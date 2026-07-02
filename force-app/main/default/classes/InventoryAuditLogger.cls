public with sharing class InventoryAuditLogger {
    public static void log(String action, Id recordId, String oldValue, String newValue) {
        Inventory_Audit_Log__c auditLog = new Inventory_Audit_Log__c(
            Action__c = action,
            Record_Id__c = recordId,
            Old_Value__c = oldValue,
            New_Value__c = newValue,
            User__c = UserInfo.getUserId(),
            Log_Date__c = System.now()
        );
        try {
            insert as user auditLog;
        } catch (Exception ex) {
            System.debug('Failed to write inventory audit log: ' + ex.getMessage());
        }
    }
}
