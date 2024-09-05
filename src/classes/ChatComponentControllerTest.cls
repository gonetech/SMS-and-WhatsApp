/**
 * @description Test class for the ChatComponentController class. 
 *              This class contains unit tests to verify the functionality 
 *              of the methods in the ChatComponentController class.
 */
@isTest
public class ChatComponentControllerTest {

    /**
 * @description Mock implementation of Twilio service to simulate HTTP responses for testing.
 */
    private class MockTwilioService implements HttpCalloutMock {
        private Id testMessageId;
     /**
     * @description Default constructor.
     */
        public MockTwilioService() {
            // This constructor intentionally left empty.
            testMessageId = null;
        }
    	/**
     * @description Constructor with testMessageId.
     * @param testMessageId The Id of the test message.
     */
        public MockTwilioService(Id testMessageId) {
            this.testMessageId = testMessageId;
        }
    	/**
     * @description Responds with a mock HTTP response.
     * @param req The incoming HTTP request.
     * @return The mock HTTP response.
     */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"sid": "mock_sid"}');
            res.setStatusCode(200);
            return res;
        }
    	 /**
     * @description Gets the test message Id.
     * @return The test message Id.
     */
        public Id getTestMessageId() {
            return testMessageId;
        }
    }
/**
 * @description Sets up test data for the test methods.
 */
    @testSetup
    static void setupTestData() {
		
        connectsocial__Message__c msg1 = new connectsocial__Message__c(
            connectsocial__Message_Body__c = 'Test Message 1',
            connectsocial__Type__c = 'Outbound',
            connectsocial__To_Number__c = '1234567890',
            connectsocial__Channel__c = 'WhatsApp',
            connectsocial__Outgoing__c = true,
            connectsocial__Delivery_Status__c = 'Sent'
        );
        insert msg1;

        connectsocial__Message__c msg2 = new connectsocial__Message__c(
            connectsocial__Message_Body__c = 'Test Message 2',
            connectsocial__Type__c = 'Inbound',
            connectsocial__To_Number__c = '1234567890',
            connectsocial__Channel__c = 'WhatsApp',
            connectsocial__Outgoing__c = false,
            connectsocial__Delivery_Status__c = 'Received'
        );
        insert msg2;

        connectsocial__SMS_WhatsApp_Settings__c settings = new connectsocial__SMS_WhatsApp_Settings__c(
            connectsocial__Object_Name__c = 'Account',
            connectsocial__Phone_Field_Name__c = 'Phone'
        );
        insert settings;

        Account acc = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert acc;

        connectsocial__Message_Template__c template = new connectsocial__Message_Template__c(
            connectsocial__Channel__c = 'WhatsApp',
            connectsocial__Template_API_Name__c = 'template_api_name',
            connectsocial__Template_Name__c = 'template_name',
            connectsocial__Header__c = 'header_text',
            connectsocial__Body__c = 'body_text',
            connectsocial__Footer__c = 'footer_text',
            connectsocial__Button__c = '[]'
        );
        insert template;
        
        connectsocial__TwilioConfiguration__c twilioSetting = connectsocial__TwilioConfiguration__c.getOrgDefaults();
        twilioSetting.connectsocial__Account_SID__c = 'TestAccountSID';
        twilioSetting.connectsocial__Auth_Token__c = 'TestAuthToken';
        twilioSetting.connectsocial__Channel__c = 'SMS';
        twilioSetting.connectsocial__Messaging_Service_SID__c = 'TestMessagingServiceSID';
        twilioSetting.connectsocial__Service_Provider_Name__c = 'Twilio';
        twilioSetting.connectsocial__Twilio_Phone_Number__c = '1234567890';
        twilioSetting.connectsocial__Active__c = false;
        upsert twilioSetting;

        connectsocial__Meta_Configuration__c metaSetting = connectsocial__Meta_Configuration__c.getOrgDefaults();
        metaSetting.connectsocial__Application_Id__c = 'TestApplicationId';
        metaSetting.connectsocial__App_Secret_key__c = 'TestSecretKey';
        metaSetting.connectsocial__Auth_Token__c = 'TestAuthToken';
        metaSetting.connectsocial__Phone_Number_Id__c = 'TestPhoneNumberId';
        metaSetting.connectsocial__WhatsApp_Business_Id__c = 'TestWhatsAppBusinessId';
        metaSetting.connectsocial__Service_Provider_Name__c = 'Meta';
        metaSetting.connectsocial__Channel__c = 'WhatsApp';
        metaSetting.connectsocial__Active__c = false;
        upsert metaSetting;
    }
