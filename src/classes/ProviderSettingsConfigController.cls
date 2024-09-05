/**
 * @description The ProviderSettingController class is responsible for managing operations
 *              related to the connectsocial__Meta_Configuration__c and connectsocial__Twilio_Configuration__c custom setting.
 *              It provides methods to retrieve and upsert (create/update) records.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ProviderSettingsConfigController {
    /**
     * @description Retrieves all records from the connectsocial__ProviderSettings__c custom setting.
     * @return List<connectsocial__ProviderSettings__c> - A list of all provider settings records.
     * @throws AuraHandledException if there is an issue retrieving the records.
     */
    @AuraEnabled(cacheable=true)
    public static List<ProtectedSettingsWrapper> getProviderSettings() {
        List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'connectssocial_Admin' AND AssigneeId =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
        if(permissionSetAssignments == NULL || permissionSetAssignments.size() == 0){
            throw new AuraHandledException('User don\'t have the required permissions to access this feature.');
        }
        try {
            
            List<ProtectedSettingsWrapper> providerSettings = new List<ProtectedSettingsWrapper>();
            
            connectsocial__Meta_Configuration__c metaSetting = connectsocial__Meta_Configuration__c.getInstance();
            if (metaSetting != null) {
                ProtectedSettingsWrapper providerSettingMeta = new ProtectedSettingsWrapper();
                providerSettingMeta.id = metaSetting.Id;
                providerSettingMeta.name = metaSetting.Name;
                providerSettingMeta.applicationId = metaSetting.connectsocial__Application_Id__c;
                providerSettingMeta.channel = metaSetting.connectsocial__Channel__c;
                providerSettingMeta.phoneNumberId = metaSetting.connectsocial__Phone_Number_Id__c;
                providerSettingMeta.serviceProviderName = metaSetting.connectsocial__Service_Provider_Name__c;
                providerSettingMeta.whatsAppBusinessId = metaSetting.connectsocial__WhatsApp_Business_Id__c;
                providerSettingMeta.isActive = metaSetting.connectsocial__Active__c;
                
                providerSettings.add(providerSettingMeta);
            }
            connectsocial__TwilioConfiguration__c twilioSetting = connectsocial__TwilioConfiguration__c.getInstance();
            if (twilioSetting != null) {
                ProtectedSettingsWrapper providerSetting = new ProtectedSettingsWrapper();
                providerSetting.id = twilioSetting.Id;
                providerSetting.name = twilioSetting.Name;
                providerSetting.accountSID = twilioSetting.connectsocial__Account_SID__c;
                providerSetting.channel = twilioSetting.connectsocial__Channel__c;
                providerSetting.messagingServiceSID = twilioSetting.connectsocial__Messaging_Service_SID__c;
                providerSetting.serviceProviderName = twilioSetting.connectsocial__Service_Provider_Name__c;
                providerSetting.twilioPhoneNumber = twilioSetting.connectsocial__Twilio_Phone_Number__c;
                providerSetting.isActive = twilioSetting.connectsocial__Active__c;
                
                providerSettings.add(providerSetting);
            }
            
            return providerSettings;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to retrieve provider settings: ' + e.getMessage());
        }
    }
    
	/**
     * @description Inserts or updates a record in the connectsocial__ProviderSettings__c custom setting.
     *              If the Id field is populated, the existing record is updated; otherwise, a new record is created.
     * @param providerSettingStr The connectsocial__ProviderSettings__c record to upsert.
     * @throws AuraHandledException if there is an issue upserting the record.
     */
   @AuraEnabled
    public static void upsertProviderSetting(String providerSettingStr) {
        ProtectedSettingsWrapper providerSetting = (ProtectedSettingsWrapper) JSON.deserialize(providerSettingStr, ProtectedSettingsWrapper.class);
        List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id, PermissionSetId, PermissionSet.Name , AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE PermissionSet.Name = 'connectssocial_Admin' AND AssigneeId =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
        if(permissionSetAssignments == NULL || permissionSetAssignments.size() == 0){
            throw new AuraHandledException('User don\'t have the required permissions to access this feature.');
        }
        try {
            if (providerSetting.channel == 'WhatsApp' && providerSetting.serviceProviderName == 'Meta') {
                connectsocial__Meta_Configuration__c setting = connectsocial__Meta_Configuration__c.getOrgDefaults();
                setting.connectsocial__Application_Id__c = providerSetting.applicationId;
                setting.connectsocial__App_Secret_key__c = providerSetting.appSecretKey;
                setting.connectsocial__Auth_Token__c = providerSetting.authToken;
                setting.connectsocial__Phone_Number_Id__c = providerSetting.phoneNumberId;
                setting.connectsocial__WhatsApp_Business_Id__c = providerSetting.whatsAppBusinessId;
                setting.connectsocial__Service_Provider_Name__c = providerSetting.serviceProviderName;
                setting.connectsocial__Channel__c = providerSetting.channel;
                setting.connectsocial__Active__c = providerSetting.isActive;
                
                upsert setting;
            } else if (providerSetting.channel == 'SMS' && providerSetting.serviceProviderName == 'Twilio') {
                connectsocial__TwilioConfiguration__c setting = connectsocial__TwilioConfiguration__c.getOrgDefaults();
                setting.connectsocial__Account_SID__c = providerSetting.accountSID;
                setting.connectsocial__Auth_Token__c = providerSetting.authToken;
                setting.connectsocial__Channel__c = providerSetting.channel;
                setting.connectsocial__Service_Provider_Name__c = providerSetting.serviceProviderName;
                setting.connectsocial__Messaging_Service_SID__c = providerSetting.messagingServiceSID;
                setting.connectsocial__Twilio_Phone_Number__c = providerSetting.twilioPhoneNumber;
                setting.connectsocial__Active__c = providerSetting.isActive;
                
                upsert setting;
            } else {
                throw new AuraHandledException('Invalid channel specified.');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}