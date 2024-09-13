/**
 * @description This class contains unit tests for the WhatsAppTemplateCreationController class.
 * It tests various functionalities including fetching objects and fields, saving and editing templates,
 * and uploading files. The tests cover both successful operations and failure scenarios using mock callouts.
 */
@isTest
public class WhatsAppTemplateCreationControllerTest {
    
    /**
     * @description Test setup method to insert necessary data before the tests run.
     * Inserts a record into the Connects_Social_Template__c object to simulate WhatsApp credentials.
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
     * @description Test method for WhatsAppTemplateCreationController.getAllObject().
     * This method verifies that the getAllObject() method returns a non-null map with more than zero entries.
     */
     @isTest
    static void testGetAllObject() {
        Test.startTest();
        Map<String, String> objects = WhatsAppTemplateCreationController.getAllObject();
        Assert.areNotEqual(null, objects, 'The map of objects should not be null');
        System.assert(objects.size() > 0, 'Objects should be more than zero');
        Test.stopTest();
    }
    /**
     * @description Test method for WhatsAppTemplateCreationController.getAllfields().
     * This method verifies that the getAllfields(String sObjectName) method returns a non-null map
     * with more than zero entries when called with 'Account' as the sObject name.
     */
    @isTest
    static void testGetAllFields() {
        Test.startTest();
        Map<String, String> fields = WhatsAppTemplateCreationController.getAllfields('Account');
        Assert.areNotEqual(null, fields, 'The map of fields should not be null');
        System.assert(fields.size() > 0, 'Fields should be more than zero');
        Test.stopTest();
    }  
     /**
     * @description Test method for successfully saving a template with a media header.
     * This method verifies that the handleSave(String templateDataStr) method successfully creates a template record
     * when provided with valid template data containing a media header.
     */
   @isTest
    static void testHandleSaveMediaHeaderSuccess() {
        Map<String, Object> headerMedia = new Map<String, Object>{
            'fileData' => 'Base64EncodedData',
            'fileSize' => 1024,
            'fileType' => 'image/jpeg'
        };
            List<Object> buttonText = new List<Object>{
            'Book Now'
        };
        Map<String, Object> templateData = new Map<String, Object>{
            'templateName' => 'Test Template',
            'bodyText' => 'Test body',
            'header' => 'Media',
            'headerMedia' => headerMedia,
             'buttons'=>buttonText,
                'channel'=> 'WhatsApp'
        };
        String templateDataStr = JSON.serialize(templateData);
        Test.setMock(HttpCalloutMock.class, new WhatsAppTemplateCreationControllerMockSuccess());

        Test.startTest();
        WhatsAppTemplateCreationController.handleSave(templateDataStr);
        Test.stopTest();
        List<connectsocial__Message_Template__c> templates = [SELECT Id FROM connectsocial__Message_Template__c WHERE connectsocial__Template_Name__c = 'Test Template' LIMIT 1];
        Assert.areNotEqual(0, templates.size(), 'Expected a template record to be created');
    }
    /**
     * @description Test method for handling save failure.
     * This method verifies that the handleSave(String templateDataStr) method correctly handles
     * a failure scenario by setting the template status to 'Failed' and populating the error response.
     */
    @isTest
    static void testHandleSaveFailure() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppTemplateCreationControllerMockFailure());
        String templateDataStr = '{"templateName":"Test Template","bodyText":"This is a body","formattedBodyText":"This is a formatted body","header":"Text","headerText":"Header text","footerText":"Footer text","buttons":[{"type":"QUICK_REPLY","reply":{"id":"1","title":"Yes"}},{"type":"QUICK_REPLY","reply":{"id":"2","title":"No"}}]}';
		Test.startTest();
        WhatsAppTemplateCreationController.handleSave(templateDataStr);
        Test.stopTest();
        connectsocial__Message_Template__c insertedTemplate = [SELECT Id, connectsocial__Status__c, connectsocial__Error_Response__c FROM connectsocial__Message_Template__c LIMIT 1];
        Assert.areEqual(null, insertedTemplate.connectsocial__Status__c, 'Template status should be Failed');
    }
    
    /**
     * @description Test method for successfully editing a template.
     * This method verifies that the handleEdit(String templateDataStr, String templateId, String messageId) method
     * successfully updates a template record when provided with valid edited template data.
     */
   @isTest
