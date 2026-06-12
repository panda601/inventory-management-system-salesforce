public with sharing class StudentApplicationHandler extends TriggerHandler {
    public override void beforeInsert(List<SObject> newRecords) {
        handleRejectionStatus((List<Student_Application__c>) newRecords);
        preventDuplicates((List<Student_Application__c>) newRecords, null);
    }

    public override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> newMap, List<SObject> oldRecords, Map<Id, SObject> oldMap) {
        handleRejectionStatus((List<Student_Application__c>) newRecords);
        preventDuplicates((List<Student_Application__c>) newRecords, (Map<Id, Student_Application__c>) oldMap);
    }

    private void handleRejectionStatus(List<Student_Application__c> newApps) {
        for (Student_Application__c app : newApps) {
            if (app.Application_Status__c == 'Rejected') {
                app.Admission_Status__c = 'Rejected';
            }
        }
    }

    private void preventDuplicates(List<Student_Application__c> newApps, Map<Id, Student_Application__c> oldAppsMap) {
        Set<String> emails = new Set<String>();
        Set<String> firstNames = new Set<String>();
        Set<String> lastNames = new Set<String>();
        
        for (Student_Application__c app : newApps) {
            // Only check if it's new or if name/email changed
            if (oldAppsMap == null || 
                app.First_Name__c != oldAppsMap.get(app.Id).First_Name__c || 
                app.Last_Name__c != oldAppsMap.get(app.Id).Last_Name__c || 
                app.Email__c != oldAppsMap.get(app.Id).Email__c) {
                
                if (app.Email__c != null) emails.add(app.Email__c);
                if (app.First_Name__c != null) firstNames.add(app.First_Name__c);
                if (app.Last_Name__c != null) lastNames.add(app.Last_Name__c);
            }
        }

        if (emails.isEmpty()) {
            return;
        }

        // Query existing applications with matching First Name, Last Name, and Email
        List<Student_Application__c> existingApps = [
            SELECT Id, First_Name__c, Last_Name__c, Email__c 
            FROM Student_Application__c 
            WHERE Email__c IN :emails 
              AND First_Name__c IN :firstNames 
              AND Last_Name__c IN :lastNames
            WITH USER_MODE
        ];

        if (existingApps.isEmpty()) {
            return;
        }

        // Map them for faster lookups
        Map<String, Student_Application__c> matchMap = new Map<String, Student_Application__c>();
        for (Student_Application__c existing : existingApps) {
            String key = (existing.First_Name__c + '|' + existing.Last_Name__c + '|' + existing.Email__c).toLowerCase();
            matchMap.put(key, existing);
        }

        for (Student_Application__c app : newApps) {
            String key = (app.First_Name__c + '|' + app.Last_Name__c + '|' + app.Email__c).toLowerCase();
            if (matchMap.containsKey(key)) {
                Student_Application__c match = matchMap.get(key);
                if (oldAppsMap == null || match.Id != app.Id) {
                    app.addError('An application with the same name and email already exists.');
                }
            }
        }
    }

    public override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> newMap, List<SObject> oldRecords, Map<Id, SObject> oldMap) {
        createPaymentOnApproval((List<Student_Application__c>) newRecords, (Map<Id, Student_Application__c>) oldMap);
    }

    private void createPaymentOnApproval(List<Student_Application__c> newApps, Map<Id, Student_Application__c> oldApps) {
        List<Payment__c> paymentsToCreate = new List<Payment__c>();
        for (Student_Application__c app : newApps) {
            Student_Application__c oldApp = oldApps.get(app.Id);
            if (app.Application_Status__c == 'Approved' && oldApp.Application_Status__c != 'Approved') {
                Payment__c pay = new Payment__c();
                pay.Student_Application__c = app.Id;
                pay.Payment_Status__c = 'Pending';
                paymentsToCreate.add(pay);
            }
        }
        if (!paymentsToCreate.isEmpty()) {
            PaymentInserterSystemMode helper = new PaymentInserterSystemMode();
            helper.insertPayments(paymentsToCreate);
        }
    }

    private without sharing class PaymentInserterSystemMode {
        public void insertPayments(List<Payment__c> payments) {
            insert payments;
        }
    }
}
