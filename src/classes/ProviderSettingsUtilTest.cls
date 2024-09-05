/**
 * @description Test class for ProviderSettingsUtil.
 * 
 * This test class verifies the functionality of the ProviderSettingsUtil methods,
 * including the retrieval of provider settings records based on the channel.
 */
@isTest
public class ProviderSettingsUtilTest {
    /**
     * @description Creates test data for the connectsocial__ProviderSettings__c, connectsocial__TwilioConfiguration__c, and connectsocial__Meta_Configuration__c custom settings.
     *              This method inserts test records with different channels ("SMS" and "WhatsApp").
     *              The data setup is shared across all test methods.
     * @testSetup
     */
    @testSetup
    private static void createTestProviderSettings() {
        
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
     * @description Tests the retrieval of provider settings using the getSMSProviderSettings method.
     *              Verifies that the correct record is returned and that specific field values match expectations.
     * @isTest
     */
    @isTest
    static void testGetSMSProviderSettings() {
        Test.startTest();
        connectsocial__TwilioConfiguration__c settings = ProviderSettingUtil.getSMSProviderSettings('SMS');
        Test.stopTest();
        System.assertNotEquals(null, settings, 'Expected Twilio settings record to be retrieved.');
        System.assertEquals('SMS', settings.connectsocial__Channel__c, 'Expected Channel to match.');
    }

    /**
     * @description Tests exception handling in the getSMSProviderSettings method when no records are present for the specified channel.
     *              Expects the method to handle the absence of data gracefully.
     * @isTest
     */
    @isTest
    static void testGetSMSProviderSettingsException() {
        
        Test.startTest();
        
        try {
            ProviderSettingUtil.getSMSProviderSettings('NonExistentChannel');
            System.assert(false, 'Expected an AuraHandledException due to no provider settings found.');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Expected exception message to match.');
        }
        Test.stopTest();
    }

    /**
     * @description Tests the retrieval of provider settings using the getWhatsAppProviderSettings method.
     *              Verifies that the correct record is returned and that specific field values match expectations.
     * @isTest
     */
    @isTest
    static void testGetWhatsAppProviderSettings() {
        Test.startTest();
        connectsocial__Meta_Configuration__c settings = ProviderSettingUtil.getWhatsAppProviderSettings('WhatsApp');
        Test.stopTest();
        System.assertNotEquals(null, settings, 'Expected Meta settings record to be retrieved.');
        System.assertEquals('WhatsApp', settings.connectsocial__Channel__c, 'Expected Channel to match.');
    }

    /**
     * @description Tests exception handling in the getWhatsAppProviderSettings method when no records are present for the specified channel.
     *              Expects the method to handle the absence of data gracefully.
     * @isTest
     */
    @isTest
    static void testGetWhatsAppProviderSettingsException() {
        Test.startTest();
        try {
            ProviderSettingUtil.getWhatsAppProviderSettings('NonExistentChannel');
            System.assert(false, 'Expected an AuraHandledException due to no provider settings found.');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Expected exception message to match.');
        }
        Test.stopTest();
    }
}