/**
 * @description Tests listing all messages for a given phone number.
 */
    @isTest
    static void testListAllMessages() {
        Test.startTest();
        List<connectsocial__Message__c> messages = ChatComponentController.listAllMessages('1234567890');
        Test.stopTest();
        Assert.areEqual(2, messages.size(), 'Expected 2 messages');
    }
/**
 * @description Tests listing all WhatsApp messages for a given phone number.
 */
    @isTest
    static void testListWAMessages() {
        Test.startTest();
        List<connectsocial__Message__c> messages = ChatComponentController.listWAMessages('1234567890');
        Test.stopTest();
        Assert.areEqual(2, messages.size(), 'Expected 2 WhatsApp messages');
    }
/**
 * @description Tests getting record details for a given record Id.
 */
    @isTest
    static void testGetRecordDetails() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Map<String, String> recordDetails = ChatComponentController.getRecordDetails('Account', acc.Id, 'Phone');
        Test.stopTest();
        Assert.areEqual('Test Account', recordDetails.get('Name'), 'Expected Account Name to be Test Account');
        Assert.areEqual('1234567890', recordDetails.get('Phone'), 'Expected Phone to be 1234567890');
    }
/**
 * @description Tests getting the phone field name for a given object.
 */
    @isTest
    static void testGetPhoneFieldName() {
        Test.startTest();
        String phoneFieldName = ChatComponentController.getPhoneFieldName('Account');
        Test.stopTest();
        Assert.areEqual('Phone', phoneFieldName, 'Expected Phone field name');
    }
/**
 * @description Tests saving the phone field name for a given object.
 */
    @isTest
    static void testSavePhoneFieldName() {
        Test.startTest();
        ChatComponentController.savePhoneFieldName('Contact', 'MobilePhone');
        Test.stopTest();
        connectsocial__SMS_WhatsApp_Settings__c setting = [SELECT Id, connectsocial__Phone_Field_Name__c FROM connectsocial__SMS_WhatsApp_Settings__c WHERE connectsocial__Object_Name__c = 'Contact' LIMIT 1];
        Assert.areEqual('MobilePhone', setting.connectsocial__Phone_Field_Name__c, 'Expected MobilePhone field name');
    }
/**
 * @description Tests sending an SMS using the Twilio service.
 */
    @isTest
    static void testSendSMS() {
        Test.setMock(HttpCalloutMock.class, new MockTwilioService());

        Test.startTest();
        connectsocial__Message__c message = ChatComponentController.sendSMS('','1234567890', 'Test SMS');
        Test.stopTest();
		Assert.areEqual(null, message,'Expected the message to be null after sending SMS');
    }
/**
 * @description Tests scheduling an SMS.
 */
    @isTest
    static void testScheduleSMS() {
        connectsocial__Message__c testMessage = new connectsocial__Message__c(
            connectsocial__Message_Body__c = 'Test SMS',
            connectsocial__Type__c = 'Outbound',
            connectsocial__Channel__c = 'SMS',
            connectsocial__Outgoing__c = true,
            connectsocial__To_Number__c = '917836458357',
            connectsocial__Delivery_Status__c = 'Scheduled',
            connectsocial__Scheduled_Date_Time__c = DateTime.newInstanceGmt(2023, 12, 25, 10, 0, 0)
        );
        insert testMessage;
    
        MockTwilioService mockTwilioService = new MockTwilioService(testMessage.Id);
    
        Test.setMock(HttpCalloutMock.class, mockTwilioService);
    
        Test.startTest();
        connectsocial__Message__c resultMessage = ChatComponentController.ScheduleSMS(testMessage.Id,String.valueOf(testMessage.connectsocial__To_Number__c),testMessage.connectsocial__Message_Body__c ,String.valueOf(testMessage.connectsocial__Scheduled_Date_Time__c) );
        Test.stopTest();
    
        Assert.areEqual(null, resultMessage,'Expected the result message to be null after scheduling SMS');
    
        Id testMessageIdFromMock = mockTwilioService.getTestMessageId();
        System.assertEquals(testMessage.Id, testMessageIdFromMock, 'Expected test message Id to match');
    }

