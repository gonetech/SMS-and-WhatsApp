/**
 * @description A class for interacting with Twilio services to send and schedule SMS messages from Salesforce.
 * This class includes methods to send SMS immediately or schedule them for a future time.
 */
public with sharing class TwilioServices {
	/**
     * @description Sends an SMS message to the specified phone number with the given message body.
     * @param recordId The Id of the message record
     * @param phoneNo The phone number to which the SMS will be sent.
     * @param smsBody The body of the SMS message.
     * @return The ID of the created message record.
     * @throws AuraHandledException If there are issues with permissions or if an error occurs during the HTTP request.
     */
/**
    @AuraEnabled
    public static Id sendSMS(String recordId, String phoneNo, String smsBody){
        smsBody = String.escapeSingleQuotes(smsBody);
        smsBody = smsBody.replace('\\\\', '\\');
        smsBody = smsBody.contains('{')?WhatsAppServices.replacePlaceholders(recordId,smsBody):smsBody;
        connectsocial__TwilioConfiguration__c smsCreds = ProviderSettingUtil.getSMSProviderSettings('SMS');
        String accountSid = smsCreds.connectsocial__Account_SID__c; 
        String endPoint = 'callout:connectsocial__Twilio_API/2010-04-01/Accounts/' + accountSid + '/Messages.json';
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        String version = '3.2.0';
        req.setHeader('X-Twilio-Client', 'salesforce-' + version);
        req.setHeader('User-Agent', 'twilio-salesforce/' + version);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept-Charset', 'utf-8');
        req.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
		req.setHeader('Pragma', 'no-cache');
		req.setHeader('Expires', '0');
		req.setHeader('X-Content-Type-Options', 'nosniff');
        String messageBody = 'To=' + EncodingUtil.urlEncode(phoneNo, 'UTF-8') +'&From=' + EncodingUtil.urlEncode(smsCreds.connectsocial__Twilio_Phone_Number__c, 'UTF-8') + '&Body=' + EncodingUtil.urlEncode(smsBody, 'UTF-8');
        req.setBody(messageBody);
        res = http.send(req);
        if(res.getStatusCode() == 201){
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String messageSid = (String) jsonResponse.get('sid');
            String phoneNumber = (String) jsonResponse.get('to');
            String status = (String) jsonResponse.get('status');
            List<connectsocial__Message__c> recordsToupdate = [SELECT Id, Name,connectsocial__To_Number__c,connectsocial__Message_ID__c, connectsocial__Message_Body__c, connectsocial__Type__c, connectsocial__Outgoing__c, CreatedDate, connectsocial__Delivery_Status__c,connectsocial__Scheduled_Date_Time__c FROM connectsocial__Message__c  WHERE connectsocial__Delivery_Status__c = 'Sent' With SECURITY_ENFORCED Order By CreatedDate DESC LIMIT 1] ;
            List<connectsocial__Message__c> smsList = new List<connectsocial__Message__c>();
            for(connectsocial__Message__c sms: recordsToupdate ){
                string phone = '+'+sms.connectsocial__To_Number__c;
                If(PhoneNumber == phone && status == 'queued'){
                    if (!Schema.sObjectType.connectsocial__Message__c.isCreateable() || !Schema.sObjectType.connectsocial__Message__c.isUpdateable()) {
                		throw new AuraHandledException('You do not have permission to create this message.');
            		}  
                    connectsocial__Message__c messagerRec = new connectsocial__Message__c();
                    messagerRec.connectsocial__Message_ID__c = messageSid;
                    messagerRec.connectsocial__Delivery_Status__c = 'Delivered';
                    messagerRec.Id = sms.Id;
                    messagerRec.connectsocial__To_Number__c = phoneNumber;
                    messagerRec.connectsocial__Message_Body__c = smsBody;
                    messagerRec.connectsocial__Outgoing__c = True;
                    messagerRec.connectsocial__Type__c = 'Outbound';
                    if (!CommonUtil.hasFLS(messagerRec)) {
        			throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
    				}
                    smsList.add(MessagerRec); 
                }
            }
            if(smsList.size()>0){
                if (!CommonUtil.hasFLS(smsList[0])) {
        			throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
    				}
                update smsList;
            }
            return smsList[0].Id;
        } else{
            errorWrapper er = (errorWrapper) JSON.deserialize(res.getBody(), errorWrapper.class);
            if(!Test.isRunningTest()){
                throw new AuraHandledException('Error : ' + er.message + ' Code: ' + er.code);
            }
            return null;
        }
    }
*/

@AuraEnabled
public static Id sendSMS(String recordId, String phoneNo, String smsBody){
    smsBody = String.escapeSingleQuotes(smsBody);
    smsBody = smsBody.replace('\\\\', '\\');
    smsBody = smsBody.contains('{') ? WhatsAppServices.replacePlaceholders(recordId, smsBody) : smsBody;
    
    connectsocial__TwilioConfiguration__c smsCreds = ProviderSettingUtil.getSMSProviderSettings('SMS');
    String accountSid = smsCreds.connectsocial__Account_SID__c; 
    String endPoint = 'callout:connectsocial__Twilio_API/2010-04-01/Accounts/' + accountSid + '/Messages.json';
    
    HttpRequest req = new HttpRequest();
    Http http = new Http();
    HTTPResponse res = new HTTPResponse();
    req.setEndpoint(endPoint);
    req.setMethod('POST');
    
    String version = '3.2.0';
    req.setHeader('X-Twilio-Client', 'salesforce-' + version);
    req.setHeader('User-Agent', 'twilio-salesforce/' + version);
    req.setHeader('Accept', 'application/json');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setHeader('Accept-Charset', 'utf-8');
    req.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    req.setHeader('Pragma', 'no-cache');
    req.setHeader('Expires', '0');
    req.setHeader('X-Content-Type-Options', 'nosniff');
    
    String messageBody = 'To=' + EncodingUtil.urlEncode(phoneNo, 'UTF-8') +
                         '&From=' + EncodingUtil.urlEncode(smsCreds.connectsocial__Twilio_Phone_Number__c, 'UTF-8') +
                         '&Body=' + EncodingUtil.urlEncode(smsBody, 'UTF-8');
    req.setBody(messageBody);
    
    res = http.send(req);
    
    if (res.getStatusCode() == 201) {
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String messageSid = (String) jsonResponse.get('sid');
        String phoneNumber = (String) jsonResponse.get('to');
        String status = (String) jsonResponse.get('status');
        
        List<connectsocial__Message__c> recordsToUpdate = [
            SELECT Id, Name, connectsocial__To_Number__c, connectsocial__Message_ID__c, 
                   connectsocial__Message_Body__c, connectsocial__Type__c, connectsocial__Outgoing__c, 
                   connectsocial__Delivery_Status__c, connectsocial__Scheduled_Date_Time__c 
            FROM connectsocial__Message__c  
            WHERE connectsocial__Delivery_Status__c = 'Sent' 
            WITH SECURITY_ENFORCED 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        List<connectsocial__Message__c> smsList = new List<connectsocial__Message__c>();
        
        for (connectsocial__Message__c sms : recordsToUpdate) {
            String phone = '+' + sms.connectsocial__To_Number__c;
            if (phoneNumber == phone && status == 'queued') {
                if (!Schema.sObjectType.connectsocial__Message__c.isCreateable() || !Schema.sObjectType.connectsocial__Message__c.isUpdateable()) {
                    throw new CalloutException('You do not have permission to create this message.');
                }  
                
                connectsocial__Message__c messageRec = new connectsocial__Message__c();
                messageRec.connectsocial__Message_ID__c = messageSid;
                messageRec.connectsocial__Delivery_Status__c = 'Delivered';
                messageRec.Id = sms.Id;
                messageRec.connectsocial__To_Number__c = phoneNumber;
                messageRec.connectsocial__Message_Body__c = smsBody;
                messageRec.connectsocial__Outgoing__c = true;
                messageRec.connectsocial__Type__c = 'Outbound';
                
                if (!CommonUtil.hasFLS(messageRec)) {
                    throw new CalloutException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
                }
                
                smsList.add(messageRec);
            }
        }
        
        if (!smsList.isEmpty()) {
            if (!CommonUtil.hasFLS(smsList[0])) {
                throw new CalloutException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
            }
            update smsList;
            return smsList[0].Id;
        } else {
            // Handle the case where no message records are updated
            return null;  // or handle accordingly
        }
    } else {
        errorWrapper er = (errorWrapper) JSON.deserialize(res.getBody(), errorWrapper.class);
        if (!Test.isRunningTest()) {
            throw new CalloutException('Error : ' + er.message + ' Code: ' + er.code);
        }
        return null;
    }
}

    /**
     * @description Schedules an SMS message to be sent at a specified future time.
     * @param recordId The Id of the message record
     * @param phoneNo The phone number to which the SMS will be sent.
     * @param smsBody The body of the SMS message.
     * @param scheduledTime The time at which the SMS should be sent, in the format required by Twilio.
     * @return The ID of the created scheduled message record.
     * @throws AuraHandledException If there are issues with permissions or if an error occurs during the HTTP request.
     */
    @AuraEnabled
    public static Id scheduleSMS(String recordId, String phoneNo, String smsBody, String scheduledTime) {
        smsBody = String.escapeSingleQuotes(smsBody).replace('\n', '\\n');
        smsBody = smsBody.contains('{')?WhatsAppServices.replacePlaceholders(recordId,smsBody):smsBody;
        connectsocial__TwilioConfiguration__c smsCreds = ProviderSettingUtil.getSMSProviderSettings('SMS');
        String accountSid = smsCreds.connectsocial__Account_SID__c;
        String endPoint = 'callout:connectsocial__Twilio_API/2010-04-01/Accounts/' + accountSid + '/Messages.json';
        String messagingServiceSid = smsCreds.connectsocial__Messaging_Service_SID__c;
        String requestBody = 'To=' + EncodingUtil.urlEncode(phoneNo, 'UTF-8') +'&MessagingServiceSid=' + messagingServiceSid +'&Body=' + EncodingUtil.urlEncode(smsBody, 'UTF-8') +'&ScheduleType=fixed' +'&SendAt=' + scheduledTime;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
		req.setHeader('Pragma', 'no-cache');
		req.setHeader('Expires', '0');
		req.setHeader('X-Content-Type-Options', 'nosniff');
        req.setBody(requestBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 201) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String messageSid = (String) jsonResponse.get('sid');
            String phoneNumber = (String) jsonResponse.get('to');
            String status = (String) jsonResponse.get('status');
            List<connectsocial__Message__c> scheduleRecordUpdate = [SELECT Id, Name,connectsocial__To_Number__c,connectsocial__Message_ID__c, connectsocial__Message_Body__c, connectsocial__Type__c, connectsocial__Outgoing__c, CreatedDate, connectsocial__Delivery_Status__c,connectsocial__Scheduled_Date_Time__c FROM connectsocial__Message__c WHERE connectsocial__Delivery_Status__c = 'Sent' With SECURITY_ENFORCED Order By CreatedDate DESC LIMIT 1] ;
            List<connectsocial__Message__c> smsScheduleList = new List<connectsocial__Message__c>();
            for(connectsocial__Message__c sms: scheduleRecordUpdate ){
                string phone = '+'+sms.connectsocial__To_Number__c;
                If(phoneNumber == phone && status == 'Scheduled'){
                    if (!Schema.sObjectType.connectsocial__Message__c.isUpdateable()) {
                		throw new AuraHandledException('You do not have permission to create this message.');
            		} 
                    connectsocial__Message__c scheduledMessage = new connectsocial__Message__c();
                    scheduledMessage.connectsocial__Message_ID__c = messageSid;
                    scheduledMessage.connectsocial__Delivery_Status__c = 'Scheduled';
                    scheduledMessage.Id = sms.Id;
                    scheduledMessage.connectsocial__To_Number__c = phoneNumber;
                    scheduledMessage.connectsocial__Message_Body__c = smsBody;
                    scheduledMessage.connectsocial__Outgoing__c = True;
                    scheduledMessage.connectsocial__Type__c = 'Outbound';
                    if (!CommonUtil.hasFLS(scheduledMessage)) {
        			throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
    				}
                    smsScheduleList.add(scheduledMessage); 
                }
    
            }
            if(smsScheduleList.size()>0){
                update smsScheduleList;
            }
            return smsScheduleList[0].Id;
        }
        else {
            return null;
        }
    }

    
	/**
     * @description A wrapper class for handling errors returned by the Twilio API.
     */
    public class ErrorWrapper{
        String code;
        String message;
        String moreInfo;
        String status; 
    }
    /**
     * @description Creates a new AuraHandledException with the specified message.
     * @param message The message for the exception.
     * @return The newly created AuraHandledException.
     */
    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}
