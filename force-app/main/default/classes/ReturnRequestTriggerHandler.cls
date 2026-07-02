public with sharing class ReturnRequestTriggerHandler {
    public static void handleBeforeInsert(List<Return_Request__c> newRecords) {
        for (Return_Request__c req : newRecords) {
            // Set standard 7-day SLA and 5-day expected resolution
            if (req.SLA_Due_Date__c == null) {
                req.SLA_Due_Date__c = System.now().addDays(7);
            }
            if (req.Expected_Resolution_Date__c == null) {
                req.Expected_Resolution_Date__c = System.today().addDays(5);
            }
        }
    }

    public static void handleAfterUpdate(Map<Id, Return_Request__c> oldMap, Map<Id, Return_Request__c> newMap) {
        for (Id reqId : newMap.keySet()) {
            Return_Request__c oldReq = oldMap.get(reqId);
            Return_Request__c newReq = newMap.get(reqId);

            if (oldReq.Status__c != newReq.Status__c) {
                InventoryAuditLogger.log(
                    'Return Request Status Change',
                    reqId,
                    'Status: ' + oldReq.Status__c,
                    'Status: ' + newReq.Status__c
                );
            }

            if (oldReq.Is_Escalated__c != newReq.Is_Escalated__c) {
                InventoryAuditLogger.log(
                    'Return Request Escalation Change',
                    reqId,
                    'Is Escalated: ' + oldReq.Is_Escalated__c,
                    'Is Escalated: ' + newReq.Is_Escalated__c
                );
            }
        }
    }
}
