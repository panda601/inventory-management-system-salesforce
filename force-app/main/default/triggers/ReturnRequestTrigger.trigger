trigger ReturnRequestTrigger on Return_Request__c (before insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ReturnRequestTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        ReturnRequestTriggerHandler.handleAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