/**
 * @description Tests creating a message record in Salesforce.
 */
    @isTest
    static void testCreateMessageRecord() {
        Test.startTest();
        String messageId = ChatComponentController.createMessageRecord('1234567890', 'Test SMS', 'Sent');
        Test.stopTest();
        connectsocial__Message__c message = [SELECT Id, connectsocial__Message_Body__c FROM connectsocial__Message__c WHERE Id = :messageId LIMIT 1];
        Assert.areNotEqual(null, message, 'Expected message to be not null');
        Assert.areEqual('Test SMS', message.connectsocial__Message_Body__c, 'Expected message body to be Test SMS');
    }
/**
 * @description Tests creating a scheduled record in Salesforce.
 */
       @isTest
    static void testCreateScheduleRecord() {
        Test.startTest();
        Map<String, Object> smsParams = new Map<String, Object>();
        smsParams.put('phoneNumber', '1234567890');
        smsParams.put('smsBody', 'Test SMS');
        smsParams.put('status', 'Sent');
        smsParams.put('scheduledTime', '2023-12-25T10:00:00Z');
        
        String messageId = ChatComponentController.createScheduleRecord(smsParams);
        Test.stopTest();
        
        connectsocial__Message__c message = [SELECT Id, connectsocial__Message_Body__c FROM connectsocial__Message__c WHERE Id = :messageId LIMIT 1];
        Assert.areEqual('Test SMS', message.connectsocial__Message_Body__c, 'Expected message body to be Test SMS');
    }
/**
 * @description Tests getting a single message record by Id.
 */
      @isTest
    static void testGetSingleMessage() {
        connectsocial__Message__c testMessage = new connectsocial__Message__c(
            connectsocial__Message_Body__c = 'Test Single Message',
            connectsocial__Type__c = 'Outbound',
            connectsocial__To_Number__c = '0987654321', 
            connectsocial__From_Number__c = '1234567890', 
            connectsocial__Channel__c = 'WhatsApp',
            connectsocial__Outgoing__c = true,
            connectsocial__Delivery_Status__c = 'Sent'
        );
        insert testMessage;
    
        connectsocial__Message__c insertedMessage = [SELECT Id, connectsocial__From_Number__c FROM connectsocial__Message__c WHERE Id = :testMessage.Id LIMIT 1];
        Assert.areNotEqual(null, insertedMessage, 'Expected message to be inserted');
        Assert.areEqual('1234567890', insertedMessage.connectsocial__From_Number__c, 'Expected From Number to be 1234567890');
    
        Test.startTest();
        connectsocial__Message__c singleMessage = ChatComponentController.getSingleMessage(insertedMessage.Id, '1234567890');
        Test.stopTest();
    
        Assert.areNotEqual(null, singleMessage, 'Expected single message to be not null');
        Assert.areEqual(insertedMessage.Id, singleMessage.Id, 'Expected message Id to match');
    }
/**
 * @description Tests sending a text message using the Twilio service.
 */
    @isTest
    static void testSendTextMessage() {
        Test.setMock(HttpCalloutMock.class, new MockTwilioService());

        Test.startTest();
        connectsocial__Message__c message = ChatComponentController.sendTextMessage('Hello World', '1234567890');
        Test.stopTest();
        Assert.areEqual(null, message,'Expected the message to be null after sending Text Message');
    }
/**
 * @description Tests creating a WhatsApp schedule record in Salesforce.
 */
       @isTest
    static void testCreateWhatsAppScheduleRecord() {
        Test.startTest();
        Map<String, Object> whatsappParams = new Map<String, Object>();
        whatsappParams.put('phoneNumber', '1234567890');
        whatsappParams.put('messageBody', 'Hello WhatsApp');
        whatsappParams.put('status', 'Scheduled');
        whatsappParams.put('scheduledTime', '2023-12-25T10:00:00Z');
        
        connectsocial__Message__c scheduledMessage = ChatComponentController.createWhatsAppScheduleRecord(whatsappParams);
        Test.stopTest();
        
        Assert.areNotEqual(null, scheduledMessage, 'Expected scheduled message to be not null');
        Assert.areEqual('Hello WhatsApp', scheduledMessage.connectsocial__Message_Body__c, 'Expected message body to be Hello WhatsApp');
    }

/**
 * @description Tests retrieving message templates.
 */
    @isTest
    static void testGetTemplates() {
        Test.startTest();
        List<connectsocial__Message_Template__c> templates = ChatComponentController.getTemplates('','WhatsApp');
        Test.stopTest();
        Assert.areEqual(1, templates.size(), 'Expected 1 template');
    }
}