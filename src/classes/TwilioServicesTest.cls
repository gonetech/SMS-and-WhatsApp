/**
 * @description Test class for the TwilioServices class. 
 *              This class contains unit tests to verify the functionality 
 *              of the methods in the TwilioServices class.
 */
@isTest
public class TwilioServicesTest {
    
    /**
     * @description Setup method to create test data.
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
     * @description Test method to verify the sendSMS functionality.
     */
    @isTest
    static void testSendSMS() {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"sid": "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "to": "+1234567890", "status": "queued", "body": "Test SMS Body"}');
        res.setStatusCode(201);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(res));

        connectsocial__Message__c message = new connectsocial__Message__c(
            connectsocial__To_Number__c = '1234567890',
            connectsocial__Delivery_Status__c = 'Sent'
        );
        insert message;

        Test.startTest();
        Id resultId = twilioServices.sendSMS('','+1234567890', 'Test SMS Body');
        Test.stopTest();      
        Assert.areNotEqual(null, resultId,'Result ID should not be null.');
        connectsocial__Message__c updatedMessage = [SELECT Id, connectsocial__Message_ID__c, connectsocial__Delivery_Status__c FROM connectsocial__Message__c WHERE Id = :resultId];
        Assert.areEqual('SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', updatedMessage.connectsocial__Message_ID__c, 'Message ID should match.');
        Assert.areEqual('Delivered', updatedMessage.connectsocial__Delivery_Status__c,'Delivery status should be Delivered.');
    }

  	/**
     * @description Test method to verify the scheduleSMS functionality.
     */
    @isTest
    static void testScheduleSMS() {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"sid": "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "to": "+1234567890", "status": "Scheduled", "body": "Scheduled SMS Body"}');
        res.setStatusCode(201);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(res));

        connectsocial__Message__c message = new connectsocial__Message__c(
            connectsocial__To_Number__c = '1234567890',
            connectsocial__Delivery_Status__c = 'Sent'
        );
        insert message;

        Test.startTest();
        Id resultId = twilioServices.ScheduleSMS('','+1234567890', 'Scheduled SMS Body', '2024-05-22T14:00:00Z');
        Test.stopTest();
        
       Assert.areNotEqual(null, resultId, 'Result ID should not be null.');

        connectsocial__Message__c updatedMessage = [SELECT Id, connectsocial__Message_ID__c, connectsocial__Delivery_Status__c FROM connectsocial__Message__c WHERE Id = :resultId];
        Assert.areEqual('SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', updatedMessage.connectsocial__Message_ID__c, 'Message ID should match.');
        Assert.areEqual('Scheduled', updatedMessage.connectsocial__Delivery_Status__c, 'Delivery status should be Scheduled.');
    }

   
	/**
     * @description MockHttpResponseGenerator class to generate mock HTTP responses.
     */
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;
            /**
     * @description Constructs a MockHttpResponseGenerator object with the specified HTTP response.
     * @param response The HttpResponse object representing the mock response to be returned.
     */
        public MockHttpResponseGenerator(HttpResponse response) {
            this.mockResponse = response;
        }
            /**
     * @description Handles the HTTP request by returning the mock response provided during object instantiation.
     * @param req The HttpRequest object representing the incoming request (not used in this implementation).
     * @return The HttpResponse object representing the mock response provided during object instantiation.
     */
        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }
}