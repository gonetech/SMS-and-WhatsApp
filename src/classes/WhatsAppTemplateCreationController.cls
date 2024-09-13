/**
 * @description Controller class for handling WhatsApp Template creation and editing.
 * @class WhatsAppTemplateCreationController
 * @with sharing
 */
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class WhatsAppTemplateCreationController {
     /**
     * @description Retrieves all available SObjects and their labels.
     * @return A map where the key is the SObject API name and the value is the label.
     * @AuraEnabled
     */
    @AuraEnabled
    public static Map<String, String> getAllObject(){
        Map<String,String> returnObjectMap = new Map<String,String>();
        Map<String, Schema.SObjectType> objectMap = Schema.getGlobalDescribe();
        List<Schema.SObjectType> objectMapValues = objectMap.Values();
        for(Schema.SObjectType objType : objectMapValues){
            String key = objType.getDescribe().getName();
            if(!key.containsignorecase('history') && !key.containsignorecase('tag')&& !key.containsignorecase('share') && !key.containsignorecase('feed') && !key.containsignorecase('status')&& !key.containsignorecase('priority')&& !key.containsignorecase('repository')&& !key.containsignorecase('partner')){
            String value = objType.getDescribe().getLabel();
            returnObjectMap.put(key,value);
            }
        }
        if(returnObjectMap != null && returnObjectMap.size() > 0){
            return returnObjectMap;
        }else{
            return null;
        }
    }
    /**
     * @description Retrieves all fields for a given SObject.
     * @param objectName The API name of the SObject.
     * @return A map where the key is the field label and the value is the field API name.
     * @AuraEnabled
     */
    @AuraEnabled
    public static Map<String, String> getAllfields(String objectName){
        Map<String, String> allFields = new Map<String, String>();
        Map<String, Schema.SObjectType> objectMap = Schema.getGlobalDescribe();
        SObjectType objType = objectMap.get(objectName);
        Map<String,Schema.SObjectField> objTypeFields = objType.getDescribe().fields.getMap();
        if(!objTypeFields.isEmpty()){
            for (String fieldName: objTypeFields.keySet()) {
                String fieldLabel = objTypeFields.get(fieldName).getDescribe().getLabel();
                allFields.put(fieldLabel,fieldName);
            }
        }
        return allFields;
    }
     /**
     * @description Handles the saving of a WhatsApp template.
     * @param templateDataStr The template data as a JSON string.
     * @throws AuraHandledException if the user lacks the necessary permissions.
     * @AuraEnabled
     */
    @AuraEnabled
    public static void handleSave(String templateDataStr) {
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(templateDataStr);
        Map<String, Object> headerMedia = (Map<String, Object>) results.get('headerMedia');
        String templateName = (String) results.get('templateName');
		if (!Schema.sObjectType.connectsocial__Message_Template__c.isCreateable()) {
        	throw new AuraHandledException('You do not have permission to create connectsocial__Message_Template__c records.');
    	}
        connectsocial__Message_Template__c msgtemp = new connectsocial__Message_Template__c();
        msgtemp.connectsocial__Template_Name__c = templateName;
        msgtemp.connectsocial__Channel__c = (String) results.get('channel');
        msgtemp.connectsocial__Object_Name__c = (String) results.get('objectName');
		msgtemp.connectsocial__Body__c = (String) results.get('bodyText');    
        msgtemp.connectsocial__Template_API_Name__c = templateName.replaceAll(' ','_').toLowerCase();
        if (!CommonUtil.hasFLS(msgtemp)) {
        	throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
    	}
        Map<String, Object> requestBody = new Map<String, Object>();       
        if((String) results.get('channel') == 'WhatsApp'){
            requestBody.put('name', msgtemp.connectsocial__Template_API_Name__c);
            requestBody.put('category','Marketing');
            requestBody.put('language','en');
            List<Object> components = new List<Object>();
            Map<String, Object> bodyParams = new Map<String, Object>();
            bodyParams.put('type','BODY');
            bodyParams.put('text',results.get('formattedBodyText'));
            if(results.containsKey('example')){
                bodyParams.put('example',results.get('example'));
            }
            components.add(bodyParams);
            String headerVal = (String) results.get('header');
            if (headerVal == 'Text' && String.isNotBlank((String) results.get('headerText'))) {
                Map<String, Object> headerParams = new Map<String, Object>();
                headerParams.put('type', 'HEADER');
                headerParams.put('format', 'TEXT');
                headerParams.put('text', results.get('headerText'));
                components.add(headerParams);
                msgtemp.connectsocial__Header__c = (String) results.get('headerText');
            } else if (headerVal == 'Image' || headerVal == 'Video' || headerVal == 'Document') {
                String fileData = (String) headerMedia.get('fileData');
                if (String.isNotBlank(fileData)) {
                    Blob fileBlob = EncodingUtil.base64Decode(fileData);
                    Integer fileLength = (Integer) headerMedia.get('fileSize');
                    String fileType = (String) headerMedia.get('fileType');
                    String fileId = uploadFileDetails(fileLength, fileType);
                    String headerHandle = initiateUpload(fileId, fileBlob);                
                    Map<String, Object> headerParams = new Map<String, Object>();
                    headerParams.put('type', 'HEADER');
                    headerParams.put('format', headerVal.toUpperCase());
                    if (String.isNotBlank(headerHandle)) {
                        List<String> headerHandles = new List<String>();
                        headerHandles.add(headerHandle);
                        Map<String, Object> exampleMap = new Map<String, Object>{ 'header_handle' => headerHandles };
                            headerParams.put('example', exampleMap);
                    }
                    components.add(headerParams);
                    msgtemp.connectsocial__Header__c = headerVal;
                }
            }
            if(String.isNotBlank((String) results.get('footerText'))){
                Map<String, Object> footerParams = new Map<String, Object>();
                footerParams.put('type','FOOTER');
                footerParams.put('text',results.get('footerText'));
                components.add(footerParams);
                msgtemp.connectsocial__Footer__c = (String) results.get('footerText');
            }
            List<Object> buttons = (List<Object>) results.get('buttons');
            if(buttons.size() > 0){
                Map<String, Object> buttonParams = new Map<String, Object>();
                buttonParams.put('type','BUTTONS');
                buttonParams.put('buttons',results.get('buttons'));
                components.add(buttonParams);
                msgtemp.connectsocial__Button__c = JSON.serialize((List<Object>) results.get('buttons'));
            }
            requestBody.put('components',components);
            connectsocial__Meta_Configuration__c whatsAppCreds = ProviderSettingUtil.getWhatsAppProviderSettings('WhatsApp');
            String endpointUrl = 'callout:connectsocial__Meta_API/v18.0/' + whatsAppCreds.WhatsApp_Business_Id__c + '/message_templates';
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint(endpointUrl);
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    		httpRequest.setHeader('Pragma', 'no-cache');
            httpRequest.setHeader('Expires', '0');
    		httpRequest.setHeader('X-Content-Type-Options', 'nosniff');
            httpRequest.setBody(JSON.serialize(requestBody));
            Http http = new Http();
            HttpResponse response = http.send(httpRequest);
            if (response.getStatusCode() == 200) {
                Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody()); 
                msgtemp.connectsocial__Status__c	 = 'Success';
                msgtemp.connectsocial__WhatsApp_Template_ID__c = (String) resBody.get('id');
                insert msgtemp;
            } else {
                msgtemp.connectsocial__Status__c = 'Failed';
                msgtemp.connectsocial__Error_Response__c = response.getBody();
                insert msgtemp;
            }
        } else {
            insert msgtemp;
        }        
    }
	/**
 * @description Uploads file details to the Facebook Graph API.
 * @param fileLength The length of the file.
 * @param fileType The type of the file.
 * @return The file ID returned by the Facebook Graph API.
 * @throws CalloutException if the file upload fails.
 */
    public static String uploadFileDetails(Integer fileLength, String fileType) {
        connectsocial__Meta_Configuration__c whatsAppCreds = ProviderSettingUtil.getWhatsAppProviderSettings('WhatsApp');
        String endpointUrl = 'callout:connectsocial__Meta_API/v18.0/' + whatsAppCreds.Application_Id__c + '/uploads';
        String authToken = whatsAppCreds.Auth_Token__c;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        request.setHeader('Pragma', 'no-cache');
        request.setHeader('Expires', '0');
        request.setHeader('X-Content-Type-Options', 'nosniff');
        request.setBody('file_length=' + fileLength + '&file_type=' + fileType + '&access_token=' + authToken);

        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return (String) jsonResponse.get('id');
        } else {
            throw new CalloutException('Failed to upload file details. Error: ' + response.getBody());
        }
    }
    /**
 * @description Initiates the file upload process to the Facebook Graph API.
 * @param fileId The file ID returned from the uploadFileDetails method.
 * @param fileBlob The file data as a Blob.
 * @return The handle returned by the Facebook Graph API for the uploaded file.
 * @throws CalloutException if the file upload initiation fails.
 */
    public static String initiateUpload(String fileId, Blob fileBlob) {
        connectsocial__Meta_Configuration__c whatsAppCreds = ProviderSettingUtil.getWhatsAppProviderSettings('WhatsApp');
        String endpoint = 'https://graph.facebook.com/v18.0/' + fileId;
        String authToken = whatsAppCreds.Auth_Token__c;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'OAuth ' + authToken);
        request.setHeader('file_offset', '0');
        request.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        request.setHeader('Pragma', 'no-cache');
        request.setHeader('Expires', '0');
        request.setHeader('X-Content-Type-Options', 'nosniff');
        request.setBodyAsBlob(fileBlob);
        Http http = new Http();
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return (String) jsonResponse.get('h');
        } else {
            throw new CalloutException('Failed to initiate upload session. Error: ' + response.getBody());
        }
    }
	/**
 * @description Handles the editing of an existing WhatsApp template.
 * @param templateDataStr The template data as a JSON string.
 * @param waTemplateId The WhatsApp template ID.
 * @param templateId The Salesforce template record ID.
 * @return A status string indicating the result of the operation.
 * @AuraEnabled
 */
    @AuraEnabled
    public static String handleEdit(String templateDataStr, String waTemplateId, String templateId) {
        try{
        connectsocial__Message_Template__c tempRecord = [SELECT Id, LastModifiedDate FROM connectsocial__Message_Template__c WHERE Id = :templateId With SECURITY_ENFORCED LIMIT 1];
        DateTime now = DateTime.now();
        DateTime lastModified = tempRecord.LastModifiedDate;
        if (lastModified.addHours(24) > now) {
            return 'error_24_hour_limit';
        }
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(templateDataStr);
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('name', (String) results.get('templateName'));
        requestBody.put('category', 'Marketing');
        requestBody.put('language', 'en');
        List<Object> components = new List<Object>();
        Map<String, Object> bodyParams = new Map<String, Object>();
        bodyParams.put('type', 'BODY');
        bodyParams.put('text', (String) results.get('formattedBodyText'));
        if (results.containsKey('example')) {
            bodyParams.put('example', results.get('example'));
        }
        components.add(bodyParams);
        if ((String) results.get('header') == 'Text' && String.isNotBlank((String) results.get('headerText'))) {
            Map<String, Object> headerParams = new Map<String, Object>();
            headerParams.put('type', 'HEADER');
            headerParams.put('format', 'TEXT');
            headerParams.put('text', results.get('headerText'));
            components.add(headerParams);
        }
        if (String.isNotBlank((String) results.get('footerText'))) {
            Map<String, Object> footerParams = new Map<String, Object>();
            footerParams.put('type', 'FOOTER');
            footerParams.put('text', results.get('footerText'));
            components.add(footerParams);
        }
        List<Object> buttons = (List<Object>) results.get('buttons');
        if (buttons.size() > 0) {
            Map<String, Object> buttonParams = new Map<String, Object>();
            buttonParams.put('type', 'BUTTONS');
            buttonParams.put('buttons', buttons);
            components.add(buttonParams);
        }
        requestBody.put('components', components);
		String endpointUrl = 'callout:connectsocial__Meta_API/v18.0/' +waTemplateId;        
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(endpointUrl);
        httpRequest.setMethod('POST'); 
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        httpRequest.setHeader('Pragma', 'no-cache');
        httpRequest.setHeader('Expires', '0');
        httpRequest.setHeader('X-Content-Type-Options', 'nosniff');
        httpRequest.setBody(JSON.serialize(requestBody));    
        Http http = new Http();
        HttpResponse response = http.send(httpRequest);
        if (response.getStatusCode() == 200) {
            if (!Schema.sObjectType.connectsocial__Message_Template__c.isUpdateable()) {
        		throw new AuraHandledException('You do not have permission to update connectsocial__Message_Template__c records.');
    		}
            connectsocial__Message_Template__c templateRecord = new connectsocial__Message_Template__c(Id = TemplateId);
            templateRecord.connectsocial__Template_Name__c = (String) results.get('templateName');
            templateRecord.connectsocial__Channel__c = 'WhatsApp';
            templateRecord.connectsocial__Body__c = (String) results.get('bodyText');
            templateRecord.connectsocial__Header__c = (String) results.get('headerText');
            templateRecord.connectsocial__Footer__c = (String) results.get('footerText');
            templateRecord.connectsocial__Button__c = JSON.serialize((List<Object>) results.get('buttons'));
            if (!CommonUtil.hasFLS(templateRecord)) {
        		throw new AuraHandledException('You do not have the necessary field permissions to update connectsocial__Message_Template__c records.');
    		}
            update templateRecord; 
            return 'success';
        } else {
            return 'error';
        }
        } catch (QueryException e) {
        return 'error_no_record_found';
    } catch (Exception e) {
    	return 'error_exception_occurred';
    }
        
    }
}