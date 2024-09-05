/**
 * @description Test class for the WhatsAppServices class. 
 *              This class contains unit tests to verify the functionality 
 *              of the methods in the WhatsAppServices class.
 */
@isTest
public class WhatsAppServicesTest {
    /**
 * @description MockHttpResponseGenerator class implements the HttpCalloutMock interface 
 *              to generate a mock HTTP response for testing HTTP callouts.
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
    /**
 * @description Test setup method to insert necessary data before running test methods in the WhatsAppServicesTest class.
 */
     @testSetup
    static void setup() {
        connectsocial__Message_Template__c template = new connectsocial__Message_Template__c(
            connectsocial__Template_API_Name__c = 'hello_world',
            connectsocial__Template_Name__c = 'Hello World Template',
            connectsocial__Header__c = 'Media',
            connectsocial__Body__c = 'Hello, this is a template message',
            connectsocial__Footer__c = 'Footer Text',
            connectsocial__Button__c = '[{"type":"QUICK_REPLY","text":"Yes"}]'
        );
        insert template;
        connectsocial__Meta_Configuration__c metaSetting = connectsocial__Meta_Configuration__c.getOrgDefaults();
        metaSetting.connectsocial__Application_Id__c = 'TestApplicationId';
        metaSetting.connectsocial__App_Secret_key__c = 'TestSecretKey';
        metaSetting.connectsocial__Auth_Token__c = 'TestAuthToken';
        metaSetting.connectsocial__Phone_Number_Id__c = 'TestPhoneNumberId';
        metaSetting.connectsocial__WhatsApp_Business_Id__c = 'TestWhatsAppBusinessId';
        metaSetting.connectsocial__Service_Provider_Name__c = 'Meta';
        metaSetting.connectsocial__Channel__c = 'WhatsApp';
        metaSetting.connectsocial__Active__c = false;
        
        insert metaSetting;
    }
    /**
 * @description Test method to verify the functionality of sending a text message using WhatsApp.
 */
    @isTest
    static void testSendTextMessage() {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"messages":[{"id":"wamid.HBgLNTEyMzQ1Njc4OTA"}]}');
        res.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(res));
        Test.startTest();
        connectsocial__Message__c message = whatsAppServices.sendTextMessage('Hello, this is a test message', '1234567890');
        Test.stopTest();
        Assert.areNotEqual(null, message, 'Message should not be null.');
        Assert.areEqual('Hello, this is a test message', message.connectsocial__Message_Body__c, 'Message body should match.');
        Assert.areEqual('1234567890', message.connectsocial__To_Number__c, 'Recipient number should match.');
        Assert.areEqual('wamid.HBgLNTEyMzQ1Njc4OTA', message.connectsocial__Message_ID__c, 'Message ID should match.');
        Assert.areEqual('text', message.connectsocial__Message_Type__c, 'Message type should be text.');
        Assert.areEqual('Outbound', message.connectsocial__Type__c, 'Message direction should be outbound.');
        Assert.areEqual('WhatsApp', message.connectsocial__Channel__c, 'Channel should be WhatsApp.');
        Assert.areEqual('Sent', message.connectsocial__Delivery_Status__c, 'Delivery status should be Sent.');
        Assert.areEqual(true, message.connectsocial__Outgoing__c, 'Message should be outgoing.');
    }
    /**
 * @description Test method to verify the functionality of sending a template message using WhatsApp.
 */
    @isTest
    static void testSendTemplateMessage() {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"contacts":[{"input":"1234567890","wa_id":"1234567890"}],"messages":[{"id":"wamid.HBgLNTEyMzQ1Njc4OTA"}]}');
        res.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(res));
        String payload = '{'+
            '"messaging_product": "whatsapp",'+
            '"recipient_type": "individual",'+
            '"to": "1234567890",'+
            '"type": "template",'+
            '"template": {'+
            '"name": "hello_world",'+
            '"language": {"code": "en"},'+
            '"components": []'+
            '}'+
        '}';
        Test.startTest();
        connectsocial__Message__c message = whatsAppServices.sendTemplateMessage(payload, 'Template Message Body');
        Test.stopTest();
       	Assert.areNotEqual(null, message, 'Message should not be null.');
        Assert.areEqual('Template Message Body', message.connectsocial__Message_Body__c, 'Message body should match.');
        Assert.areEqual('1234567890', message.connectsocial__To_Number__c, 'Recipient number should match.');
        Assert.areEqual('wamid.HBgLNTEyMzQ1Njc4OTA', message.connectsocial__Message_ID__c, 'Message ID should match.');
        Assert.areEqual('template', message.connectsocial__Message_Type__c, 'Message type should be template.');
        Assert.areEqual('Outbound', message.connectsocial__Type__c, 'Message direction should be outbound.');
        Assert.areEqual('WhatsApp', message.connectsocial__Channel__c, 'Channel should be WhatsApp.');
        Assert.areEqual('Sent', message.connectsocial__Delivery_Status__c, 'Delivery status should be Sent.');
        Assert.areEqual(true, message.connectsocial__Outgoing__c, 'Message should be outgoing.');
    }
    /**
 * @description Test method to verify the functionality of constructing a payload for a WhatsApp message.
 */
    @isTest
    static void testConstructPayload() {
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        connectsocial__Message_Template__c template = new connectsocial__Message_Template__c(
            connectsocial__Template_API_Name__c = 'hello_world',
            connectsocial__Template_Name__c = 'Hello World Template',
            connectsocial__Header__c = 'Media',
            connectsocial__Body__c = 'Hello {!name}, this is a template message',
            connectsocial__Footer__c = 'Footer Text',
            connectsocial__Button__c = '[{"type":"QUICK_REPLY","text":"Yes"}]'
        );
        insert template;
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"contacts":[{"input":"1234567890","wa_id":"1234567890"}],"messages":[{"id":"wamid.HBgLNTEyMzQ1Njc4OTA"}]}');
        res.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(res));
        Test.startTest();
        connectsocial__Message__c message = whatsAppServices.constructPayload(acc.Id,template.Id, '1234567890', 'https://example.com/image.jpg','');
        Test.stopTest();
        Assert.areNotEqual(null, message, 'Message should not be null.');
        Assert.areEqual('1234567890', message.connectsocial__To_Number__c, 'Recipient number should match.');
        Assert.areEqual('wamid.HBgLNTEyMzQ1Njc4OTA', message.connectsocial__Message_ID__c, 'Message ID should match.');
        Assert.areEqual('template', message.connectsocial__Message_Type__c, 'Message type should be template.');
        Assert.areEqual('Outbound', message.connectsocial__Type__c, 'Message direction should be outbound.');
        Assert.areEqual('WhatsApp', message.connectsocial__Channel__c, 'Channel should be WhatsApp.');
        Assert.areEqual('Sent', message.connectsocial__Delivery_Status__c, 'Delivery status should be Sent.');
        Assert.areEqual(true, message.connectsocial__Outgoing__c, 'Message should be outgoing.');
    }
}