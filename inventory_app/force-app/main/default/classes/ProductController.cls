public with sharing class ProductController {
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getProducts(String searchKey, String categoryFilter) {
        String key = String.isNotBlank(searchKey) ? '%' + searchKey + '%' : null;
        String cat = (String.isNotBlank(categoryFilter) && categoryFilter != 'All') ? categoryFilter : null;
        
        if (key != null && cat != null) {
            return [SELECT Id, Name, Product_Name__c, SKU__c, Category__c, Price__c, Current_Stock__c, Minimum_Stock__c, Status__c 
                    FROM Product__c 
                    WHERE Status__c = 'Active' 
                    AND (Name LIKE :key OR Product_Name__c LIKE :key OR SKU__c LIKE :key) 
                    AND Category__c = :cat 
                    WITH USER_MODE 
                    ORDER BY Name ASC];
        } else if (key != null) {
            return [SELECT Id, Name, Product_Name__c, SKU__c, Category__c, Price__c, Current_Stock__c, Minimum_Stock__c, Status__c 
                    FROM Product__c 
                    WHERE Status__c = 'Active' 
                    AND (Name LIKE :key OR Product_Name__c LIKE :key OR SKU__c LIKE :key) 
                    WITH USER_MODE 
                    ORDER BY Name ASC];
        } else if (cat != null) {
            return [SELECT Id, Name, Product_Name__c, SKU__c, Category__c, Price__c, Current_Stock__c, Minimum_Stock__c, Status__c 
                    FROM Product__c 
                    WHERE Status__c = 'Active' 
                    AND Category__c = :cat 
                    WITH USER_MODE 
                    ORDER BY Name ASC];
        } else {
            return [SELECT Id, Name, Product_Name__c, SKU__c, Category__c, Price__c, Current_Stock__c, Minimum_Stock__c, Status__c 
                    FROM Product__c 
                    WHERE Status__c = 'Active' 
                    WITH USER_MODE 
                    ORDER BY Name ASC];
        }
    }

    @AuraEnabled(cacheable=true)
    public static Product__c getProductDetail(Id productId) {
        return [SELECT Id, Name, Product_Name__c, SKU__c, Category__c, Price__c, Current_Stock__c, Minimum_Stock__c, Status__c 
                FROM Product__c 
                WHERE Id = :productId 
                WITH USER_MODE 
                LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static Supplier__c getProductSupplier(Id productId) {
        List<Purchase_Order_Item__c> items = [
            SELECT Purchase_Order__r.Supplier__r.Id,
                   Purchase_Order__r.Supplier__r.Name,
                   Purchase_Order__r.Supplier__r.Supplier_Name__c,
                   Purchase_Order__r.Supplier__r.Email__c,
                   Purchase_Order__r.Supplier__r.Phone__c,
                   Purchase_Order__r.Supplier__r.Address__c,
                   Purchase_Order__r.Supplier__r.Status__c
            FROM Purchase_Order_Item__c 
            WHERE Product__c = :productId 
            AND Purchase_Order__r.Supplier__c != null
            WITH USER_MODE 
            ORDER BY Purchase_Order__r.Order_Date__c DESC 
            LIMIT 1
        ];
        if (!items.isEmpty()) {
            return items[0].Purchase_Order__r.Supplier__r;
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<Inventory_Transaction__c> getProductTransactions(Id productId) {
        return [SELECT Id, Name, Transaction_Type__c, Quantity__c, Transaction_Date__c 
                FROM Inventory_Transaction__c 
                WHERE Product__c = :productId 
                WITH USER_MODE 
                ORDER BY Transaction_Date__c DESC 
                LIMIT 10];
    }
}
