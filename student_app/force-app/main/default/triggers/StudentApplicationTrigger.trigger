trigger StudentApplicationTrigger on Student_Application__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    TriggerFactory.createAndExecuteHandler(StudentApplicationHandler.class);
}
