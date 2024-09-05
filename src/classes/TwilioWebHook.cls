/**
 * @description REST resource to handle incoming messages from Twilio.
 * Handles incoming SMS messages and stores them as connectsocial__Message__c records in Salesforce.
 */
@RestResource(urlMapping='/twilioWebhook/*')
global with sharing class TwilioWebHook {
    
    /**
     * @description Handles incoming SMS messages from Twilio.
     * Extracts the sender's phone number and the message body from the request parameters,
     * stores the message as a connectsocial__Message__c record in Salesforce.
     */
     @HttpGet
    global static void handleIncomingMessage() {
       RestRequest req = RestContext.request;
        Map<String, String> sms = req.params; 
        String fromPhNumber;
        String smsBody;
        String accountsid;
        if (sms.containsKey('From')) {
            fromPhNumber = sms.get('From');
        }
        if (sms.containsKey('Body')) {
            smsBody = sms.get('Body');
        }
         if (sms.containsKey('AccountSid')) {
            accountsid = sms.get('AccountSid');
        }
        MessageUpdateHelper.processSMSIncomingMessage(fromPhNumber, smsBody, accountsid);
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'text/plain');
    }
    
}