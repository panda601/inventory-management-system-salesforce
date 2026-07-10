public with sharing class IMS_GetSystemHealth {
    public class Request {
        @InvocableVariable(description='Dummy placeholder')
        public String placeholder;
    }

    public class SystemHealthSummary {
        @InvocableVariable public Integer activeProductsCount;
        @InvocableVariable public Integer totalSuppliersCount;
        @InvocableVariable public Integer pendingPOCount;
        @InvocableVariable public Integer pendingSOCount;
        @InvocableVariable public Integer pendingReturnCount;
        @InvocableVariable public String systemStatus;
    }

    @InvocableMethod(label='Get System Health' description='Retrieve a quick audit summary of the inventory system objects')
    public static List<SystemHealthSummary> execute(List<Request> requests) {
        List<SystemHealthSummary> responses = new List<SystemHealthSummary>();
        
        Integer products = [SELECT COUNT() FROM Product__c WHERE Status__c = 'Active' WITH SECURITY_ENFORCED];
        Integer suppliers = [SELECT COUNT() FROM Supplier__c WITH SECURITY_ENFORCED];
        
        Integer pendingPOs = 0;
        if (Schema.sObjectType.Purchase_Order__c.isAccessible()) {
            pendingPOs = [SELECT COUNT() FROM Purchase_Order__c WHERE Status__c IN ('Draft', 'Approved') WITH SECURITY_ENFORCED];
        }
        
        Integer pendingSOs = 0;
        if (Schema.sObjectType.Sales_Order__c.isAccessible()) {
            pendingSOs = [SELECT COUNT() FROM Sales_Order__c WHERE Status__c IN ('Draft', 'Confirmed') WITH SECURITY_ENFORCED];
        }
        
        Integer pendingReturns = 0;
        if (Schema.sObjectType.Return_Request__c.isAccessible()) {
            pendingReturns = [SELECT COUNT() FROM Return_Request__c WHERE Status__c IN ('Submitted', 'Under Review') WITH SECURITY_ENFORCED];
        }

        for (Request req : requests) {
            SystemHealthSummary s = new SystemHealthSummary();
            s.activeProductsCount = products;
            s.totalSuppliersCount = suppliers;
            s.pendingPOCount = pendingPOs;
            s.pendingSOCount = pendingSOs;
            s.pendingReturnCount = pendingReturns;
            s.systemStatus = 'HEALTHY';
            responses.add(s);
        }
        return responses;
    }
}
