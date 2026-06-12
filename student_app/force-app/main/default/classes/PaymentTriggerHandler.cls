public with sharing class PaymentTriggerHandler extends TriggerHandler {
    public override void beforeInsert(List<SObject> newRecords) {
        setPaymentOwner((List<Payment__c>) newRecords);
    }

    public override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> newMap, List<SObject> oldRecords, Map<Id, SObject> oldMap) {
        setPaymentOwner((List<Payment__c>) newRecords);
    }

    private void setPaymentOwner(List<Payment__c> payments) {
        Set<Id> appIds = new Set<Id>();
        for (Payment__c pay : payments) {
            if (pay.Student_Application__c != null) {
                appIds.add(pay.Student_Application__c);
            }
        }

        if (appIds.isEmpty()) {
            return;
        }

        // Query the parent application's OwnerId and course fees
        Map<Id, Student_Application__c> appsMap = new Map<Id, Student_Application__c>([
            SELECT Id, OwnerId, Applied_Course__c, Applied_Course__r.Fees__c 
            FROM Student_Application__c 
            WHERE Id IN :appIds
            WITH SYSTEM_MODE
        ]);

        for (Payment__c pay : payments) {
            if (pay.Student_Application__c != null && appsMap.containsKey(pay.Student_Application__c)) {
                Student_Application__c app = appsMap.get(pay.Student_Application__c);
                pay.OwnerId = app.OwnerId;
                
                // Auto-populate Amount from Course Fee if not specified
                if (pay.Amount__c == null && app.Applied_Course__c != null) {
                    pay.Amount__c = app.Applied_Course__r.Fees__c;
                }
            }
        }
    }
}
