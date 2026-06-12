public virtual class TriggerHandler {
    public virtual void beforeInsert(List<SObject> newRecords) {}
    public virtual void afterInsert(List<SObject> newRecords, Map<Id, SObject> newMap) {}
    public virtual void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> newMap, List<SObject> oldRecords, Map<Id, SObject> oldMap) {}
    public virtual void afterUpdate(List<SObject> newRecords, Map<Id, SObject> newMap, List<SObject> oldRecords, Map<Id, SObject> oldMap) {}
    public virtual void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldMap) {}
    public virtual void afterDelete(List<SObject> oldRecords, Map<Id, SObject> oldMap) {}
    public virtual void afterUndelete(List<SObject> newRecords, Map<Id, SObject> newMap) {}
}
