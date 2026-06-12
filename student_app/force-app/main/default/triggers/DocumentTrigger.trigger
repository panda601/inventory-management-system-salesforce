trigger DocumentTrigger on Document__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    TriggerFactory.createAndExecuteHandler(DocumentTriggerHandler.class);
}
