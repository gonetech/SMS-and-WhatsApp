/**
* @description REST resource for handling WhatsApp webhooks.
* @class WhatsAppWebhook
* @without sharing
*/
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
@RestResource(urlMapping='/whatsapp/webhooks/v1/*')
global with sharing class WhatsAppWebhook {
    /**
* @description Message indicating signature verification success.
*/
    public static Final String SIGNATURE_VALID_MESSAGE     = 'Signature Verified';
    /**
* @description Message indicating signature verification failure.
*/
    public static Final String SIGNATURE_NOT_VALID_MESSAGE = 'Signature could not be verified';
    /**
* @description Handles HTTP GET requests to verify the webhook.
* @HttpGet
* @global static void doGet()
*/
    @HttpGet
    global static void doGet() {
        RestResponse response = RestContext.response;
        RestRequest request = RestContext.request;
        connectsocial__Meta_Configuration__c whatsAppCreds = connectsocial__Meta_Configuration__c.getInstance();
        if(request.params.get('hub.verify_token') == whatsAppCreds.connectsocial__App_Secret_key__c){
            response.responseBody = Blob.valueOf( request.params.get('hub.challenge') );
        }
    }
    /**
* @description Handles HTTP POST requests containing WhatsApp webhook data.
* @HttpPost
* @global static void doPost()
*/
    @HttpPost
    global static void doPost() {
        RestResponse response = RestContext.response;
        RestRequest request = RestContext.request;
        response.addHeader('Content-type', 'application/json');
        String responseString = RestContext.request.requestBody.toString();
        String responseValid = validateWhatsAppSignature(RestContext.request, responseString);
        if (responseValid == SIGNATURE_VALID_MESSAGE) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseString);
            	List<Object> entryList = (List<Object>) responseMap.get('entry');
            	if (entryList != null && !entryList.isEmpty()) {
                MessageUpdateHelper.processIncomingMessage(responseString);
            }
        }else{
            response.responseBody = Blob.valueOf('{success:false, event:"Unknown","message:"'+responseValid+'"}');
            response.statusCode = 401;
            return;
        }
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{success:true, event:"success"}');
    }
    /**
* @description Validates the signature of the incoming WhatsApp webhook request.
* @param request The incoming REST request.
* @param responseString The body of the incoming request as a string.
* @return A message indicating whether the signature is valid or not.
*/
    public static String validateWhatsAppSignature(RestRequest request, String responseString) {
        connectsocial__Meta_Configuration__c whatsAppCreds = connectsocial__Meta_Configuration__c.getInstance();
        Map<String, String> headers = request.headers;
        String whatsAppSignature = headers.get('X-Hub-Signature-256');
        String whatsAppPayload = responseString;
        String fbAppSecret =  whatsAppCreds.connectsocial__App_Secret_key__c;
        Blob signedPayload = Crypto.generateMac('hmacSHA256', Blob.valueOf(whatsAppPayload), Blob.valueOf( fbAppSecret ));
        String encodedPayload = 'sha256='+EncodingUtil.convertToHex(signedPayload);
        String response = (encodedPayload == whatsAppSignature)? SIGNATURE_VALID_MESSAGE : SIGNATURE_NOT_VALID_MESSAGE;
        return response;
    }
    /**
* @description Retrieves the image URL for a given image ID from Facebook Graph API.
* @param imageId The ID of the image.
* @return The base64 encoded image data.
*/
    global static String getImageUrl(String imageId) {
        connectsocial__Meta_Configuration__c whatsAppCreds = ProviderSettingUtil.getWhatsAppProviderSettings('WhatsApp');
        String endpointUrl = 'callout:connectsocial__Meta_API/v18.0/';
        String accessToken = whatsAppCreds.connectsocial__Auth_Token__c;
        String imageLink = endpointUrl + imageId + '/?access_token=' + accessToken;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(imageLink);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
		request.setHeader('Pragma', 'no-cache');
		request.setHeader('Expires', '0');
		request.setHeader('X-Content-Type-Options', 'nosniff');
        HttpResponse response = http.send(request);
        
        if (response != null && response.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String imageUrl = (String) jsonResponse.get('url');
            String endpoint = imageUrl;
            HttpRequest downloadRequest = new HttpRequest();
            downloadRequest.setEndpoint(endpoint);
            downloadRequest.setMethod('GET');
            downloadRequest.setHeader('Content-Type', 'application/json');
            downloadRequest.setHeader('Authorization', 'Bearer ' +whatsAppCreds.connectsocial__Auth_Token__c);
            downloadRequest.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
			downloadRequest.setHeader('Pragma', 'no-cache');
			downloadRequest.setHeader('Expires', '0');
			downloadRequest.setHeader('X-Content-Type-Options', 'nosniff');
            HttpResponse downloadResponse = http.send(downloadRequest);
            if (downloadResponse != null && downloadResponse.getStatusCode() == 200) {
                Blob imageData = downloadResponse.getBodyAsBlob();
                String base64Image = EncodingUtil.base64Encode(imageData);
                return base64Image;
            } 
            else {
                return null;
            }
        } else {
            return null;
        }
    }
}