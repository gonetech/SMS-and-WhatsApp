/**
 * @description Test class for ProviderSettingsConfigController.
 * 
 * This test class verifies the functionality of the ProviderSettingsConfigController methods, 
 * including the retrieval and upserting of provider settings records. It ensures that the 
 * operations handle data correctly and handle exceptions appropriately.
 */
@isTest
public class ProviderSettingsConfigControllerTest {
    /**
     * @description Creates test data for the connectsocial__Meta_Configuration__c and connectsocial__TwilioConfiguration__c custom settings.
     *              This method inserts test records with different channels ("SMS" and "WhatsApp").
     *              The data setup is shared across all test methods.
     * @testSetup
     */
    @testSetup
    private static void createTestProviderSettings() {
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

        connectsocial__TwilioConfiguration__c twilioSetting = connectsocial__TwilioConfiguration__c.getOrgDefaults();
        twilioSetting.connectsocial__Account_SID__c = 'TestAccountSID';
        twilioSetting.connectsocial__Auth_Token__c = 'TestAuthToken';
        twilioSetting.connectsocial__Channel__c = 'SMS';
        twilioSetting.connectsocial__Messaging_Service_SID__c = 'TestMessagingServiceSID';
        twilioSetting.connectsocial__Service_Provider_Name__c = 'Twilio';
        twilioSetting.connectsocial__Twilio_Phone_Number__c = '1234567890';
        twilioSetting.connectsocial__Active__c = false;
        upsert twilioSetting;
    }
    
    /**
     * @description Tests the retrieval of all provider settings using the getProviderSettings method for WhatsApp channel.
     *              Verifies that the correct record is returned and that specific field values match expectations.
     * @isTest
     */
    @isTest
    static void testGetProviderSettings() {
        Test.startTest();
        List<ProtectedSettingsWrapper> settings = ProviderSettingsConfigController.getProviderSettings();
        Test.stopTest();
        System.assertEquals(2, settings.size(), 'Expected 2 provider settings record.');
    }

    /**
     * @description Tests the insertion of a new provider setting record using the upsertProviderSetting method.
     *              It verifies that the new record is inserted with the correct values for WhatsApp channel.
     * @isTest
     */
    @isTest
    static void testUpsertProviderSettingInsertWhatsApp() {
        ProtectedSettingsWrapper newSetting = new ProtectedSettingsWrapper();
        newSetting.name = 'NewMetaSetting'; 
        newSetting.applicationId = 'NewApplicationId';
        newSetting.appSecretKey = 'NewSecretKey';
        newSetting.authToken = 'NewAuthToken';
        newSetting.channel = 'WhatsApp';
        newSetting.isActive = true;
        newSetting.phoneNumberId = 'NewPhoneNumberId';
        newSetting.serviceProviderName = 'Meta';
        newSetting.whatsAppBusinessId = 'NewWhatsAppBusinessId';

        Test.startTest();
        String providerSettingStr = JSON.serialize(newSetting);
        ProviderSettingsConfigController.upsertProviderSetting(providerSettingStr);
        Test.stopTest();

        connectsocial__Meta_Configuration__c insertedSetting = connectsocial__Meta_Configuration__c.getOrgDefaults();
        System.assertNotEquals(null, insertedSetting, 'Expected the provider setting record to be inserted.');
        System.assertEquals('NewApplicationId', insertedSetting.connectsocial__Application_Id__c, 'Expected Application ID to match.');
    }

    /**
     * @description Tests the insertion of a new provider setting record using the upsertProviderSetting method.
     *              It verifies that the new record is inserted with the correct values for SMS channel.
     * @isTest
     */
    @isTest
    static void testUpsertProviderSettingInsertSMS() {
        ProtectedSettingsWrapper newSetting = new ProtectedSettingsWrapper();
        newSetting.name = 'NewTwilioSetting'; 
        newSetting.accountSID = 'NewAccountSID';
        newSetting.authToken = 'NewAuthToken';
        newSetting.channel = 'SMS';
        newSetting.isActive = true;
        newSetting.messagingServiceSID = 'NewMessagingServiceSID';
        newSetting.serviceProviderName = 'Twilio';
        newSetting.twilioPhoneNumber = 'TwilioPhone';

        Test.startTest();
        String providerSettingStr = JSON.serialize(newSetting);
        ProviderSettingsConfigController.upsertProviderSetting(providerSettingStr);
        Test.stopTest();

        connectsocial__TwilioConfiguration__c insertedSetting = connectsocial__TwilioConfiguration__c.getOrgDefaults();
        System.assertNotEquals(null, insertedSetting, 'Expected the provider setting record to be inserted.');
        System.assertEquals('NewAccountSID', insertedSetting.connectsocial__Account_SID__c, 'Expected Account SID to match.');
    }

