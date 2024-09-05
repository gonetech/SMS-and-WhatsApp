/**
 * @description Wrapper class for the connectsocial__ProviderSettings__c custom setting.
 *              This class is used to transfer data between the client and server securely,
 *              excluding any sensitive information that shouldn't be exposed directly.
 *              The fields correspond to those in the connectsocial__ProviderSettings__c object.
 */
public class ProtectedSettingsWrapper {
    
	@AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String appSecretKey;
    @AuraEnabled
    public String accountSID;
    @AuraEnabled
    public String applicationId;
    @AuraEnabled
    public String authToken;
    @AuraEnabled
    public String channel;
    @AuraEnabled
    public String messagingServiceSID;
    @AuraEnabled
    public String phoneNumberId;
    @AuraEnabled
    public String serviceProviderName;
    @AuraEnabled
    public String twilioPhoneNumber;
    @AuraEnabled
    public String whatsappBusinessId;
    @AuraEnabled
    public Boolean isActive;
}