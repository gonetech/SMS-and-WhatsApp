/**
 * @class ProviderSettingUtil
 * @description Utility class for retrieving provider settings based on the channel.
 * @public
 */
public with sharing class ProviderSettingUtil {
    /**
     * @description Retrieves the provider settings for a given channel.
     * 
     * @param channel The channel for which the provider settings are to be retrieved (e.g., 'WhatsApp', 'SMS').
     * @return connectsocial__TwilioConfiguration__c The provider settings record matching the specified channel.
     * @throws AuraHandledException If no provider settings are found for the specified channel.
     */
    public static connectsocial__TwilioConfiguration__c getSMSProviderSettings(String channel) {
        
        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Name 
            FROM PermissionSetAssignment 
            WHERE (PermissionSet.Name = 'connectssocial_Admin' OR PermissionSet.Name = 'connectssocial_User')
            AND AssigneeId = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
        ];
        
        if (permissionSetAssignments.isEmpty() || permissionSetAssignments.size() == 0) {
            throw new AuraHandledException('You do not have the required permissions to access this feature.');
        }
        
        connectsocial__TwilioConfiguration__c setting = connectsocial__TwilioConfiguration__c.getInstance();
        
        if(setting != null && setting.connectsocial__Channel__c == channel) {
            return setting;
        }

        throw new AuraHandledException('No ProviderSettings found for channel: ' + channel);
    }
     /**
     * @description Retrieves the provider settings for a given channel.
     * 
     * @param channel The channel for which the provider settings are to be retrieved (e.g., 'WhatsApp', 'SMS').
     * @return connectsocial__TwilioConfiguration__c The provider settings record matching the specified channel.
     * @throws AuraHandledException If no provider settings are found for the specified channel.
     */
    public static connectsocial__Meta_Configuration__c getWhatsAppProviderSettings(String channel) {
        
        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Name 
            FROM PermissionSetAssignment 
            WHERE (PermissionSet.Name = 'connectssocial_Admin' OR PermissionSet.Name = 'connectssocial_User' OR PermissionSet.Name = 'connectssocial_Site_User')
            AND AssigneeId = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
        ];
        
        if (permissionSetAssignments.isEmpty() || permissionSetAssignments.size() == 0) {
            throw new AuraHandledException('You do not have the required permissions to access this feature.');
        }
        
        connectsocial__Meta_Configuration__c setting = connectsocial__Meta_Configuration__c.getInstance();
        
        if(setting != null && setting.connectsocial__Channel__c == channel) {
            return setting;
        }

        throw new AuraHandledException('No ProviderSettings found for channel: ' + channel);
    }

}