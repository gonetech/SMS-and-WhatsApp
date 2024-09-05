/**
 * @description Test class for TwilioWebHook class.
 */
@isTest
private class TwilioWebHookTest {    
    
    /**
     * @description Setup method to insert test data.
     */  
    @testSetup
    static void setup() {
         connectsocial__TwilioConfiguration__c twilioSetting = connectsocial__TwilioConfiguration__c.getOrgDefaults();
        twilioSetting.connectsocial__Account_SID__c = 'TestAccountSID';
        twilioSetting.connectsocial__Auth_Token__c = 'TestAuthToken';
        twilioSetting.connectsocial__Channel__c = 'SMS';
        twilioSetting.connectsocial__Messaging_Service_SID__c = 'TestMessagingServiceSID';
        twilioSetting.connectsocial__Service_Provider_Name__c = 'Twilio';
        twilioSetting.connectsocial__Twilio_Phone_Number__c = '1234567890';
        twilioSetting.connectsocial__Active__c = false;
        insert twilioSetting;
    }  
    
    /**
     * @description Test method to verify the handling of incoming messages by TwilioWebHook class.
     */
    @isTest
    static void testHandleIncomingMessage() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/twilioWebhook/';
        request.addParameter('From', '1234567890');
        request.addParameter('Body', 'Test message');
        request.addParameter('AccountSid', 'TestAccountSID');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        RestContext.request = request;
        RestContext.response = response;
        TwilioWebHook.handleIncomingMessage();
        Test.stopTest();

        Assert.areEqual('text/plain', RestContext.response.headers.get('Content-Type'), 'Unexpected Content-Type header');
        List<connectsocial__Message__c> messages = [SELECT Id, connectsocial__To_Number__c, connectsocial__Message_Body__c, connectsocial__Outgoing__c, connectsocial__Type__c, connectsocial__Delivery_Status__c FROM connectsocial__Message__c];
        Assert.areEqual(1, messages.size(), 'Unexpected number of message records created');
        connectsocial__Message__c message = messages[0];
        Assert.areEqual('1234567890', message.connectsocial__To_Number__c, 'Unexpected phone number');
        Assert.areEqual('Test message', message.connectsocial__Message_Body__c, 'Unexpected message body');
        Assert.areEqual(false, message.connectsocial__Outgoing__c, 'Expected message to be inbound');
        Assert.areEqual('Inbound', message.connectsocial__Type__c, 'Unexpected message type');
        Assert.areEqual('Received', message.connectsocial__Delivery_Status__c, 'Unexpected message delivery status');
    }
	/**
     * @description Mock HTTP response generator for simulating HTTP callouts.
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        /**
     * @description Simulates an HTTP response with a mock body and status code.
     * @param req The HTTP request to which this response corresponds.
     * @return An HTTPResponse object with a mock body and status code 200.
     */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('Mock response body');
            res.setStatusCode(200);
            return res;
        }
    }
}