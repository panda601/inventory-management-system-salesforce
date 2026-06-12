public with sharing class InventoryController {
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMonitorData() {
        return [SELECT Id, Name, Product_Name__c, SKU__c, Current_Stock__c, Minimum_Stock__c, Status__c 
                FROM Product__c 
                WHERE Status__c = 'Active' 
                WITH USER_MODE 
                ORDER BY Current_Stock__c ASC];
    }

    @AuraEnabled(cacheable=true)
    public static List<Inventory_Transaction__c> getRecentTransactions() {
        return [SELECT Id, Name, Product__r.Name, Product__r.Product_Name__c, Transaction_Type__c, Quantity__c, Transaction_Date__c 
                FROM Inventory_Transaction__c 
                WITH USER_MODE 
                ORDER BY Transaction_Date__c DESC 
                LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static List<Purchase_Order__c> getPurchaseOrders() {
        return [SELECT Id, Name, Supplier__r.Name, Supplier__r.Supplier_Name__c, Order_Date__c, Status__c, Total_Amount__c 
                FROM Purchase_Order__c 
                WITH USER_MODE 
                ORDER BY Order_Date__c DESC, Name DESC];
    }
}
