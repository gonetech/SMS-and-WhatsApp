/**
* @description This class implements a Queueable interface to handle the updating and sending of scheduled WhatsApp messages.
* It retrieves scheduled WhatsApp messages that are due for delivery, sends them out using WhatsApp API, and updates their delivery status.
*/
public with sharing class UpdateScheduledWhatsAppMessages implements Queueable {
    
    public static  String messagingProduct = 'messaging_product';
    public Contacts[] contacts;
    public Messages[] messages;
    /**
* @description A nested class representing a WhatsApp contact.
*/
    public class Contacts {
        public String input;
    }
    /**
* @description A nested class representing a WhatsApp message.
*/
    public class Messages {
        public String id;
    }    
    /**
* @description Executes the queueable job to update and send scheduled WhatsApp messages.
* Retrieves scheduled WhatsApp messages due for delivery and sends them out.
* Updates the delivery status and message ID upon successful delivery.
* @param context The queueable context.
*/
    public void execute(QueueableContext context) {
        Set<Id> scheduledMessageIds = new Set<Id>();
        List<connectsocial__Message__c> scheduledMessages = [SELECT Id, connectsocial__Delivery_Status__c, connectsocial__Scheduled_Date_Time__c, connectsocial__To_Number__c,connectsocial__Outgoing__c,connectsocial__Message_Body__c  FROM connectsocial__Message__c  WHERE connectsocial__Delivery_Status__c = 'Scheduled' AND connectsocial__Scheduled_Date_Time__c <= :DateTime.now() AND connectsocial__Channel__c = 'WhatsApp' With SECURITY_ENFORCED];
        for (connectsocial__Message__c message : scheduledMessages) {
            scheduledMessageIds.add(message.Id);
        }
        if (!scheduledMessageIds.isEmpty()) {
            sendWhatsAppMessages(scheduledMessageIds);
        }
    }
    /**
    * @description Sends WhatsApp messages based on the provided message IDs.
    * @param scheduledMessageIds The IDs of scheduled WhatsApp messages to be sent.
    */
    @future(callout=true)
    public static void sendWhatsAppMessages(Set<Id> scheduledMessageIds) {
        List<connectsocial__Message__c> messages = [SELECT Id, connectsocial__To_Number__c, connectsocial__Type__c, connectsocial__Message_Body__c, connectsocial__Delivery_Status__c, connectsocial__Scheduled_Date_Time__c FROM connectsocial__Message__c WHERE Id IN :scheduledMessageIds With SECURITY_ENFORCED];
        if (!Schema.sObjectType.connectsocial__Message__c.isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update this message.');
        }
        connectsocial__Meta_Configuration__c whatsAppCreds = ProviderSettingUtil.getWhatsAppProviderSettings('WhatsApp');
        if (whatsAppCreds != null) {
            String endpointUrl = 'callout:connectsocial__Meta_API/v19.0/' + whatsAppCreds.connectsocial__Phone_Number_Id__c + '/messages';
            List<connectsocial__Message__c> messagesToUpdate = new List<connectsocial__Message__c>();
            for (connectsocial__Message__c message : messages) {
                HttpRequest httpReq = new HttpRequest();
                httpReq.setEndpoint(endpointUrl);
                httpReq.setMethod('POST');
                httpReq.setHeader('Content-Type', 'application/json');
                httpReq.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        		httpReq.setHeader('Pragma', 'no-cache');
        		httpReq.setHeader('Expires', '0');
        		httpReq.setHeader('X-Content-Type-Options', 'nosniff');
                String toPhone = message.connectsocial__To_Number__c;
                String messageContent = message.connectsocial__Message_Body__c;
                String messageBody = '{'+
                    +messagingProduct+ ' : "whatsapp",'+
                    '    "recipient_type": "individual",'+
                    '    "to": "'+toPhone+'",'+
                    '    "type": "text",'+
                    '    "text": {'+
                    '        "preview_url": false,'+
                    '        "body": "'+messageContent+'"'+
                    '    }'+
                    '}';
                
                httpReq.setBody(messageBody);               
                Http http = new Http();
                try {
                    HttpResponse response = http.send(httpReq);
                    if (response.getStatusCode() == 200) {
                        whatsAppServices responseFromWA = (whatsAppServices) JSON.deserialize( response.getBody() , whatsAppServices.class);
                        message.connectsocial__Message_ID__c = responseFromWA.messages.get(0).id;
                        message.connectsocial__To_Number__c = toPhone;
                        message.connectsocial__Message_Type__c = 'text';
                        message.connectsocial__Delivery_Status__c = 'Sent';
                        message.connectsocial__Outgoing__c = true;
                        messagesToUpdate.add(message);
                    }
                } catch (System.CalloutException ex) {
                    throw new AuraHandledException('CalloutException: ' + ex.getMessage());
                }
                
            }
            
            if (!messagesToUpdate.isEmpty()) {
                if (Schema.sObjectType.connectsocial__Message__c.isUpdateable() && CommonUtil.hasFLS(messagesToUpdate[0])) {
        			update messagesToUpdate;
    			}
                else {
                    throw new AuraHandledException('You do not have the necessary field permissions to update connectsocial__Message__c records.');
                }
            }
        } else {
            throw new AuraHandledException('WhatsApp credentials not found.');
        }
    }
    
}