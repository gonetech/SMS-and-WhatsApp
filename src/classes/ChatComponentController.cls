/**
 * @description Controller class for all the neccessary record querying from Message,SMS/WhatsApp Setting and Message Template objects.
 * @class ChatComponentController
 * @with sharing
 */
public with sharing class ChatComponentController {
    
    /**
 * @description Retrieves all messages sent to a specific phone number.
 * @return List of messages sent to the specified phone number.
 * @throws AuraHandledException if there's an error during the query execution.
 */
    @AuraEnabled(cacheable=true)
    public static Boolean hasUserPermission() {
        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Name 
            FROM PermissionSetAssignment 
            WHERE (PermissionSet.Name = 'connectssocial_Admin' OR PermissionSet.Name = 'connectssocial_User')
            AND AssigneeId = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
        ];
        
        if (permissionSetAssignments.isEmpty() || permissionSetAssignments.size() == 0) {
            throw new AuraHandledException('You do not have the required permissions to access this feature.');
        }
        return true;
    }
    
    /**
 * @description Retrieves all messages sent to a specific phone number.
 * @param phoneNumber The phone number to filter messages.
 * @return List of messages sent to the specified phone number.
 * @throws AuraHandledException if there's an error during the query execution.
 */
    @AuraEnabled
    public static List<connectsocial__Message__c> listAllMessages(String phoneNumber) {
        List<connectsocial__Message__c> messages = new List<connectsocial__Message__c>();
        try {
            messages = [SELECT Id, Name, connectsocial__Message_Body__c, connectsocial__Type__c,
                               connectsocial__To_Number__c, connectsocial__Channel__c, connectsocial__Outgoing__c,
                               connectsocial__Delivery_Status__c, connectsocial__Scheduled_Date_Time__c, CreatedDate, connectsocial__Sent_At__c  
                        FROM connectsocial__Message__c 
                        WHERE connectsocial__To_Number__c = :phoneNumber OR connectsocial__From_Number__c = :phoneNumber
                        WITH SECURITY_ENFORCED 
                        ORDER BY connectsocial__Sent_At__c ASC ];
        } catch (Exception ex) {
            throw new AuraHandledException('CalloutException: ' + ex.getMessage());
        }
        return messages;
    }

    /**
 * @description Retrieves WhatsApp messages for a specific customer phone number.
 * @param customerPhone The customer's phone number.
 * @return List of WhatsApp messages associated with the specified phone number.
 */
    @AuraEnabled
    public static List<connectsocial__Message__c> listWAMessages(String customerPhone){
        customerPhone = customerPhone.replaceAll(' ', '');
        List<connectsocial__Message__c> messages = new List<connectsocial__Message__c>();
        messages= [SELECT Id, Name, connectsocial__Message_Body__c, connectsocial__Type__c,
                          connectsocial__To_Number__c, connectsocial__Channel__c, connectsocial__Outgoing__c,
                          connectsocial__Delivery_Status__c, connectsocial__Scheduled_Date_Time__c, CreatedDate 
                   FROM connectsocial__Message__c 
                   WHERE connectsocial__To_Number__c = :customerPhone OR connectsocial__From_Number__c = :customerPhone 
                   WITH SECURITY_ENFORCED 
                   ORDER BY CreatedDate ASC];
        return messages;
    }

    /**
 * @description Retrieves details of a specific record.
 * @param objectName The name of the object.
 * @param recordId The ID of the record.
 * @param phoneField The phone field to be retrieved.
 * @return A map containing record details (Name and Phone).
 * @throws AuraHandledException if the object or field name is invalid or if there's an error during the query execution.
 */
  @AuraEnabled
    public static Map<String, String> getRecordDetails(String objectName, String recordId, String phoneField) {
        Map<String, String> recordDetails = new Map<String, String>();
        try {
            if (Schema.getGlobalDescribe().containsKey(objectName) && Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().containsKey(phoneField)) {
                String query = 'SELECT Name, ' + String.escapeSingleQuotes(phoneField) + ' FROM ' + String.escapeSingleQuotes(objectName) + ' WHERE Id = :recordId LIMIT 1';
                SObject record = Database.query(query);
                if (record != null) {
                    if (record.get('Name') != null) {
                        recordDetails.put('Name', (String) record.get('Name'));
                    }
                    if (record.get(phoneField) != null) {
                        recordDetails.put('Phone', (String) record.get(phoneField));
                    }
                }
            } else {
                throw new AuraHandledException('Invalid object name or phone field');
            }
        } catch (Exception ex) {
            throw new AuraHandledException('CalloutException: ' + ex.getMessage());
        }
        return recordDetails;
    }
    /**
 * @description Retrieves the phone field name for a specific object.
 * @param objectName The name of the object.
 * @return The phone field name for the specified object.
 * @throws AuraHandledException if there's an error during the query execution.
 */
    @AuraEnabled(cacheable=true)
    public static String getPhoneFieldName(String objectName) {
        try {
            List<connectsocial__SMS_WhatsApp_Settings__c> settings = [SELECT connectsocial__Phone_Field_Name__c 
                                                                       FROM connectsocial__SMS_WhatsApp_Settings__c 
                                                                       WHERE connectsocial__Object_Name__c = :objectName 
                                                                       WITH SECURITY_ENFORCED 
                                                                       LIMIT 1 ];
            if (!settings.isEmpty()) {
                return settings[0].connectsocial__Phone_Field_Name__c;
            }
        } catch (Exception ex) {
            throw new AuraHandledException('CalloutException: ' + ex.getMessage());
        }
        return null;
    }
