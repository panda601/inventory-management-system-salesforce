@isTest
public class SecurityAuditTest {
    @isTest
    static void testSalesExecutiveAccess() {
        User salesExec = [SELECT Id FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];
        System.runAs(salesExec) {
            // Check read Product__c
            System.assert(Schema.sObjectType.Product__c.isAccessible(), 'Sales Executive must read Product__c');
            // Check create Sales_Order__c
            System.assert(Schema.sObjectType.Sales_Order__c.isCreateable(), 'Sales Executive must create Sales_Order__c');
            // Check cannot create Supplier__c
            System.assert(!Schema.sObjectType.Supplier__c.isCreateable(), 'Sales Executive must not create Supplier__c');
            // Check cannot create Purchase_Order__c
            System.assert(!Schema.sObjectType.Purchase_Order__c.isCreateable(), 'Sales Executive must not create Purchase_Order__c');
            // Check cannot create Inventory_Transaction__c
            System.assert(!Schema.sObjectType.Inventory_Transaction__c.isCreateable(), 'Sales Executive must not create Inventory_Transaction__c');
        }
    }

    @isTest
    static void testInventoryManagerAccess() {
        User invManager = [SELECT Id FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
        System.runAs(invManager) {
            // Check create Product__c
            System.assert(Schema.sObjectType.Product__c.isCreateable(), 'Inventory Manager must create Product__c');
            // Check create Supplier__c
            System.assert(Schema.sObjectType.Supplier__c.isCreateable(), 'Inventory Manager must create Supplier__c');
            // Check create Purchase_Order__c
            System.assert(Schema.sObjectType.Purchase_Order__c.isCreateable(), 'Inventory Manager must create Purchase_Order__c');
            // Check create Inventory_Transaction__c
            System.assert(Schema.sObjectType.Inventory_Transaction__c.isCreateable(), 'Inventory Manager must create Inventory_Transaction__c');
        }
    }

    @isTest
    static void testRecordVisibility() {
        // Fetch users
        User adminUser = [SELECT Id FROM User WHERE Username = '723145roy.6036123142ec@agentforce.com' LIMIT 1];
        User invManager = [SELECT Id FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
        User salesExec = [SELECT Id FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];

        // Seed data as admin
        Product__c prod = new Product__c(
            Name = 'Test Product',
            Product_Name__c = 'Test Product',
            SKU__c = 'TEST-SKU-1',
            Category__c = 'Electronics',
            Price__c = 100.00,
            Current_Stock__c = 10,
            Minimum_Stock__c = 2,
            Status__c = 'Active',
            OwnerId = adminUser.Id
        );
        insert prod;

        Supplier__c supp = new Supplier__c(
            Name = 'Test Supplier',
            Supplier_Name__c = 'Test Supplier',
            Status__c = 'Active',
            OwnerId = adminUser.Id
        );
        insert supp;

        Purchase_Order__c po = new Purchase_Order__c(
            Supplier__c = supp.Id,
            Order_Date__c = System.today(),
            Status__c = 'Draft',
            OwnerId = adminUser.Id
        );
        insert po;

        Inventory_Transaction__c txn = new Inventory_Transaction__c(
            Product__c = prod.Id,
            Transaction_Type__c = 'Adjustment',
            Quantity__c = 5,
            Transaction_Date__c = System.now(),
            OwnerId = adminUser.Id
        );
        insert txn;

        Sales_Order__c salesExecSO = new Sales_Order__c(
            Customer_Name__c = 'Sales Exec Customer',
            Order_Date__c = System.today(),
            Status__c = 'Draft',
            OwnerId = salesExec.Id
        );
        insert salesExecSO;

        Sales_Order__c adminSO = new Sales_Order__c(
            Customer_Name__c = 'Admin Customer',
            Order_Date__c = System.today(),
            Status__c = 'Draft',
            OwnerId = adminUser.Id
        );
        insert adminSO;

        // Test as Inventory Manager
        System.runAs(invManager) {
            // Can see Product
            List<Product__c> prods = [SELECT Id FROM Product__c WHERE Id = :prod.Id];
            System.assertEquals(1, prods.size(), 'Inventory Manager must see Product');

            // Can see Supplier (via sharing rule)
            List<Supplier__c> supps = [SELECT Id FROM Supplier__c WHERE Id = :supp.Id];
            System.assertEquals(1, supps.size(), 'Inventory Manager must see Supplier');

            // Can see Purchase Order (via sharing rule)
            List<Purchase_Order__c> pos = [SELECT Id FROM Purchase_Order__c WHERE Id = :po.Id];
            System.assertEquals(1, pos.size(), 'Inventory Manager must see Purchase Order');

            // Can see Inventory Transaction (via sharing rule)
            List<Inventory_Transaction__c> txns = [SELECT Id FROM Inventory_Transaction__c WHERE Id = :txn.Id];
            System.assertEquals(1, txns.size(), 'Inventory Manager must see Inventory Transaction');
        }

        // Test as Sales Executive
        System.runAs(salesExec) {
            // Can see Product
            List<Product__c> prods = [SELECT Id FROM Product__c WHERE Id = :prod.Id];
            System.assertEquals(1, prods.size(), 'Sales Executive must see Product');

            // Can see own Sales Order
            List<Sales_Order__c> ownSOs = [SELECT Id FROM Sales_Order__c WHERE Id = :salesExecSO.Id];
            System.assertEquals(1, ownSOs.size(), 'Sales Executive must see own Sales Order');

            // Cannot see admin's Sales Order
            List<Sales_Order__c> otherSOs = [SELECT Id FROM Sales_Order__c WHERE Id = :adminSO.Id];
            System.assertEquals(0, otherSOs.size(), 'Sales Executive must not see other Sales Orders');

            // Cannot see Supplier, PO, or Inventory Transaction (via query exclusion)
            List<Supplier__c> supps = [SELECT Id FROM Supplier__c WHERE Id = :supp.Id];
            System.assertEquals(0, supps.size(), 'Sales Executive must not see Supplier records');

            List<Purchase_Order__c> pos = [SELECT Id FROM Purchase_Order__c WHERE Id = :po.Id];
            System.assertEquals(0, pos.size(), 'Sales Executive must not see Purchase Order records');

            List<Inventory_Transaction__c> txns = [SELECT Id FROM Inventory_Transaction__c WHERE Id = :txn.Id];
            System.assertEquals(0, txns.size(), 'Sales Executive must not see Inventory Transaction records');
        }
    }
}
