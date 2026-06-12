public with sharing class Utility {
    /**
     * Checks CRUD access for a given object and action type.
     */
    public static Boolean checkObjectAccess(String sobjectName, String accessType) {
        SObjectType targetType = Schema.getGlobalDescribe().get(sobjectName);
        if (targetType == null) {
            return false;
        }
        DescribeSObjectResult describeResult = targetType.getDescribe();
        if (accessType.equalsIgnoreCase('create')) {
            return describeResult.isCreateable();
        } else if (accessType.equalsIgnoreCase('read')) {
            return describeResult.isAccessible();
        } else if (accessType.equalsIgnoreCase('edit')) {
            return describeResult.isUpdateable();
        } else if (accessType.equalsIgnoreCase('delete')) {
            return describeResult.isDeletable();
        }
        return false;
    }

    /**
     * Checks FLS access for a specific field on an object.
     */
    public static Boolean checkFieldAccess(String sobjectName, String fieldName, String accessType) {
        SObjectType targetType = Schema.getGlobalDescribe().get(sobjectName);
        if (targetType == null) {
            return false;
        }
        Map<String, SObjectField> fieldsMap = targetType.getDescribe().fields.getMap();
        SObjectField field = fieldsMap.get(fieldName);
        if (field == null) {
            return false;
        }
        DescribeFieldResult describeResult = field.getDescribe();
        if (accessType.equalsIgnoreCase('read')) {
            return describeResult.isAccessible();
        } else if (accessType.equalsIgnoreCase('edit')) {
            return describeResult.isUpdateable();
        }
        return false;
    }
}