/**
 * @description Saves the phone field name for a specific object.
 * @param objectName The name of the object.
 * @param phoneFieldName The phone field name to be saved.
 * @throws AuraHandledException if the user does not have permission to create or update the setting, or if there's an error during the insert operation.
 */
    @AuraEnabled
    public static void savePhoneFieldName(String objectName, String phoneFieldName) {
        try {
            if (!Schema.sObjectType.connectsocial__SMS_WhatsApp_Settings__c.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create this setting.');
            }
            connectsocial__SMS_WhatsApp_Settings__c setting = new connectsocial__SMS_WhatsApp_Settings__c();        
            if (Schema.sObjectType.connectsocial__SMS_WhatsApp_Settings__c.fields.connectsocial__Object_Name__c.isAccessible()) {
                setting.connectsocial__Object_Name__c = objectName;
            } else {
                throw new AuraHandledException('You do not have permission to read the Object Name field.');
            }
            if (Schema.sObjectType.connectsocial__SMS_WhatsApp_Settings__c.fields.connectsocial__Phone_Field_Name__c.isAccessible()) {
                setting.connectsocial__Phone_Field_Name__c = phoneFieldName;
            } else {
                throw new AuraHandledException('You do not have permission to read the Phone Field Name field.');
            }
            insert setting;
        } catch (Exception ex) {
            throw new AuraHandledException('CalloutException: ' + ex.getMessage());
        }
    }

    
