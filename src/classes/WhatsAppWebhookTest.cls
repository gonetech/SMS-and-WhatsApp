/**
 * @description Test class for the WhatsAppWebhook class.
 *              This class contains unit tests to verify the functionality 
 *              of the methods in the WhatsAppWebhook class.
 */
@IsTest
public class WhatsAppWebhookTest {
     /**
     * @description Setup method to insert test data.
     */  
    @testSetup
    static void setup() {
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
     * @description Test method for verifying GET request with a valid token.
     */
    @IsTest
    static void testDoGetValidToken() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/whatsapp/webhooks/v1/';
        req.httpMethod = 'GET';
        req.params.put('hub.verify_token', 'TestSecretKey');
        req.params.put('hub.challenge', 'test_challenge');
        
        RestContext.request = req;
        RestContext.response = res;
        
        WhatsAppWebhook.doGet();
        
        Assert.areEqual('test_challenge', res.responseBody.toString(), 'Response body should match the challenge.');
    }
     /**
     * @description Test method for verifying GET request with an invalid token.
     */
    @IsTest
    static void testDoGetInvalidToken() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/whatsapp/webhooks/v1/';
        req.httpMethod = 'GET';
        req.params.put('hub.verify_token', 'INVALIDTOKEN');
        req.params.put('hub.challenge', 'test_challenge');
        RestContext.request = req;
        RestContext.response = res;
        WhatsAppWebhook.doGet();
        Assert.areEqual(null, res.responseBody, 'Response body should be null for invalid token.');
    }
    /**
     * @description Test method for verifying POST request with a valid signature.
     */
    @IsTest
    static void testDoPostValidSignature() {
        String validPayload = '{"entry":[{"id":"TestWhatsAppBusinessId","changes":[{"value":{"contacts":[{"profile":{"name":"John Doe"},"wa_id":"12345"}],"messages":[{"id":"message123","type":"text","text":{"body":"Hello"},"image":{"id":"image123","mime_type":"image/jpeg","sha256":"imageSHA256"},"video":{"id":"video123","mime_type":"video/mp4","sha256":"videoSHA256"},"document":{"id":"doc123","mime_type":"application/pdf","sha256":"docSHA256"},"location":{"address":"123 Street","latitude":"45.0","longitude":"-93.0","name":"LocationName","url":"http://location.url"},"button":{"text":"ButtonText"},"reaction":{"emoji":"👍","message_id":"parentMessageId"},"context":{"id":"context123"}}],"metadata":{"display_phone_number":"123-456-7890"}}}]}]}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/whatsapp/webhooks/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(validPayload);
        req.addHeader('X-Hub-Signature-256', 'sha256=' + EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(validPayload), Blob.valueOf('TestSecretKey'))));        
        RestContext.request = req;
        RestContext.response = res;        
        HttpMock mock = new HttpMock();
        mock.setMockHttpResponse(200, '{"url":"http://example.com/image.jpg"}');        
        Test.setMock(HttpCalloutMock.class, mock);      
        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();
        List<connectsocial__Message__c> messages = [SELECT Id, connectsocial__Business_Phone_Number__c, connectsocial__From_Number__c, connectsocial__Customer_Name__c, connectsocial__Message_ID__c, connectsocial__Message_Type__c, connectsocial__Message_Body__c, connectsocial__Reaction__c, connectsocial__Parent_Message_Id__c, connectsocial__Image_ID__c, connectsocial__Image_type__c, connectsocial__Image_SHA256__c, connectsocial__Video_ID__c, connectsocial__Video_Type__c, connectsocial__Video_SHA256__c, connectsocial__Document_ID__c, connectsocial__Document_Type__c, connectsocial__Document_SHA256__c, connectsocial__Location_Address__c, connectsocial__Location_Latitude__c, connectsocial__Location_Longitude__c, connectsocial__Location_Name__c, connectsocial__Location_Link__c FROM connectsocial__Message__c];      
        Assert.areEqual(1, messages.size(), 'Expected one message record to be inserted.');        
        connectsocial__Message__c message = messages[0];
      	Assert.areEqual('123-456-7890', message.connectsocial__Business_Phone_Number__c, 'Business phone number should match.');
        Assert.areEqual('12345', message.connectsocial__From_Number__c, 'From number should match.');
        Assert.areEqual('John Doe', message.connectsocial__Customer_Name__c, 'Customer name should match.');
        Assert.areEqual('message123', message.connectsocial__Message_ID__c, 'Message ID should match.');
        Assert.areEqual('text', message.connectsocial__Message_Type__c, 'Message type should be text.');
        if (message.connectsocial__Message_Body__c == 'Hello') {
            Assert.areEqual('Hello', message.connectsocial__Message_Body__c, 'Message body should match.');
        } else {
            Assert.areEqual('ButtonText', message.connectsocial__Message_Body__c, 'Message body should match.');
        }
        Assert.areEqual('👍', message.connectsocial__Reaction__c, 'Reaction should match.');
        Assert.areEqual('parentMessageId', message.connectsocial__Parent_Message_Id__c, 'Parent message ID should match.');
        Assert.areEqual('image123', message.connectsocial__Image_ID__c, 'Image ID should match.');
        Assert.areEqual('image/jpeg', message.connectsocial__Image_type__c, 'Image type should be null.');
        Assert.areEqual('imageSHA256', message.connectsocial__Image_SHA256__c, 'Image SHA256 should match.');
        Assert.areEqual('video123', message.connectsocial__Video_ID__c, 'Video ID should match.');
        Assert.areEqual('video/mp4', message.connectsocial__Video_Type__c, 'Video type should be null.');
        Assert.areEqual('videoSHA256', message.connectsocial__Video_SHA256__c, 'Video SHA256 should match.');
        Assert.areEqual('doc123', message.connectsocial__Document_ID__c, 'Document ID should match.');
        Assert.areEqual('application/pdf', message.connectsocial__Document_Type__c, 'Document type should be null.');
        Assert.areEqual('docSHA256', message.connectsocial__Document_SHA256__c, 'Document SHA256 should match.');
        Assert.areEqual('123 Street', message.connectsocial__Location_Address__c, 'Location address should match.');
        Assert.areEqual('45.0', message.connectsocial__Location_Latitude__c, 'Location latitude should match.');
        Assert.areEqual('-93.0', message.connectsocial__Location_Longitude__c, 'Location longitude should match.');
        Assert.areEqual('LocationName', message.connectsocial__Location_Name__c, 'Location name should match.');
        Assert.areEqual('http://location.url', message.connectsocial__Location_Link__c, 'Location link should match.');

    }

	/**
     * @description Test method for verifying POST request with an invalid signature.
     */
    @IsTest
    static void testDoPostInvalidSignature() {
        String validPayload = '{"entry":[{"id":"TestWhatsAppBusinessId","changes":[{"value":{"contacts":[{"profile":{"name":"John Doe"},"wa_id":"12345"}],"messages":[{"id":"message123","type":"text","text":{"body":"Hello"}}],"metadata":{"display_phone_number":"123-456-7890"}}}]}]}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/whatsapp/webhooks/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(validPayload);
        req.addHeader('X-Hub-Signature-256', 'invalid_signature');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        WhatsAppWebhook.doPost();
        Test.stopTest();
        Assert.areEqual(401, res.statusCode,'Response status code should be 401.');
        System.assert(res.responseBody.toString().contains('Unknown'), 'Response body should contain "Unknown" message.');
    }
	/**
     * @description Test method for validating WhatsApp signature.
     */
      @IsTest
    static void testValidateWhatsAppSignature() {
        String payload = '{"test":"data"}';
        String validSignature = 'sha256=' + EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(payload), Blob.valueOf('TestSecretKey')));        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/whatsapp/webhooks/v1/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.addHeader('X-Hub-Signature-256', validSignature);        
        String result = WhatsAppWebhook.validateWhatsAppSignature(req, payload);
        Assert.areEqual(WhatsAppWebhook.SIGNATURE_VALID_MESSAGE, result, 'Signature should be valid.');
        req.headers.put('X-Hub-Signature-256', 'invalid_signature');
        result = WhatsAppWebhook.validateWhatsAppSignature(req, payload);
        Assert.areEqual(WhatsAppWebhook.SIGNATURE_NOT_VALID_MESSAGE, result, 'Signature should be not valid.');
    }
    /**
     * @description Test method for getting image URL.
     */
   @IsTest
    static void testGetImageUrl() {
        Test.startTest();
        HttpMock mock = new HttpMock();
        mock.setMockHttpResponse(200, '{"url":"http://example.com/image.jpg"}');
        Test.setMock(HttpCalloutMock.class, mock);
        String imageId = '123456';
        String result = WhatsAppWebhook.getImageUrl(imageId);        
        Test.stopTest();
        Assert.areEqual(null, result, 'Image URL should be null.');
    }
     /**
     * @description Inner class for mocking HTTP callouts.
     */
    private class HttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        void setMockHttpResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
          /**
         * @description Handles the HTTP request and generates an appropriate response based on the request's endpoint.
         * If the request endpoint contains 'image123', it returns a success response with a JSON body containing a URL to an image.
         * If the request endpoint contains 'http://example.com/image.jpg', it returns a success response with a body containing fake image data.
         * Otherwise, it returns an error response with status code 400 (Bad Request) and a JSON body with an error message indicating an unexpected endpoint.
         * @param req The HttpRequest object representing the incoming request.
         * @return An HttpResponse object representing the response to the incoming request.
         */
            public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            String endpoint = req.getEndpoint();
            if (endpoint.contains('image123')) {
                res.setStatusCode(200);
                res.setBody('{"url":"http://example.com/image.jpg"}');
            } else if (endpoint.contains('http://example.com/image.jpg')) {
                res.setStatusCode(200);
                res.setBody('fakeImageData');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error":"Unexpected endpoint"}');
            }
            return res;
        }
        
    }
}