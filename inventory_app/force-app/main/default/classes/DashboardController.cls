public with sharing class DashboardController {
    
    public class InventorySummary {
        @AuraEnabled public Integer totalProducts {get;set;}
        @AuraEnabled public Decimal availableStock {get;set;}
        @AuraEnabled public Integer lowStock {get;set;}
        @AuraEnabled public Integer outOfStock {get;set;}
        @AuraEnabled public Integer pendingPurchaseOrders {get;set;}
        @AuraEnabled public Integer pendingSalesOrders {get;set;}
    }

    public class SalesSummary {
        @AuraEnabled public Integer totalOrders {get;set;}
        @AuraEnabled public Decimal totalRevenue {get;set;}
        @AuraEnabled public List<ProductSalesBreakdown> productSales {get;set;}
    }

    public class ProductSalesBreakdown {
        @AuraEnabled public String productName {get;set;}
        @AuraEnabled public Decimal quantitySold {get;set;}
        @AuraEnabled public Decimal totalSales {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static InventorySummary getInventorySummary() {
        InventorySummary summary = new InventorySummary();
        
        summary.totalProducts = [SELECT COUNT() FROM Product__c WHERE Status__c = 'Active' WITH USER_MODE];
        
        List<AggregateResult> stockSum = [SELECT SUM(Current_Stock__c) totalStock FROM Product__c WHERE Status__c = 'Active' WITH USER_MODE];
        summary.availableStock = stockSum[0].get('totalStock') != null ? (Decimal)stockSum[0].get('totalStock') : 0;
        
        Integer lowCount = 0;
        for (Product__c prod : [SELECT Current_Stock__c, Minimum_Stock__c FROM Product__c WHERE Status__c = 'Active' WITH USER_MODE]) {
            if (prod.Current_Stock__c <= prod.Minimum_Stock__c && prod.Current_Stock__c > 0) {
                lowCount++;
            }
        }
        summary.lowStock = lowCount;
        
        summary.outOfStock = [SELECT COUNT() FROM Product__c WHERE Status__c = 'Active' AND Current_Stock__c = 0 WITH USER_MODE];
        
        if (Schema.sObjectType.Purchase_Order__c.isAccessible()) {
            summary.pendingPurchaseOrders = [SELECT COUNT() FROM Purchase_Order__c WHERE Status__c IN ('Draft', 'Approved') WITH USER_MODE];
        } else {
            summary.pendingPurchaseOrders = 0;
        }
        
        if (Schema.sObjectType.Sales_Order__c.isAccessible()) {
            summary.pendingSalesOrders = [SELECT COUNT() FROM Sales_Order__c WHERE Status__c IN ('Draft', 'Confirmed') WITH USER_MODE];
        } else {
            summary.pendingSalesOrders = 0;
        }
        
        return summary;
    }

    @AuraEnabled(cacheable=true)
    public static SalesSummary getSalesSummary() {
        SalesSummary summary = new SalesSummary();
        
        if (Schema.sObjectType.Sales_Order__c.isAccessible()) {
            summary.totalOrders = [SELECT COUNT() FROM Sales_Order__c WITH USER_MODE];
            List<AggregateResult> revSum = [SELECT SUM(Total_Amount__c) totalRev FROM Sales_Order__c WHERE Status__c IN ('Confirmed', 'Delivered') WITH USER_MODE];
            summary.totalRevenue = revSum[0].get('totalRev') != null ? (Decimal)revSum[0].get('totalRev') : 0;
        } else {
            summary.totalOrders = 0;
            summary.totalRevenue = 0;
        }
        
        summary.productSales = new List<ProductSalesBreakdown>();
        
        if (Schema.sObjectType.Sales_Order_Item__c.isAccessible()) {
            List<AggregateResult> itemGroup = [
                SELECT Product__r.Product_Name__c prodName, 
                       SUM(Quantity__c) totalQty, 
                       SUM(Line_Total__c) totalAmount
                FROM Sales_Order_Item__c
                WHERE Sales_Order__r.Status__c IN ('Confirmed', 'Delivered')
                WITH USER_MODE
                GROUP BY Product__r.Product_Name__c
                ORDER BY SUM(Line_Total__c) DESC
            ];
            
            for (AggregateResult ar : itemGroup) {
                ProductSalesBreakdown item = new ProductSalesBreakdown();
                item.productName = ar.get('prodName') != null ? (String)ar.get('prodName') : 'Unknown';
                item.quantitySold = ar.get('totalQty') != null ? (Decimal)ar.get('totalQty') : 0;
                item.totalSales = ar.get('totalAmount') != null ? (Decimal)ar.get('totalAmount') : 0;
                summary.productSales.add(item);
            }
        }
        
        return summary;
    }
}
