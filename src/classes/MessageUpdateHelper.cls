/**
 * @description Helper class to update messages without enforcing sharing rules.
 * This class is used internally within a secure environment and is designed
 * to update fields that are managed by our application's logic, bypassing
 * Salesforce's record-level security for specific use cases.
 * 
 * @security
 * - Access to this class is restricted to internal processes only.
 * - Custom security checks ensure that updates are performed only on records
 *   where the user has appropriate permissions based on application logic.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class MessageUpdateHelper {
    /**
     * @description Process the incoming SMS message.
     * @param fromPhNumber The sender's phone number.
     * @param smsBody The body of the SMS message.
     * @param accountsid The sid of the incoming message.
     * @throws AuraHandledException if there are any issues while processing the SMS message.
     */
        public static void processSMSIncomingMessage(String fromPhNumber, String smsBody, String accountsid) {
        try {
            connectsocial__TwilioConfiguration__c smsCreds = connectsocial__TwilioConfiguration__c.getInstance();
            
            if (accountsid == smsCreds.connectsocial__Account_SID__c) {
                storeIncomingMessage(fromPhNumber, smsBody, accountsid);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error processing incoming SMS message: ' + e.getMessage());
        }
    }
    
   /**
     * @description Stores the incoming SMS message as a connectsocial__Message__c record in Salesforce.
     * @param fromPhNumber The sender's phone number.
     * @param smsBody The body of the SMS message.
     * @param sid The sid of twilio account.
     * @throws AuraHandledException if there are permissions issues or if an exception occurs during insertion.
     */
    public static void storeIncomingMessage(String fromPhNumber, String smsBody, String sid) {
        if (!Schema.sObjectType.connectsocial__Message__c.isCreateable()) {
            throw new AuraHandledException('You do not have permission to create this message.');
        }
        connectsocial__Message__c messagerRec = new connectsocial__Message__c();
        messagerRec.connectsocial__To_Number__c = fromPhNumber;
        messagerRec.connectsocial__Message_Body__c = smsBody;
        messagerRec.connectsocial__Channel__c = 'SMS';
        messagerRec.connectsocial__Outgoing__c = False;
        messagerRec.connectsocial__Type__c = 'Inbound';
        messagerRec.connectsocial__Delivery_Status__c = 'Received';
        
        if (!CommonUtil.hasFLS(messagerRec)) {
            throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
        }
        try {
            Insert messagerRec;
        } catch (Exception e) {
            throw new AuraHandledException('CalloutException: ' +e.getMessage());
        }
    }
      /**
     * @description Processes the incoming WhatsApp message response.
     * @param responseString The response string from the WhatsApp webhook.
     * @throws AuraHandledException if there are any issues while processing the WhatsApp Message.
     */
     public static void processIncomingMessage(String responseString) {
         connectsocial__Meta_Configuration__c whatsAppCreds = connectsocial__Meta_Configuration__c.getInstance();
    try {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseString);
        List<Object> entryList = (List<Object>) responseMap.get('entry');

        if (entryList != null && !entryList.isEmpty()) {
 
            Map<String, Object> entry = (Map<String, Object>) entryList[0];
            String entryId = (String) entry.get('id');
            if (entryId == whatsAppCreds.connectsocial__WhatsApp_Business_Id__c) {
                storeIncomingWAMessage(entryList, responseString);
            }
        }
    } catch (Exception e) {
        throw new AuraHandledException('Error processing incoming message: ' + e.getMessage());
    }
}
    /**
     * @description Stores the incoming WhatsApp message.
     * @param entryList The list of entries containing the message data.
     * @param responseString The response string to be stored in the message record.
     * @throws AuraHandledException if there are permissions issues or if an exception occurs during insertion or update.
     */
    public static void storeIncomingWAMessage(List<Object> entryList,String responseString) {
        Map<String, Object> entry = (Map<String, Object>) entryList.get(0);
        List<Object> changesList = (List<Object>) entry.get('changes');
        if (changesList != null && !changesList.isEmpty()) {
            Map<String, Object> changes = (Map<String, Object>) changesList.get(0);
            Map<String, Object> value = (Map<String, Object>) changes.get('value');
            List<Object> contactsList = (List<Object>) value.get('contacts');
            List<Object> messagesList = (List<Object>) value.get('messages');
            List<Object> statusesList = (List<Object>) value.get('statuses');
            if (statusesList != null && !statusesList.isEmpty()) {              
                Map<String, Object> statuses = (Map<String, Object>) statusesList[0];
                String status = (String) statuses.get('status');
                String messageId = (String) statuses.get('id');
                
				List<connectsocial__Message__c> queriedMessages = [SELECT Id, connectsocial__Message_ID__c,connectsocial__To_Number__c, connectsocial__Delivery_Status__c 
                                                                   FROM connectsocial__Message__c 
                                                                   WHERE connectsocial__Message_ID__c = :messageId WITH SECURITY_ENFORCED LIMIT 1];	
                if(queriedMessages != NULL && queriedMessages.size() > 0){
                    connectsocial__Message__c existingMessage = queriedMessages[0];
                    existingMessage.connectsocial__Delivery_Status__c = status;
                    existingMessage.connectsocial__Response__c = responseString;
                    
                    if (CommonUtil.hasFLS(existingMessage)) {
                        update existingMessage;
                    }
                    else {
                        throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message__c records.');
                    }
                    
                    WhatsApp_Event__e platformEvent = new WhatsApp_Event__e();
                    platformEvent.connectsocial__Message_ID__c = existingMessage.Id;
                    platformEvent.connectsocial__From_Number__c = existingMessage.connectsocial__To_Number__c;
                    platformEvent.connectsocial__Delivery_Status__c = existingMessage.connectsocial__Delivery_Status__c;
                    Eventbus.publish(platformEvent);
                }
            }
            Map<String, Object> metadata = (Map<String, Object>) value.get('metadata');
            if (!Schema.sObjectType.connectsocial__Message__c.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create this message.');
            }
            connectsocial__Message__c salesforceMessage = new connectsocial__Message__c();
            salesforceMessage.connectsocial__Response__c = responseString;
            salesforceMessage.connectsocial__Business_Phone_Number__c = metadata != null ? (String) metadata.get('display_phone_number') : null;
            salesforceMessage.connectsocial__Type__c = 'Inbound';
            salesforceMessage.connectsocial__Delivery_Status__c = 'Received';
            salesforceMessage.connectsocial__Channel__c = 'WhatsApp';
            if (contactsList != null && !contactsList.isEmpty()) {
                Map<String, Object> contact = (Map<String, Object>) contactsList.get(0);
                salesforceMessage.connectsocial__From_Number__c = (String) contact.get('wa_id');
                salesforceMessage.connectsocial__Customer_Name__c = (String) ((Map<String, Object>) contact.get('profile')).get('name');
            }
            if (messagesList != null && !messagesList.isEmpty()) {
                Map<String, Object> message = (Map<String, Object>) messagesList.get(0);
                salesforceMessage.connectsocial__Message_ID__c = (String) message.get('id');
                salesforceMessage.connectsocial__Message_Type__c = (String) message.get('type');
                salesforceMessage.connectsocial__Sent_At__c = System.now();
                salesforceMessage.connectsocial__Message_Body__c = message.get('text') != null ? (String) ((Map<String, Object>) message.get('text')).get('body') : null;
                
                salesforceMessage.connectsocial__Reaction__c = message.get('reaction') != null ? (String) ((Map<String, Object>) message.get('reaction')).get('emoji') : null;
                if (message.get('reaction') != null) {
                    salesforceMessage.connectsocial__Parent_Message_Id__c = (String) ((Map<String, Object>) message.get('reaction')).get('message_id');
                } else if (message.get('context') != null) {
                    salesforceMessage.connectsocial__Parent_Message_Id__c = (String) ((Map<String, Object>) message.get('context')).get('id');
                }
                String imageId = null;
                if (message.get('image') != null) {
                    imageId = (String) ((Map<String, Object>) message.get('image')).get('id');
                    String imageUrl = WhatsAppWebhook.getImageUrl(imageId);
                    if (message.get('image') != null || imageUrl != null) {
                        salesforceMessage.connectsocial__Image_ID__c = imageId;
                        salesforceMessage.connectsocial__Image_type__c = (String) ((Map<String, Object>) message.get('image')).get('mime_type');
                        salesforceMessage.connectsocial__Image_SHA256__c = (String) ((Map<String, Object>) message.get('image')).get('sha256');
                    }
                }
                salesforceMessage.connectsocial__Video_ID__c = message.get('video') != null ? (String) ((Map<String, Object>) message.get('video')).get('id') : null;
                salesforceMessage.connectsocial__Video_Type__c = message.get('video') != null ? (String) ((Map<String, Object>) message.get('video')).get('mime_type') : null;
                salesforceMessage.connectsocial__Video_SHA256__c = message.get('video') != null ? (String) ((Map<String, Object>) message.get('video')).get('sha256') : null;
                salesforceMessage.connectsocial__Document_ID__c = message.get('document') != null ? (String) ((Map<String, Object>) message.get('document')).get('id') : null;
                salesforceMessage.connectsocial__Document_Type__c = message.get('document') != null ? (String) ((Map<String, Object>) message.get('document')).get('mime_type') : null;
                salesforceMessage.connectsocial__Document_SHA256__c = message.get('document') != null ? (String) ((Map<String, Object>) message.get('document')).get('sha256') : null;
                
                if (message.get('button') != null) {
                    salesforceMessage.connectsocial__Message_Body__c = (String) ((Map<String, Object>) message.get('button')).get('text');
                }
                salesforceMessage.connectsocial__Location_Address__c = message.get('location') != null ? (String) ((Map<String, Object>) message.get('location')).get('address') : null;
                salesforceMessage.connectsocial__Location_Latitude__c = message.get('location') != null ? (String) ((Map<String, Object>) message.get('location')).get('latitude') : null;
                salesforceMessage.connectsocial__Location_Longitude__c = message.get('location') != null ? (String) ((Map<String, Object>) message.get('location')).get('longitude') : null;
                salesforceMessage.connectsocial__Location_Name__c = message.get('location') != null ? (String) ((Map<String, Object>) message.get('location')).get('name') : null;
                salesforceMessage.connectsocial__Location_Link__c = message.get('location') != null ? (String) ((Map<String, Object>) message.get('location')).get('url') : null;
                if (!CommonUtil.hasFLS(salesforceMessage)) {
                    throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message__c records.');
                }
                insert salesforceMessage;
                connectsocial__WhatsApp_Event__e platformEvent = new connectsocial__WhatsApp_Event__e();
                platformEvent.connectsocial__Message_ID__c = salesforceMessage.Id;
                platformEvent.connectsocial__From_Number__c = salesforceMessage.connectsocial__From_Number__c;
                platformEvent.connectsocial__Delivery_Status__c = salesforceMessage.connectsocial__Delivery_Status__c;
                Eventbus.publish(platformEvent);
            }
        }
    }
}