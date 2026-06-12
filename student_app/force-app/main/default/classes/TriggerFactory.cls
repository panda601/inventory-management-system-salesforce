public class TriggerFactory {
    /**
     * Instantiates and executes the appropriate TriggerHandler based on Type.
     */
    public static void createAndExecuteHandler(Type handlerType) {
        Object handlerObj = handlerType.newInstance();
        if (!(handlerObj instanceof TriggerHandler)) {
            throw new TriggerException('Handler must extend TriggerHandler virtual class');
        }
        TriggerHandler handler = (TriggerHandler) handlerObj;
        execute(handler);
    }

    private static void execute(TriggerHandler handler) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                handler.beforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            } else if (Trigger.isDelete) {
                handler.beforeDelete(Trigger.old, Trigger.oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                handler.afterInsert(Trigger.new, Trigger.newMap);
            } else if (Trigger.isUpdate) {
                handler.afterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            } else if (Trigger.isDelete) {
                handler.afterDelete(Trigger.old, Trigger.oldMap);
            } else if (Trigger.isUndelete) {
                handler.afterUndelete(Trigger.new, Trigger.newMap);
            }
        }
    }

    public class TriggerException extends Exception {}
}