/**
 * @description Sends an SMS using the Twilio service.
 * @param recordId The Id of the message record
 * @param phoneNumber The recipient's phone number.
 * @param smsBody The body of the SMS message.
 * @return The message record created in Salesforce.
 * @throws AuraHandledException if there's an error during the Twilio call or message query.
 */
    @AuraEnabled
    public static connectsocial__Message__c sendSMS(String recordId, String phoneNumber, String smsBody) {
        Id message = twilioServices.SendSMS(recordId, phoneNumber, smsBody);      
        List<connectsocial__Message__c> messages = [SELECT Id, Name, connectsocial__Message_Body__c, connectsocial__Type__c, 
                                                           connectsocial__Channel__c, connectsocial__Outgoing__c, CreatedDate, 
                                                           connectsocial__Delivery_Status__c, connectsocial__Scheduled_Date_Time__c 
                                                    FROM connectsocial__Message__c 
                                                    WHERE Id = :message 
                                                    WITH SECURITY_ENFORCED 
                                                    ORDER BY CreatedDate ASC ];
        return messages.size() > 0 ? messages[0] : null;
    }

    /**
     * @description Schedules an SMS using the Twilio service.
     * 
	 * @param recordId The Id of the message record
     * @param phoneNumber The recipient's phone number.
     * @param smsBody The body of the SMS message.
     * @param scheduledTime The time at which the SMS should be sent.
     * @return The scheduled message record created in Salesforce.
     * @throws AuraHandledException if there's an error during the Twilio call or message query.
     */
    @AuraEnabled
    public static connectsocial__Message__c scheduleSMS(String recordId, String phoneNumber, String smsBody, String scheduledTime) {
        try {
            Id scheduledMessage = twilioServices.ScheduleSMS(recordId, phoneNumber, smsBody, scheduledTime);
            List<connectsocial__Message__c> message = [SELECT Id, Name, connectsocial__Message_Body__c, connectsocial__Type__c, 
                                                               connectsocial__Channel__c, connectsocial__Outgoing__c, CreatedDate, 
                                                               connectsocial__Delivery_Status__c, connectsocial__Scheduled_Date_Time__c 
                                                        FROM connectsocial__Message__c 
                                                        WHERE Id = :scheduledMessage 
                                                        WITH SECURITY_ENFORCED 
                                                        ORDER BY CreatedDate ASC ];
            return message.size() > 0 ? message[0] : null;
        } catch (Exception e) {
            throw new AuraHandledException('Error scheduling SMS: ' + e.getMessage());
        }
    }

    /**
     * @description Creates a message record in Salesforce.
     * 
     * @param phoneNumber The recipient's phone number.
     * @param smsBody The body of the SMS message.
     * @param status The delivery status of the message.
     * @return The ID of the created message record.
     * @throws AuraHandledException if the user does not have permission to create the message or if there's an error during the insert operation.
     */
    @AuraEnabled(cacheable=false)
    public static String createMessageRecord(String phoneNumber, String smsBody, String status) {
        try {
            if (!Schema.sObjectType.connectsocial__Message__c.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create this message.');
            }    
            if (!Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__To_Number__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Message_Body__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Delivery_Status__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Type__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Channel__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Outgoing__c.isCreateable()) {
                throw new AuraHandledException('You do not have permission to set one or more fields for this message.');
            }
            if(String.isBlank(smsBody)){
                throw new AuraHandledException('The Message body cannot be Empty');
            }
            connectsocial__Message__c newMessage = new connectsocial__Message__c(
                connectsocial__To_Number__c = phoneNumber,
                connectsocial__Message_Body__c = smsBody,
                connectsocial__Delivery_Status__c = 'sent',
                connectsocial__Type__c = 'Outbound',
                connectsocial__Channel__c = 'SMS',
                connectsocial__Outgoing__c = true
            );            
            insert newMessage;
            return newMessage.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating message record: ' + e.getMessage());
        }
    }

    /**
     * @description Creates a scheduled message record in Salesforce.
     * 
     * @param smsparams A map containing SMS parameters (phoneNumber, smsBody, status, scheduledTime).
     * @return The ID of the created scheduled message record.
     * @throws AuraHandledException if the user does not have permission to create the message or if there's an error during the insert operation.
     */
    @AuraEnabled(cacheable=false)
    public static String createScheduleRecord(Map<String, Object> smsparams) {
        try {
            String phoneNumber = (String) smsparams.get('phoneNumber');
            String smsBody = (String) smsparams.get('smsBody');
            String status = (String) smsparams.get('status');
            String scheduledTime = (String) smsparams.get('scheduledTime');
            if (!Schema.sObjectType.connectsocial__Message__c.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create this message.');
            }
            DateTime resultDateTime;
            if (scheduledTime != null) {
                String inputString = scheduledTime;
                resultDateTime = DateTime.ValueofGmt(inputString.replace('T', ' '));
            }
            connectsocial__Message__c scheduledMessage = new connectsocial__Message__c(
                connectsocial__To_Number__c = phoneNumber,
                connectsocial__Message_Body__c = smsBody,
                connectsocial__Channel__c = 'SMS',
                connectsocial__Delivery_Status__c = status,
                connectsocial__Type__c = 'Outbound',
                connectsocial__Outgoing__c = true,
                connectsocial__Scheduled_Date_Time__c = resultDateTime 
            );
            if (!Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__To_Number__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Message_Body__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Channel__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Delivery_Status__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Type__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Outgoing__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Scheduled_Date_Time__c.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create one or more fields on this message.');
            }
            insert scheduledMessage;
            return scheduledMessage.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating scheduled message record: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves a single message record by its ID and customer phone number.
     * 
     * @param recordId The ID of the message record.
     * @param customerPhone The customer's phone number.
     * @return The message record if found.
     */
    @AuraEnabled(cacheable=true)
    public static connectsocial__Message__c getSingleMessage(String recordId, String customerPhone){
        connectsocial__Message__c message = [SELECT Id, Name, connectsocial__Message_Body__c, connectsocial__To_Number__c, 
                                                     connectsocial__From_Number__c, connectsocial__Message_Type__c, connectsocial__Channel__c, 
                                                     connectsocial__Customer_Name__c, connectsocial__Type__c, connectsocial__Delivery_Status__c, 
                                                     connectsocial__Outgoing__c, connectsocial__Scheduled_Date_Time__c, CreatedDate 
                                              FROM connectsocial__Message__c 
                                              WHERE Id = :recordId AND (connectsocial__From_Number__c = :customerPhone OR connectsocial__To_Number__c = :customerPhone) 
                                              WITH SECURITY_ENFORCED 
                                              ORDER BY CreatedDate ASC];       
        return message;
    }

    /**
     * @description Sends a WhatsApp text message.
     * 
     * @param messageContent The content of the WhatsApp message.
     * @param toPhone The recipient's phone number.
     * @return The message record created in Salesforce.
     * @throws AuraHandledException if there's an error during the WhatsApp service call or message query.
     */
    @AuraEnabled
    public static connectsocial__Message__c sendTextMessage(String messageContent, String toPhone){
        connectsocial__Message__c message = whatsAppServices.sendTextMessage(messageContent, toPhone);
        List<connectsocial__Message__c> messages = [SELECT Id, Name, connectsocial__Message_Body__c, connectsocial__To_Number__c, 
                                                            connectsocial__Message_Type__c, connectsocial__Channel__c, connectsocial__Customer_Name__c, 
                                                            connectsocial__Type__c, connectsocial__Delivery_Status__c, connectsocial__Outgoing__c, 
                                                            connectsocial__Scheduled_Date_Time__c, CreatedDate 
                                                     FROM connectsocial__Message__c 
                                                     WHERE Id = :message.Id 
                                                     WITH SECURITY_ENFORCED 
                                                     ORDER BY CreatedDate ASC ];
        return messages.size() > 0 ? messages[0] : null;
    }

    /**
     * @description Creates a scheduled WhatsApp message record in Salesforce.
     * 
     * @param whatsappparams A map containing WhatsApp parameters (phoneNumber, messageBody, status, scheduledTime).
     * @return The created scheduled message record.
     * @throws AuraHandledException if the user does not have permission to create the message or if there's an error during the insert operation.
     */
    @AuraEnabled(cacheable=false)
    public static connectsocial__Message__c createWhatsAppScheduleRecord(Map<String, Object> whatsappparams) {
        try {
            String phoneNumber = (String) whatsappparams.get('phoneNumber');
            String messageBody = (String) whatsappparams.get('messageBody');
            String status = (String) whatsappparams.get('status');
            String scheduledTime = (String) whatsappparams.get('scheduledTime');
            if (!Schema.sObjectType.connectsocial__Message__c.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create this message.');
            }
            DateTime myDate;
            if (scheduledTime != null) {
                myDate = (DateTime)JSON.deserialize('"' + scheduledTime + '"', DateTime.class);
            }
            connectsocial__Message__c scheduledMessage = new connectsocial__Message__c(
                connectsocial__To_Number__c = phoneNumber,
                connectsocial__Message_Body__c = messageBody,
                connectsocial__Channel__c = 'WhatsApp',
                connectsocial__Delivery_Status__c = status,
                connectsocial__Type__c = 'Outbound',
                connectsocial__Outgoing__c = true,
                connectsocial__Scheduled_Date_Time__c = myDate
            );
            if (!Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__To_Number__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Message_Body__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Channel__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Delivery_Status__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Type__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Outgoing__c.isCreateable() ||
                !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Scheduled_Date_Time__c.isCreateable()) {
                throw new AuraHandledException('You do not have permission to create one or more fields on this message.');
            }
            insert scheduledMessage;
            scheduledMessage = [SELECT Id, CreatedDate, connectsocial__To_Number__c, connectsocial__Message_Body__c, 
                                       connectsocial__Channel__c, connectsocial__Delivery_Status__c, connectsocial__Type__c, 
                                       connectsocial__Outgoing__c, connectsocial__Scheduled_Date_Time__c 
                                FROM connectsocial__Message__c 
                                WHERE Id = :scheduledMessage.Id 
                                WITH SECURITY_ENFORCED];
            return scheduledMessage;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating message record: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves all message templates.
     * 
     * @param objectApiName The API Name of Object
     * @param templateType The type of the template
     * @return A list of all message templates.
     */
    @AuraEnabled(cacheable=true)
    public static List<connectsocial__Message_Template__c> getTemplates(String objectApiName,String templateType) {
        try{
            List<connectsocial__Message_Template__c> allTemplate = [SELECT Id, connectsocial__Channel__c, connectsocial__Template_API_Name__c, 
                                                                    connectsocial__Template_Name__c, connectsocial__Header__c, 
                                                                    connectsocial__Body__c, connectsocial__Footer__c, connectsocial__Button__c , connectsocial__Object_Name__c
                                                                    FROM connectsocial__Message_Template__c WHERE connectsocial__Channel__c = :templateType AND (connectsocial__Object_Name__c =:objectApiName OR connectsocial__Object_Name__c = NULL)
                                                                    WITH SECURITY_ENFORCED LIMIT 100];
            return allTemplate;
        } catch (Exception e) {
            throw new AuraHandledException('Error Fetching Message Template Records ' + e.getMessage());
        } 
    }
}