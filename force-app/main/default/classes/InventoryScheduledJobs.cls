public with sharing class InventoryScheduledJobs implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new InventoryScheduledJobs(), 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Status__c, SLA_Due_Date__c, Is_Escalated__c ' +
            'FROM Return_Request__c ' +
            'WHERE Status__c NOT IN (\'Closed\', \'Rejected\', \'Refunded\')'
        );
    }

    public void execute(Database.BatchableContext bc, List<Return_Request__c> scope) {
        List<Return_Request__c> returnsToUpdate = new List<Return_Request__c>();
        for (Return_Request__c req : scope) {
            if (req.SLA_Due_Date__c != null && System.now() > req.SLA_Due_Date__c && !req.Is_Escalated__c) {
                req.Is_Escalated__c = true;
                returnsToUpdate.add(req);
            }
        }
        if (!returnsToUpdate.isEmpty()) {
            update as user returnsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        runStockRecalculations();
    }

    private void runStockRecalculations() {
        List<Product__c> lowStockProducts = [
            SELECT Id, Name, Current_Stock__c, Minimum_Stock__c, Price__c 
            FROM Product__c 
            WHERE Status__c = 'Active'
            WITH SECURITY_ENFORCED
        ];
        
        for (Product__c prod : lowStockProducts) {
            if (prod.Current_Stock__c <= prod.Minimum_Stock__c) {
                try {
                    Decimal quantity = prod.Minimum_Stock__c * 2; 
                    InventoryController.quickReorder(prod.Id, quantity);
                } catch (Exception ex) {
                    System.debug('Auto-reorder failed for ' + prod.Name + ': ' + ex.getMessage());
                }
            }
        }
    }
}
