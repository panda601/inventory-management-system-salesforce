public with sharing class AdmissionHandler extends TriggerHandler {
    public override void beforeInsert(List<SObject> newRecords) {
        checkCourseCapacity((List<Admission__c>) newRecords, null);
    }

    public override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> newMap, List<SObject> oldRecords, Map<Id, SObject> oldMap) {
        checkCourseCapacity((List<Admission__c>) newRecords, (Map<Id, Admission__c>) oldMap);
    }

    private void checkCourseCapacity(List<Admission__c> newAdmissions, Map<Id, Admission__c> oldAdmissionsMap) {
        Set<Id> courseIds = new Set<Id>();
        for (Admission__c adm : newAdmissions) {
            if (adm.Course__c != null) {
                if (oldAdmissionsMap == null || adm.Course__c != oldAdmissionsMap.get(adm.Id).Course__c) {
                    courseIds.add(adm.Course__c);
                }
            }
        }

        if (courseIds.isEmpty()) {
            return;
        }

        // Query courses to get their Capacity__c
        Map<Id, Course__c> coursesMap = new Map<Id, Course__c>([
            SELECT Id, Name, Capacity__c 
            FROM Course__c 
            WHERE Id IN :courseIds
            WITH USER_MODE
        ]);

        // Aggregate current enrolled counts for these courses
        Map<Id, Integer> enrolledMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Course__c, COUNT(Id) enrolledCount 
            FROM Admission__c 
            WHERE Course__c IN :courseIds
            WITH USER_MODE
            GROUP BY Course__c
        ]) {
            enrolledMap.put((Id)ar.get('Course__c'), (Integer)ar.get('enrolledCount'));
        }

        // Keep track of counts of admissions currently being inserted/moved in this transaction
        Map<Id, Integer> pendingIncreaseMap = new Map<Id, Integer>();
        for (Admission__c adm : newAdmissions) {
            if (adm.Course__c != null) {
                if (oldAdmissionsMap == null || adm.Course__c != oldAdmissionsMap.get(adm.Id).Course__c) {
                    Integer count = pendingIncreaseMap.containsKey(adm.Course__c) ? pendingIncreaseMap.get(adm.Course__c) : 0;
                    pendingIncreaseMap.put(adm.Course__c, count + 1);
                }
            }
        }

        for (Admission__c adm : newAdmissions) {
            if (adm.Course__c != null && coursesMap.containsKey(adm.Course__c)) {
                Course__c course = coursesMap.get(adm.Course__c);
                Integer currentEnrolled = enrolledMap.containsKey(adm.Course__c) ? enrolledMap.get(adm.Course__c) : 0;
                Integer pendingNew = pendingIncreaseMap.get(adm.Course__c);
                Integer totalProposed = currentEnrolled + pendingNew;

                if (totalProposed > course.Capacity__c) {
                    adm.addError('Cannot complete admission. The selected course "' + course.Name + '" is already at maximum capacity (' + course.Capacity__c + ' seats).');
                }
            }
        }
    }
}
