/**
 * @description Common Util
 */
public with sharing class CommonUtil {
/**
 * @description hasFLS
 *@param record
 *@return Boolean
 */
    public static Boolean hasFLS(sObject record) {
        Map<String, Object> rec = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(record));
        String sobjectName = String.valueOf(record.getsobjecttype());
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> mapSchema = targetType.getDescribe().fields.getMap();
        Boolean isCreateAccess = true;
        for(String fieldToCheck : rec.keySet()) {
            if(fieldToCheck <> 'attributes' && mapSchema.get(fieldToCheck) != null && mapSchema.get(fieldToCheck).getDescribe().isCustom() && (!mapSchema.get(fieldToCheck).getDescribe().isCreateable() && (!mapSchema.get(fieldToCheck).getDescribe().isUpdateable()))) {
               isCreateAccess = false;
                break;
            }
        }
        return isCreateAccess;
    }
}