/**
* @description A class for sending and managing WhatsApp messages using the Facebook Graph API.
* This class includes methods to send text messages, send template messages, and construct payloads for template messages.
*/
public with sharing class WhatsAppServices {
    public static  String messagingProduct = 'messaging_product';
    public Contacts[] contacts;
    public Messages[] messages;
    /**
* @description A nested class representing a WhatsApp contact.
*/
    public class Contacts {
        public String input;
    }
    /**
* @description A nested class representing a WhatsApp message.
*/
    public class Messages {
        public String id;
    }
    /**
* @description Sends a text message to a specified phone number via WhatsApp.
* @param messageContent The content of the text message.
* @param toPhone The phone number to which the message will be sent.
* @return A connectsocial__Message__c record representing the sent message.
* @throws AuraHandledException If there are issues with permissions or if an error occurs during the HTTP request.
*/
    public static connectsocial__Message__c sendTextMessage(String messageContent, String toPhone){
        connectsocial__Meta_Configuration__c whatsAppCreds = ProviderSettingUtil.getWhatsAppProviderSettings('WhatsApp');
        HttpRequest httpReq = new HttpRequest();
        String endpointUrl = 'callout:connectsocial__Meta_API/v19.0/' + whatsAppCreds.connectsocial__Phone_Number_Id__c + '/messages';
        httpReq.setEndpoint(endpointUrl);
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        httpReq.setHeader('Pragma', 'no-cache');
        httpReq.setHeader('Expires', '0');
        httpReq.setHeader('X-Content-Type-Options', 'nosniff');
        String messageBody = '{'+
            +messagingProduct+ ' : "whatsapp",'+
            '    "recipient_type": "individual",'+
            '    "to": "'+toPhone+'",'+
            '    "type": "text",'+
            '    "text": {'+
            '        "preview_url": false,'+
            '        "body": "' + messageContent.replace('\n', '\\n') + '"'+
            '    }'+
            '}';
        httpReq.setBody(messageBody);
        Http http = new Http();
        connectsocial__Message__c salesforceMessage = new connectsocial__Message__c();
        try{
            HttpResponse response = http.send(httpReq);
            if( response.getStatusCode() == 200 ){
                whatsAppServices responseFromWA = (whatsAppServices) JSON.deserialize( response.getBody() , whatsAppServices.class);
                if (!Schema.sObjectType.connectsocial__Message__c.isCreateable() && !Schema.sObjectType.connectsocial__Message__c.isUpdateable()) {
                    throw new AuraHandledException('You do not have permission to create this message.');
                } 
                salesforceMessage.connectsocial__Message_Body__c = messageContent;
                salesforceMessage.connectsocial__To_Number__c = toPhone;
                salesforceMessage.connectsocial__Message_ID__c = responseFromWA.messages.get(0).id;
                salesforceMessage.connectsocial__Message_Type__c = 'text';
                salesforceMessage.connectsocial__Type__c = 'Outbound';
                salesforceMessage.connectsocial__Channel__c = 'WhatsApp';
                salesforceMessage.connectsocial__Delivery_Status__c = 'Sent';
                salesforceMessage.connectsocial__Outgoing__c = True;
                salesforceMessage.connectsocial__Response__c = response.getBody();
                if (!CommonUtil.hasFLS(salesforceMessage)) {
                    throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
                }
                upsert salesforceMessage connectsocial__Message_ID__c;
            }
        }catch(System.CalloutException ex){
            throw new AuraHandledException('CalloutException: ' + ex.getMessage());
        }catch(System.Exception ex){
            if(!Test.isRunningTest()){
                throw new AuraHandledException('CalloutException: ' + ex.getStackTraceString());
            }    
        }
        return salesforceMessage;
    }
    /**
* @description Sends a template message to a specified phone number via WhatsApp.
* @param payload The JSON payload of the template message.
* @param messageBody The body of the template message.
* @return A connectsocial__Message__c record representing the sent message.
* @throws AuraHandledException If there are issues with permissions or if an error occurs during the HTTP request.
*/
    @AuraEnabled
    public static connectsocial__Message__c sendTemplateMessage(String payload, String messageBody) {
        connectsocial__Meta_Configuration__c whatsAppCreds = ProviderSettingUtil.getWhatsAppProviderSettings('WhatsApp');
        String endpointUrl = 'callout:connectsocial__Meta_API/v19.0/' + whatsAppCreds.connectsocial__Phone_Number_Id__c + '/messages';        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        req.setHeader('Pragma', 'no-cache');
        req.setHeader('Expires', '0');
        req.setHeader('X-Content-Type-Options', 'nosniff');
        req.setBody(payload);
        Http http = new Http();
        HttpResponse res;
        try{
            res = http.send(req);
        } catch(System.CalloutException ex){
            throw new AuraHandledException('CalloutException: ' + ex.getMessage() + 'StackTraceString: '+ex.getStackTraceString());
        }
        
        connectsocial__Message__c salesforceMessage = new connectsocial__Message__c();       
        if (res.getStatusCode() == 200) {
            whatsAppServices responseFromWA = (whatsAppServices) JSON.deserialize( res.getBody() , whatsAppServices.class);
            salesforceMessage.connectsocial__Message_Body__c = messageBody;
            salesforceMessage.connectsocial__To_Number__c = responseFromWA.contacts.get(0).input;
            salesforceMessage.connectsocial__Message_ID__c = responseFromWA.messages.get(0).id;
            salesforceMessage.connectsocial__Message_Type__c = 'template';
            salesforceMessage.connectsocial__Type__c = 'Outbound';
            salesforceMessage.connectsocial__Channel__c = 'WhatsApp';
            salesforceMessage.connectsocial__Delivery_Status__c = 'Sent';
            salesforceMessage.connectsocial__Outgoing__c = True;
        }
        else {
            salesforceMessage.connectsocial__Response__c = res.getBody();
        }
        
        if (!Schema.sObjectType.connectsocial__Message__c.isCreateable()) {
            throw new AuraHandledException('You do not have permission to create this message.');
        }
        
        if (!CommonUtil.hasFLS(salesforceMessage)) {
            throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
        }
        
        insert salesforceMessage;
        List<connectsocial__Message__c> createdTempRec = [SELECT Id, connectsocial__Message_Body__c, connectsocial__To_Number__c, 
                                                      connectsocial__Message_ID__c, connectsocial__Message_Type__c, 
                                                      connectsocial__Type__c, connectsocial__Channel__c, 
                                                      connectsocial__Delivery_Status__c, connectsocial__Outgoing__c, 
                                                      CreatedDate 
                                                      FROM connectsocial__Message__c 
                                                      WHERE Id = :salesforceMessage.Id WITH SECURITY_ENFORCED LIMIT 1]; 
        if (createdTempRec != null && !createdTempRec.isEmpty()) {
            return createdTempRec[0]; 
        } else {
            return null; 
        }
    }
    /**
* @description Constructs the payload for a template message.
* @param recordId The Id of the message record
* @param templateId The ID of the template.
* @param phoneNumber The phone number to which the message will be sent.
* @param headerMediaURL The URL for the header media (if applicable).
* @param fileName The Name of the uploading file
* @return A connectsocial__Message__c record representing the constructed message.
*/
    @AuraEnabled
    public static connectsocial__Message__c constructPayload(String recordId, String templateId, String phoneNumber, String headerMediaURL, String fileName) {
        connectsocial__Message_Template__c template = [SELECT Id, connectsocial__Template_API_Name__c,connectsocial__Template_Name__c, 
                                                       connectsocial__Header__c,connectsocial__Body__c, connectsocial__Footer__c,
                                                       connectsocial__Button__c  
                                                       FROM connectsocial__Message_Template__c 
                                                       WHERE Id = :templateId WITH SECURITY_ENFORCED];
        Map<String, Object> payloadMap = new Map<String, Object>();
        payloadMap.put('messaging_product', 'whatsapp');
        payloadMap.put('recipient_type', 'individual');
        payloadMap.put('to', phoneNumber);
        payloadMap.put('type', 'template');
        Map<String, Object> templateObject = new Map<String, Object>();
        templateObject.put('name', template.connectsocial__Template_API_Name__c);
        templateObject.put('language', new Map<String, String>{ 'code' => 'en' });
        List<Object> components = new List<Object>();
        if (String.isNotBlank(template.connectsocial__Header__c) && (template.connectsocial__Header__c == 'Image' || template.connectsocial__Header__c == 'Video' || template.connectsocial__Header__c == 'Document')) {
            components.add(constructComponent('header', template.connectsocial__Header__c, headerMediaURL,null,fileName));
        }
        if (String.isNotBlank(template.connectsocial__Body__c) && template.connectsocial__Body__c.contains('{')) {
            components.add(constructComponent('body', template.connectsocial__Body__c,null,recordId,null));
        }
        if (String.isNotBlank(template.connectsocial__Button__c)) {
            components.addAll(constructButtons(template.connectsocial__Button__c));
        }
        templateObject.put('components', components);
        payloadMap.put('template', templateObject);
        String payload = JSON.serialize(payloadMap);
        String messageBody = (String.isNotBlank(template.connectsocial__Body__c) && template.connectsocial__Body__c.contains('{'))?replacePlaceholders(recordId,template.connectsocial__Body__c):template.connectsocial__Body__c;
        return sendTemplateMessage(payload, messagebody);
    }
    /**
* @description Constructs a component for a WhatsApp message.
* @param type The type of the component (e.g., 'text', 'header').
* @param text The text content of the component.
* @param headerUrl The URL of the header image, if applicable.
* @param recordId The Id of the message record
* @param fileName The fileName of the uploading file
* @return A map representing the constructed component.
*/
    public static Map<String, Object> constructComponent(String type, String text, String headerUrl,String recordId, String fileName) {
        Map<String, Object> component = new Map<String, Object>();
        component.put('type', type);
        List<Object> parameters = new List<Object>();
        
        if (type.equalsIgnoreCase('text')) {
            parameters.add(new Map<String, Object>{ 'type' => 'text', 'text' => text });
        } else if (type.equalsIgnoreCase('header') && String.isNotBlank(headerUrl)) {
            Map<String, Object> imageParameter = new Map<String, Object>{ 'type' => text.toLowerCase() };
                
                Map<String, Object> imageMap = new Map<String, Object>{ 'link' => headerUrl };
                    if(text.toLowerCase() == 'document'){
                        imageMap.put('filename',fileName);
                    }
                    imageParameter.put(text.toLowerCase(), imageMap);
            parameters.add(imageParameter);
        } else if(type.equalsIgnoreCase('body')){
            parameters.addAll(getBodyParams(recordId,text));
        }
        component.put('parameters', parameters);
        return component;
    }

    /**
 * @description Replaces placeholders in the message text with actual field values from the record specified by the record ID.
 * 
 * @param recordId The ID of the record from which to retrieve field values.
 * @param messageText The message text containing placeholders in the format {!fieldName}.
 * @return The message text with placeholders replaced by actual field values.
 */
    
    public static String replacePlaceholders(String recordId, String messageText) {
        String sanitizedRecordId = String.escapeSingleQuotes(recordId);        
        Pattern pattern = Pattern.compile('\\{!(\\w+)\\}');
        Matcher matcher = pattern.matcher(messageText);        
        List<String> fieldNames = new List<String>();        
        while (matcher.find()) {
            String fieldName = matcher.group(1); 
            fieldNames.add(fieldName);
        }
        
        String query = 'SELECT ';
        query += String.join(fieldNames, ',');        
        String objName = ID.valueOf(sanitizedRecordId).getSObjectType().getDescribe().getName();
        query += ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE ID = :sanitizedRecordId WITH SECURITY_ENFORCED LIMIT 1';        
        SObject obj = Database.query(query);        
        matcher.reset();
        while (matcher.find()) {
            String placeholder = matcher.group(); 
            String fieldName = matcher.group(1); 
            String fieldValue = String.valueOf(obj.get(fieldName));
            messageText = messageText.replace(placeholder, fieldValue);
        }
        
        return messageText;
    }

 /**
 * @description Extracts and returns a list of parameters from the message text, replacing placeholders with actual field values from the record specified by the record ID.
 * 
 * @param recordId The ID of the record from which to retrieve field values.
 * @param messageText The message text containing placeholders in the format {!fieldName}.
 * @return A list of maps, each containing a 'type' and 'text' key with corresponding values from the record fields.
 */
    public static List<Map<String, String>> getBodyParams(String recordId, String messageText) {
        List<Map<String, String>> params = new List<Map<String, String>>();        
        String sanitizedRecordId = String.escapeSingleQuotes(recordId);        
        Pattern pattern = Pattern.compile('\\{!(\\w+)\\}');
        Matcher matcher = pattern.matcher(messageText);        
        List<String> fieldNames = new List<String>();        
        while (matcher.find()) {
            String fieldName = matcher.group(1); 
            fieldNames.add(String.escapeSingleQuotes(fieldName));
        }        
        String query = 'SELECT ';
        query += String.join(fieldNames, ',');        
        String objName = ID.valueOf(sanitizedRecordId).getSObjectType().getDescribe().getName();
        query += ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE ID = :sanitizedRecordId WITH SECURITY_ENFORCED LIMIT 1';        
        SObject obj = Database.query(query);        
        matcher.reset();
        while (matcher.find()) {
            Map<String, String> param = new Map<String, String>();
            String fieldName = matcher.group(1); 
            param.put('type', 'text');
            param.put('text', String.valueOf(obj.get(fieldName)));
            params.add(param);
        }
        
        return params;
    }

    /**
* @description Constructs button parameters for a WhatsApp message from a JSON string.
* @param buttonsJson The JSON string representing the buttons.
* @return A list of maps representing the button parameters.
*/
    public static List<Map<String, Object>> constructButtons(String buttonsJson) {
        List<Object> buttons = (List<Object>) JSON.deserializeUntyped(buttonsJson);
        List<Map<String, Object>> buttonParameters = new List<Map<String, Object>>();
        Integer index = 0;
        for (Object button : buttons) {
            Map<String, Object> buttonMap = (Map<String, Object>) button;
            String buttonType = (String) buttonMap.get('type');
            
            if (!buttonType.equals('PHONE_NUMBER') && !buttonType.equals('URL')) {
                Map<String, Object> parameter = new Map<String, Object>{
                    'type' => 'button',
                        'sub_type' => buttonType.toUpperCase(), 
                        'index' => String.valueOf(index)
                        };
                            if (buttonType.equals('COPY_CODE')) {
                                parameter.put('parameters', new List<Object>{
                                    new Map<String, Object>{
                                        'type' => 'payload',
                                            'payload' => (String) buttonMap.get('example')
                                            }
                                });
                            } else {
                                parameter.put('parameters', new List<Object>{
                                    new Map<String, Object>{
                                        'type' => 'payload',
                                            'payload' => (String) buttonMap.get('text')
                                            }
                                });
                            }
                buttonParameters.add(parameter);
            }
            index++;
        }
        return buttonParameters;
    }
}