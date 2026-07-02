public with sharing class ProductController {
    public class ProductCostPriceInfo {
        @AuraEnabled public Decimal costPrice { get; set; }
    }

    public class ProductDetailView {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String sku { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public Decimal costPrice { get; set; }
        @AuraEnabled public Decimal sellingPrice { get; set; }
        @AuraEnabled public Decimal stockOnHand { get; set; }
        @AuraEnabled public Decimal reorderPoint { get; set; }
        @AuraEnabled public Decimal availableQuantity { get; set; }
        @AuraEnabled public String status { get; set; }
    }

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
        if (productId == null) {
            return null;
        }

        List<Product__c> products = [
            SELECT Id, Name, Product_Name__c, SKU__c, Category__c, Price__c, Current_Stock__c, Minimum_Stock__c, Status__c
            FROM Product__c
            WHERE Id = :productId
            WITH USER_MODE
            LIMIT 1
        ];

        return products.isEmpty() ? null : products[0];
    }

    @AuraEnabled(cacheable=true)
    public static ProductDetailView getProduct(Id recordId) {
        if (recordId == null) {
            return null;
        }

        Product__c productRecord = getProductDetail(recordId);
        if (productRecord == null) {
            return null;
        }

        ProductDetailView result = new ProductDetailView();
        result.Id = productRecord.Id;
        result.Name = productRecord.Name;
        result.productName = productRecord.Product_Name__c;
        result.sku = productRecord.SKU__c;
        result.category = productRecord.Category__c;
        result.sellingPrice = productRecord.Price__c;
        result.stockOnHand = productRecord.Current_Stock__c;
        result.reorderPoint = productRecord.Minimum_Stock__c;
        result.availableQuantity = productRecord.Current_Stock__c;
        result.status = productRecord.Status__c;

        ProductCostPriceInfo costInfo = getProductCostPrice(recordId);
        result.costPrice = costInfo == null ? null : costInfo.costPrice;

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static ProductCostPriceInfo getProductCostPrice(Id productId) {
        ProductCostPriceInfo result = new ProductCostPriceInfo();
        result.costPrice = null;

        if (productId == null) {
            return result;
        }

        if (!hasOperationalInventoryAccess() || !Schema.sObjectType.Purchase_Order_Item__c.isAccessible()) {
            return result;
        }

        List<Purchase_Order_Item__c> items = [
            SELECT Unit_Price__c
            FROM Purchase_Order_Item__c
            WHERE Product__c = :productId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!items.isEmpty()) {
            result.costPrice = items[0].Unit_Price__c;
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Supplier__c getProductSupplier(Id productId) {
        if (productId == null) {
            return null;
        }

        if (!hasOperationalInventoryAccess() ||
            !Schema.sObjectType.Purchase_Order_Item__c.isAccessible() || 
            !Schema.sObjectType.Purchase_Order__c.isAccessible() || 
            !Schema.sObjectType.Supplier__c.isAccessible()) {
            return null;
        }
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
        if (productId == null) {
            return new List<Inventory_Transaction__c>();
        }

        if (!hasOperationalInventoryAccess() || !Schema.sObjectType.Inventory_Transaction__c.isAccessible()) {
            return new List<Inventory_Transaction__c>();
        }

        return [
            SELECT Id, Name, Product__c, Transaction_Type__c, Quantity__c, Transaction_Date__c, CreatedDate
            FROM Inventory_Transaction__c
            WHERE Product__c = :productId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Product__c getInventory(Id recordId) {
        if (recordId == null) {
            return null;
        }
        if (!Schema.sObjectType.Product__c.isAccessible()) {
            return null;
        }
        List<Product__c> products = [
            SELECT Id, Current_Stock__c, Minimum_Stock__c, Status__c
            FROM Product__c
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];
        return products.isEmpty() ? null : products[0];
    }

    @AuraEnabled(cacheable=true)
    public static Supplier__c getSupplier(Id recordId) {
        return getProductSupplier(recordId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Inventory_Transaction__c> getTransactions(Id recordId) {
        return getProductTransactions(recordId);
    }

    @TestVisible
    private static Boolean hasOperationalInventoryAccess() {
        Profile profileRecord = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        if (profileRecord.Name == 'System Administrator') {
            return true;
        }

        for (PermissionSetAssignment assignment : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            WITH USER_MODE
        ]) {
            if (assignment.PermissionSet.Name == 'Admin_Access' ||
                assignment.PermissionSet.Name == 'Inventory_Manager_Access') {
                return true;
            }
        }
        return false;
    }
}
