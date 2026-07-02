public with sharing class InventoryController {
    private static final String ROLE_ADMIN = 'Admin';
    private static final String ROLE_MANAGER = 'Manager';
    private static final String ROLE_SALES = 'Sales';

    @AuraEnabled(cacheable=true)
    public static Boolean isInventoryManager() {
        String roleName = resolveCurrentUserRole();
        return roleName == ROLE_ADMIN || roleName == ROLE_MANAGER;
    }

    @AuraEnabled
    public static String getUserRole() {
        return resolveCurrentUserRole();
    }

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMonitorData() {
        List<Product__c> products = [SELECT Id, Name, Product_Name__c, SKU__c, Current_Stock__c, Minimum_Stock__c, Status__c, Product_Image__c
                FROM Product__c
                WHERE Status__c = 'Active'
                WITH SECURITY_ENFORCED
                ORDER BY Current_Stock__c ASC];

        if (!products.isEmpty()) {
            List<Id> prodIds = new List<Id>();
            for (Product__c p : products) {
                prodIds.add(p.Id);
            }
            Map<Id, String> fileUrls = ProductController.getProductImageUrls(prodIds);
            for (Product__c p : products) {
                String fileUrl = fileUrls.get(p.Id);
                if (fileUrl != null) {
                    p.Product_Image__c = fileUrl;
                }
            }
        }
        return products;
    }

    @AuraEnabled(cacheable=true)
    public static List<Inventory_Transaction__c> getRecentTransactions() {
        if (resolveCurrentUserRole() == ROLE_SALES || !Schema.sObjectType.Inventory_Transaction__c.isAccessible()) {
            return new List<Inventory_Transaction__c>();
        }
        try {
            return [SELECT Id, Name, Product__r.Name, Product__r.Product_Name__c, Transaction_Type__c, Quantity__c, Transaction_Date__c
                    FROM Inventory_Transaction__c
                    WITH SECURITY_ENFORCED
                    ORDER BY Transaction_Date__c DESC, CreatedDate DESC];
        } catch (QueryException exceptionInstance) {
            return new List<Inventory_Transaction__c>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Purchase_Order__c> getPurchaseOrders() {
        if (!Schema.sObjectType.Purchase_Order__c.isAccessible()) {
            return new List<Purchase_Order__c>();
        }
        try {
            return [SELECT Id, Name, Supplier__r.Name, Supplier__r.Supplier_Name__c, Order_Date__c, Status__c, Total_Amount__c
                    FROM Purchase_Order__c
                    WITH SECURITY_ENFORCED
                    ORDER BY Order_Date__c DESC, Name DESC];
        } catch (QueryException exceptionInstance) {
            return new List<Purchase_Order__c>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Sales_Order__c> getRecentSalesOrders() {
        if (!Schema.sObjectType.Sales_Order__c.isAccessible()) {
            return new List<Sales_Order__c>();
        }
        return [SELECT Id, Name, Customer_Name__c, Order_Date__c, Status__c, Total_Amount__c
                FROM Sales_Order__c
                WITH SECURITY_ENFORCED
                ORDER BY Order_Date__c DESC, Name DESC];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getReportIds() {
        Map<String, Id> reportMap = new Map<String, Id>();
        for (Report r : [SELECT Id, DeveloperName FROM Report WHERE DeveloperName IN ('Sales_Order_Report', 'Purchase_Order_Report', 'Product_Inventory_Report', 'Low_Stock_Report', 'Inventory_Transaction_Report') WITH USER_MODE]) {
            reportMap.put(r.DeveloperName, r.Id);
        }
        return reportMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<Supplier__c> getSuppliers() {
        if (!Schema.sObjectType.Supplier__c.isAccessible()) {
            return new List<Supplier__c>();
        }
        try {
            return [SELECT Id, Name, Supplier_Name__c, Email__c, Status__c
                    FROM Supplier__c
                    WITH SECURITY_ENFORCED
                    ORDER BY Name ASC];
        } catch (QueryException exceptionInstance) {
            return new List<Supplier__c>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Sales_Order__c> getSalesOrders() {
        if (!Schema.sObjectType.Sales_Order__c.isAccessible()) {
            return new List<Sales_Order__c>();
        }
        return [SELECT Id, Name, Customer_Name__c, Order_Date__c, Status__c, Total_Amount__c
                FROM Sales_Order__c
                WITH SECURITY_ENFORCED
                ORDER BY Order_Date__c DESC, Name DESC];
    }

    @AuraEnabled(cacheable=true)
    public static List<Return_Request__c> getReturnRequests() {
        if (!Schema.sObjectType.Return_Request__c.isAccessible()) {
            return new List<Return_Request__c>();
        }
        String baseQuery =
            'SELECT Id, Name, OwnerId, CreatedById, Sales_Order__c, Sales_Order__r.Name, Customer_Name__c, ' +
            'Product__r.Product_Name__c, Quantity__c, Reason__c, Resolution_Type__c, Status__c, ' +
            'Requested_Date__c, Processed_Date__c, Processed_By__r.Name, Product__c ' +
            'FROM Return_Request__c';
        Id currentUserId = UserInfo.getUserId();

        if (resolveCurrentUserRole() == ROLE_SALES) {
            baseQuery += ' WHERE OwnerId = :currentUserId';
        }

        baseQuery += ' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC';
        return Database.query(baseQuery);
    }

    @AuraEnabled
    public static void processReturnRequest(Id requestId, String status) {
        processReturnRequestExtended(requestId, status, null);
    }

    @AuraEnabled
    public static void processReturnRequestExtended(Id requestId, String status, String resolutionType) {
        if (!Schema.sObjectType.Return_Request__c.isUpdateable()) {
            throw new AuraHandledException('You do not have access to update Return Requests');
        }
        if (!canProcessReturn()) {
            throw new AuraHandledException('You do not have permission to process return requests.');
        }
        if (status == 'Refunded' && !canApproveRefund()) {
            throw new AuraHandledException('You do not have permission to approve refunds.');
        }
        String userRole = resolveCurrentUserRole();
        Return_Request__c currentRequest = [
            SELECT Id, Name, Status__c, Resolution_Type__c, Product__c, Quantity__c
            FROM Return_Request__c
            WHERE Id = :requestId
            WITH SECURITY_ENFORCED
        ];

        validateReturnTransition(currentRequest, userRole, status);

        Return_Request__c req = new Return_Request__c(Id = requestId);
        req.Status__c = status;
        req.Processed_Date__c = System.today();
        req.Processed_By__c = UserInfo.getUserId();

        if (String.isNotBlank(resolutionType)) {
            req.Resolution_Type__c = resolutionType;
        } else if (status == 'Refunded') {
            req.Resolution_Type__c = 'Refund';
        } else if (status == 'Approved') {
            throw new AuraHandledException('Resolution type is required for admin approvals.');
        }

        update as user req;
    }

    @AuraEnabled
    public static Id quickReorder(Id productId, Decimal quantity) {
        if (!Schema.sObjectType.Purchase_Order__c.isCreateable() || 
            !Schema.sObjectType.Purchase_Order_Item__c.isCreateable()) {
            throw new AuraHandledException('You do not have permission to create Purchase Orders.');
        }

        Id supplierId = null;
        List<Purchase_Order_Item__c> items = [
            SELECT Purchase_Order__r.Supplier__c
            FROM Purchase_Order_Item__c
            WHERE Product__c = :productId
            AND Purchase_Order__r.Supplier__c != null
            WITH SECURITY_ENFORCED
            ORDER BY Purchase_Order__r.Order_Date__c DESC
            LIMIT 1
        ];
        if (!items.isEmpty()) {
            supplierId = items[0].Purchase_Order__r.Supplier__c;
        } else {
            List<Supplier__c> suppliers = [
                SELECT Id
                FROM Supplier__c
                WHERE Status__c = 'Active'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!suppliers.isEmpty()) {
                supplierId = suppliers[0].Id;
            }
        }

        if (supplierId == null) {
            throw new AuraHandledException('No active supplier found for this product.');
        }

        Decimal unitPrice = 10.00;
        List<Purchase_Order_Item__c> lastPoi = [
            SELECT Unit_Price__c
            FROM Purchase_Order_Item__c
            WHERE Product__c = :productId
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!lastPoi.isEmpty() && lastPoi[0].Unit_Price__c != null) {
            unitPrice = lastPoi[0].Unit_Price__c;
        } else {
            List<Product__c> prods = [
                SELECT Price__c
                FROM Product__c
                WHERE Id = :productId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!prods.isEmpty() && prods[0].Price__c != null) {
                unitPrice = prods[0].Price__c * 0.7;
            }
        }

        Purchase_Order__c po = new Purchase_Order__c(
            Supplier__c = supplierId,
            Order_Date__c = System.today(),
            Status__c = 'Draft'
        );
        insert as user po;

        Purchase_Order_Item__c poi = new Purchase_Order_Item__c(
            Purchase_Order__c = po.Id,
            Product__c = productId,
            Quantity__c = quantity,
            Unit_Price__c = unitPrice
        );
        insert as user poi;

        return po.Id;
    }

    public class ReorderPrefillInfo {
        @AuraEnabled public Id supplierId {get;set;}
        @AuraEnabled public Decimal unitPrice {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static ReorderPrefillInfo getReorderPrefillInfo(Id productId) {
        ReorderPrefillInfo info = new ReorderPrefillInfo();
        info.unitPrice = 10.00;
        
        List<Purchase_Order_Item__c> items = [
            SELECT Purchase_Order__r.Supplier__c, Unit_Price__c
            FROM Purchase_Order_Item__c
            WHERE Product__c = :productId
            AND Purchase_Order__r.Supplier__c != null
            WITH SECURITY_ENFORCED
            ORDER BY Purchase_Order__r.Order_Date__c DESC
            LIMIT 1
        ];
        if (!items.isEmpty()) {
            info.supplierId = items[0].Purchase_Order__r.Supplier__c;
            info.unitPrice = items[0].Unit_Price__c;
        } else {
            List<Supplier__c> suppliers = [
                SELECT Id FROM Supplier__c WHERE Status__c = 'Active' WITH SECURITY_ENFORCED LIMIT 1
            ];
            if (!suppliers.isEmpty()) {
                info.supplierId = suppliers[0].Id;
            }
            List<Product__c> prods = [
                SELECT Price__c FROM Product__c WHERE Id = :productId WITH SECURITY_ENFORCED LIMIT 1
            ];
            if (!prods.isEmpty() && prods[0].Price__c != null) {
                info.unitPrice = prods[0].Price__c * 0.7;
            }
        }
        return info;
    }

    @AuraEnabled
    public static Id createPurchaseOrderWithItem(Id supplierId, Id productId, Decimal quantity, Decimal unitPrice) {
        if (!Schema.sObjectType.Purchase_Order__c.isCreateable() || 
            !Schema.sObjectType.Purchase_Order_Item__c.isCreateable()) {
            throw new AuraHandledException('You do not have permission to create Purchase Orders.');
        }
        Purchase_Order__c po = new Purchase_Order__c(
            Supplier__c = supplierId,
            Order_Date__c = System.today(),
            Status__c = 'Draft'
        );
        insert as user po;

        Purchase_Order_Item__c poi = new Purchase_Order_Item__c(
            Purchase_Order__c = po.Id,
            Product__c = productId,
            Quantity__c = quantity,
            Unit_Price__c = unitPrice
        );
        insert as user poi;

        return po.Id;
    }

    private static String resolveCurrentUserRole() {
        Profile profileRecord = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        if (profileRecord.Name == 'System Administrator') {
            return ROLE_ADMIN;
        }

        Boolean isManager = false;
        Boolean isSales = false;
        for (PermissionSetAssignment assignment : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            WITH USER_MODE
        ]) {
            if (assignment.PermissionSet.Name == 'Admin_Access') {
                return ROLE_ADMIN;
            }
            if (assignment.PermissionSet.Name == 'Inventory_Manager_Access') {
                isManager = true;
            }
            if (assignment.PermissionSet.Name == 'Sales_Executive_Access') {
                isSales = true;
            }
        }

        if (isManager) {
            return ROLE_MANAGER;
        }
        if (isSales) {
            return ROLE_SALES;
        }
        return ROLE_SALES;
    }

    private static void validateReturnTransition(Return_Request__c requestRecord, String userRole, String targetStatus) {
        if (userRole == ROLE_MANAGER) {
            if (requestRecord.Status__c != 'Submitted') {
                throw new AuraHandledException('Inventory Managers can only process submitted return requests.');
            }
            if (!new Set<String>{ 'Under Review', 'Rejected', 'Submitted' }.contains(targetStatus)) {
                throw new AuraHandledException('Inventory Managers can approve, reject, or send back a return request.');
            }
            return;
        }

        if (userRole == ROLE_ADMIN) {
            if (requestRecord.Status__c != 'Under Review') {
                throw new AuraHandledException('Admin can only process return requests that are under review.');
            }
            if (!new Set<String>{ 'Approved', 'Refunded', 'Rejected', 'Closed' }.contains(targetStatus)) {
                throw new AuraHandledException('Admin can approve repair/replacement, refund, reject, or close a return request.');
            }
            return;
        }

        throw new AuraHandledException('You do not have permission to process return requests.');
    }

    @TestVisible
    private static Boolean canProcessReturn() {
        String roleName = resolveCurrentUserRole();
        return roleName == ROLE_ADMIN || roleName == ROLE_MANAGER;
    }

    @TestVisible
    private static Boolean canApproveRefund() {
        return resolveCurrentUserRole() == ROLE_ADMIN;
    }

    public class SupplierDetailWrapper {
        @AuraEnabled public Supplier__c supplier {get; set;}
        @AuraEnabled public List<Purchase_Order__c> purchaseOrders {get; set;}
        @AuraEnabled public List<Product__c> productsSupplied {get; set;}
    }

    @AuraEnabled(cacheable=true)
    public static SupplierDetailWrapper getSupplierDetail(Id recordId) {
        if (recordId == null) {
            return null;
        }
        
        SupplierDetailWrapper wrapper = new SupplierDetailWrapper();
        
        List<Supplier__c> suppliers = [
            SELECT Id, Name, Supplier_Name__c, Email__c, Phone__c, Address__c, Status__c, CreatedDate
            FROM Supplier__c
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];
        
        if (suppliers.isEmpty()) {
            return null;
        }
        wrapper.supplier = suppliers[0];
        
        wrapper.purchaseOrders = [
            SELECT Id, Name, Order_Date__c, Total_Amount__c, Status__c
            FROM Purchase_Order__c
            WHERE Supplier__c = :recordId
            WITH USER_MODE
            ORDER BY Order_Date__c DESC, CreatedDate DESC
        ];
        
        Set<Id> productIds = new Set<Id>();
        for (Purchase_Order_Item__c item : [
            SELECT Product__c
            FROM Purchase_Order_Item__c
            WHERE Purchase_Order__r.Supplier__c = :recordId
            WITH USER_MODE
        ]) {
            if (item.Product__c != null) {
                productIds.add(item.Product__c);
            }
        }
        
        if (!productIds.isEmpty()) {
            wrapper.productsSupplied = [
                SELECT Id, Product_Name__c, SKU__c, Category__c, Price__c, Product_Image__c
                FROM Product__c
                WHERE Id IN :productIds
                WITH USER_MODE
                ORDER BY Product_Name__c ASC
            ];

            Map<Id, String> fileUrls = ProductController.getProductImageUrls(new List<Id>(productIds));
            for (Product__c p : wrapper.productsSupplied) {
                String fileUrl = fileUrls.get(p.Id);
                if (fileUrl != null) {
                    p.Product_Image__c = fileUrl;
                }
            }
        } else {
            wrapper.productsSupplied = new List<Product__c>();
        }
        
        return wrapper;
    }
}
