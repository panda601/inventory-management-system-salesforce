public without sharing class DocumentTriggerHandler extends TriggerHandler {
    public override void afterInsert(List<SObject> newRecords, Map<Id, SObject> newMap) {
        syncParentApplicationStatuses((List<Document__c>) newRecords, null);
    }

    public override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> newMap, List<SObject> oldRecords, Map<Id, SObject> oldMap) {
        syncParentApplicationStatuses((List<Document__c>) newRecords, (Map<Id, Document__c>) oldMap);
    }

    private void syncParentApplicationStatuses(List<Document__c> newDocs, Map<Id, Document__c> oldDocsMap) {
        Set<Id> parentAppIds = new Set<Id>();
        for (Document__c doc : newDocs) {
            if (doc.Student_Application__c != null) {
                parentAppIds.add(doc.Student_Application__c);
            }

            if (oldDocsMap != null) {
                Document__c oldDoc = oldDocsMap.get(doc.Id);
                if (oldDoc != null && oldDoc.Student_Application__c != null) {
                    parentAppIds.add(oldDoc.Student_Application__c);
                }
            }
        }

        if (parentAppIds.isEmpty()) {
            return;
        }

        Map<Id, Student_Application__c> currentApps = new Map<Id, Student_Application__c>([
            SELECT Id, Document_Status__c, Admission_Status__c
            FROM Student_Application__c
            WHERE Id IN :parentAppIds
        ]);

        Map<Id, Integer> totalByApp = new Map<Id, Integer>();
        Map<Id, Integer> verifiedByApp = new Map<Id, Integer>();
        Map<Id, Integer> rejectedByApp = new Map<Id, Integer>();

        for (Document__c doc : [
            SELECT Id, Student_Application__c, Verification_Status__c
            FROM Document__c
            WHERE Student_Application__c IN :parentAppIds
        ]) {
            Id appId = doc.Student_Application__c;
            totalByApp.put(appId, (totalByApp.containsKey(appId) ? totalByApp.get(appId) : 0) + 1);

            if (doc.Verification_Status__c == 'Verified') {
                verifiedByApp.put(appId, (verifiedByApp.containsKey(appId) ? verifiedByApp.get(appId) : 0) + 1);
            } else if (doc.Verification_Status__c == 'Rejected') {
                rejectedByApp.put(appId, (rejectedByApp.containsKey(appId) ? rejectedByApp.get(appId) : 0) + 1);
            }
        }

        List<Student_Application__c> appsToUpdate = new List<Student_Application__c>();
        for (Id appId : parentAppIds) {
            Student_Application__c currentApp = currentApps.get(appId);
            if (currentApp == null) {
                continue;
            }

            Integer totalDocs = totalByApp.containsKey(appId) ? totalByApp.get(appId) : 0;
            Integer verifiedDocs = verifiedByApp.containsKey(appId) ? verifiedByApp.get(appId) : 0;
            Integer rejectedDocs = rejectedByApp.containsKey(appId) ? rejectedByApp.get(appId) : 0;

            String nextDocumentStatus = 'Pending';
            String nextAdmissionStatus = currentApp.Admission_Status__c;

            if (rejectedDocs > 0) {
                nextDocumentStatus = 'Rejected';
                nextAdmissionStatus = 'Rejected';
            } else if (totalDocs > 0 && verifiedDocs == totalDocs) {
                nextDocumentStatus = 'Verified';
            } else if (totalDocs > 0) {
                nextDocumentStatus = 'Uploaded';
            }

            if (currentApp.Document_Status__c != nextDocumentStatus || currentApp.Admission_Status__c != nextAdmissionStatus) {
                appsToUpdate.add(new Student_Application__c(
                    Id = appId,
                    Document_Status__c = nextDocumentStatus,
                    Admission_Status__c = nextAdmissionStatus
                ));
            }
        }

        if (!appsToUpdate.isEmpty()) {
            update appsToUpdate;
        }
    }
}