    /**
     * @description Tests the update functionality of the upsertProviderSetting method.
     *              Updates an existing provider setting and verifies that the changes are correctly saved for WhatsApp channel.
     * @isTest
     */
    @isTest
    static void testUpsertProviderSettingUpdateWhatsApp() {
        connectsocial__Meta_Configuration__c existingSetting = connectsocial__Meta_Configuration__c.getOrgDefaults();
        ProtectedSettingsWrapper wrapper = new ProtectedSettingsWrapper();
        wrapper.id = existingSetting.Id;
        wrapper.name = existingSetting.Name;
        wrapper.applicationId = 'UpdatedApplicationId';
        wrapper.appSecretKey = 'UpdatedSecretKey';
        wrapper.authToken = 'UpdatedAuthToken';
        wrapper.channel = 'WhatsApp';
        wrapper.phoneNumberId = 'UpdatedPhoneNumberId';
        wrapper.serviceProviderName = 'Meta';
        wrapper.whatsAppBusinessId = 'UpdatedWhatsAppBusinessId';
        wrapper.isActive = true;

        Test.startTest();
        String providerSettingStr = JSON.serialize(wrapper);
        ProviderSettingsConfigController.upsertProviderSetting(providerSettingStr);
        Test.stopTest();

        connectsocial__Meta_Configuration__c updatedSetting = connectsocial__Meta_Configuration__c.getOrgDefaults();
        System.assertEquals('UpdatedAuthToken', updatedSetting.connectsocial__Auth_Token__c, 'Expected the Auth Token to be updated.');
    }

    /**
     * @description Tests the update functionality of the upsertProviderSetting method.
     *              Updates an existing provider setting and verifies that the changes are correctly saved for SMS channel.
     * @isTest
     */
    @isTest
    static void testUpsertProviderSettingUpdateSMS() {
        connectsocial__TwilioConfiguration__c existingSetting = connectsocial__TwilioConfiguration__c.getOrgDefaults();
        ProtectedSettingsWrapper wrapper = new ProtectedSettingsWrapper();
        wrapper.id = existingSetting.Id;
        wrapper.name = existingSetting.Name;
        wrapper.accountSID = 'UpdatedAccountSID';
        wrapper.authToken = 'UpdatedAuthToken';
        wrapper.channel = 'SMS';
        wrapper.messagingServiceSID = 'UpdatedMessagingServiceSID';
        wrapper.serviceProviderName = 'Twilio';
        wrapper.twilioPhoneNumber = 'TwilioPhone';
        wrapper.isActive = true;

        Test.startTest();
        String providerSettingStr = JSON.serialize(wrapper);
        ProviderSettingsConfigController.upsertProviderSetting(providerSettingStr);
        Test.stopTest();

        connectsocial__TwilioConfiguration__c updatedSetting = connectsocial__TwilioConfiguration__c.getOrgDefaults();
        System.assertEquals('UpdatedAuthToken', updatedSetting.connectsocial__Auth_Token__c, 'Expected the Auth Token to be updated.');
    }

    /**
     * @description Tests the exception handling of the upsertProviderSetting method when provided with invalid data.
     *              It attempts to insert a provider setting with missing required fields and expects an AuraHandledException.
     * @isTest
     */
    @isTest
    static void testUpsertProviderSettingException() {
        ProtectedSettingsWrapper invalidSetting = new ProtectedSettingsWrapper();
        try {
            Test.startTest();
            String providerSettingStr = JSON.serialize(invalidSetting);
            ProviderSettingsConfigController.upsertProviderSetting(providerSettingStr);
            Test.stopTest();
            System.assert(false, 'Expected an AuraHandledException due to missing required fields.');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Expected an exception message due to missing required fields.');
        }
    }
}