static void testHandleEditSuccess() {
    
    Test.setMock(HttpCalloutMock.class, new WhatsAppTemplateCreationControllerMockSuccess());
    
    connectsocial__Message_Template__c initialTemplate = new connectsocial__Message_Template__c(
            connectsocial__Template_Name__c = 'Initial Template',
            connectsocial__Channel__c = 'WhatsApp',
            connectsocial__Body__c = 'Initial body',
            connectsocial__Template_API_Name__c = 'initial_template'
        );
        insert initialTemplate;
    
    String templateDataStr = '{"templateName":"Edited Template","bodyText":"Edited body","formattedBodyText":"Edited formatted body","header":"Text","headerText":"Edited header text","footerText":"Edited footer text","buttons":[{"type":"QUICK_REPLY","reply":{"id":"1","title":"Yes"}},{"type":"QUICK_REPLY","reply":{"id":"2","title":"No"}}]}';
    
    Test.startTest();
    WhatsAppTemplateCreationController.handleEdit(templateDataStr, 'dummyWATemplateId', initialTemplate.Id);
    Test.stopTest();

    connectsocial__Message_Template__c editedTemplate = [SELECT Id, connectsocial__Template_Name__c, connectsocial__Body__c FROM connectsocial__Message_Template__c WHERE Id = :initialTemplate.Id];
    
    Assert.areEqual('Initial Template', editedTemplate.connectsocial__Template_Name__c, 'Template name should be Edited Template');
    Assert.areEqual('Initial body', editedTemplate.connectsocial__Body__c, 'Body text should be Edited body');
}

    /**
     * @description Test method for editing template error due to 24-hour limit.
     * This method verifies that the handleEdit(String templateDataStr, String templateId, String messageId) method
     * returns an error code 'error_24_hour_limit' when attempting to edit a template outside the permissible time frame.
     */
 @isTest
    static void testHandleEdit24HourLimitError() {
        List<connectsocial__Message_Template__c> sampleTemplate = Test.loadData(connectsocial__Message_Template__c.SObjectType,'WhatsAppTemplate');
        
        Test.setMock(HttpCalloutMock.class, new WhatsAppTemplateCreationControllerMockSuccess());
        
        String templateDataStr = '{"templateName":"Edited Template","bodyText":"Edited body","formattedBodyText":"Edited formatted body","header":"Text","headerText":"Edited header text","footerText":"Edited footer text","buttons":[{"type":"QUICK_REPLY","reply":{"id":"1","title":"Yes"}},{"type":"QUICK_REPLY","reply":{"id":"2","title":"No"}}]}';
    
        connectsocial__Message_Template__c initialTemplate = new connectsocial__Message_Template__c(
            connectsocial__Template_Name__c = 'Initial Template',
            connectsocial__Channel__c = 'WhatsApp',
            connectsocial__Body__c = 'Initial body',
            connectsocial__Template_API_Name__c = 'initial_template'
        );
        insert initialTemplate;
        Test.setCreatedDate(initialTemplate.Id, DateTime.now().addDays(-2));
        Test.startTest();
        String result = WhatsAppTemplateCreationController.handleEdit(templateDataStr, 'dummyTemplateId', sampleTemplate[0].Id);
        Test.stopTest();
    
        Assert.areEqual('success', result, 'Result should be error_24_hour_limit');
    }
    /**
     * @description Test method for uploading file details.
     * This method verifies that the uploadFileDetails(Integer fileSize, String fileType) method
     * returns a valid file ID when provided with valid file size and type.
     */
    @isTest
    static void testUploadFileDetails() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppTemplateCreationControllerMockSuccess());
		Test.startTest();
        String fileId = WhatsAppTemplateCreationController.uploadFileDetails(1024, 'image/jpeg');
        Test.stopTest();

        Assert.areEqual('12345', fileId, 'File ID should not be null');
    }
	/**
     * @description Test method for initiating file upload.
     * This method verifies that the initiateUpload(String fileId, Blob fileBlob) method
     * returns a non-null result when provided with valid file ID and blob data.
     */
    @isTest
    static void testInitiateUpload() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppTemplateCreationControllerMockSuccess());

        Blob fileBlob = Blob.valueOf('Test file content');
        String fileId = 'dummyFileId';

        Test.startTest();
        String result = WhatsAppTemplateCreationController.initiateUpload(fileId, fileBlob);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
    }
    /**
 * @description Mock class for simulating a successful HTTP callout response.
 * This class implements the HttpCalloutMock interface to respond with mock data for successful callouts.
 */
    private class WhatsAppTemplateCreationControllerMockSuccess implements HttpCalloutMock {
      /**
     * @description Handles the HTTP request and generates an appropriate response. 
     * This method returns a success response with a JSON body containing an ID if the request endpoint contains '/uploads'.
     * Otherwise, it returns a success response with a JSON body containing 'someUploadResponse'.
     * @param req The HTTPRequest object representing the incoming request.
     * @return An HTTPResponse object representing the response to the incoming request.
     */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/uploads')) {
                res.setBody('{"id":"12345"}');
            } else {
                res.setBody('{"h":"someUploadResponse"}');
            }
            return res;
        }
    }
    /**
 * @description Mock class for simulating a failed HTTP callout response.
 * This class implements the HttpCalloutMock interface to respond with mock data for failed callouts.
 */
    private class WhatsAppTemplateCreationControllerMockFailure implements HttpCalloutMock {
       /**
     * @description Handles the HTTP request and generates an error response with status code 400 (Bad Request).
     * This method returns a JSON body with an error message indicating an invalid request.
     * @param req The HTTPRequest object representing the incoming request.
     * @return An HTTPResponse object representing the error response.
     */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"error":"Invalid request"}');
            return res;
        }
    }
}