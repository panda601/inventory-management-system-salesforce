@isTest
public class SecurityAuditTest {
    @isTest
    static void testSalesExecutiveSecurityBoundaries() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.salesUser) {
            System.assertEquals('Sales', InventoryController.getUserRole(), 'Sales Executive should resolve to Sales.');
            System.assertEquals(false, InventoryController.isInventoryManager(), 'Sales Executive must not resolve as manager.');
            System.assertEquals(false, InventoryController.canProcessReturn(), 'Sales Executive must not receive processing permission.');
            System.assertEquals(false, InventoryController.canApproveRefund(), 'Sales Executive must not receive refund approval permission.');
            System.assertEquals(false, InventoryDashboardController.canViewProfitMetrics(), 'Sales Executive must not receive profit-metric access.');

            System.assert(Schema.sObjectType.Product__c.isAccessible(), 'Sales Executive must read Product__c.');
            System.assert(Schema.sObjectType.Sales_Order__c.isCreateable(), 'Sales Executive must create Sales_Order__c.');
            System.assert(Schema.sObjectType.Return_Request__c.isCreateable(), 'Sales Executive must create Return_Request__c.');
            System.assertEquals(0, InventoryController.getSuppliers().size(), 'Sales Executive must not retrieve suppliers.');
            System.assertEquals(0, InventoryController.getRecentTransactions().size(), 'Sales Executive must not retrieve inventory transactions.');
            System.assertEquals(1, InventoryController.getReturnRequests().size(), 'Sales Executive should only see owned return requests.');

            try {
                InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Under Review', null);
                System.assert(false, 'Sales Executive should not be able to process returns.');
            } catch (AuraHandledException expectedException) {
                System.assert(String.isNotBlank(expectedException.getMessage()), 'Sales Executive processing must fail with an error.');
            }
        }
    }

    @isTest
    static void testInventoryManagerOperationalSecurity() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.managerUser) {
            System.assertEquals('Manager', InventoryController.getUserRole(), 'Inventory Manager should resolve to Manager.');
            System.assertEquals(true, InventoryController.isInventoryManager(), 'Inventory Manager must resolve as manager.');
            System.assertEquals(true, InventoryController.canProcessReturn(), 'Inventory Manager must receive processing permission.');
            System.assertEquals(false, InventoryController.canApproveRefund(), 'Inventory Manager must not receive refund approval permission.');
            System.assertEquals(false, InventoryDashboardController.canViewProfitMetrics(), 'Inventory Manager must not receive admin profit metrics.');

            System.assert(Schema.sObjectType.Product__c.isCreateable(), 'Inventory Manager must create Product__c.');
            System.assert(Schema.sObjectType.Supplier__c.isCreateable(), 'Inventory Manager must create Supplier__c.');
            System.assert(Schema.sObjectType.Purchase_Order__c.isCreateable(), 'Inventory Manager must create Purchase_Order__c.');
            System.assert(Schema.sObjectType.Inventory_Transaction__c.isCreateable(), 'Inventory Manager must create Inventory_Transaction__c.');
            System.assertEquals(1, InventoryController.getSuppliers().size(), 'Inventory Manager must retrieve suppliers.');
            System.assertEquals(1, InventoryController.getPurchaseOrders().size(), 'Inventory Manager must retrieve purchase orders.');
            System.assertEquals(1, InventoryController.getRecentTransactions().size(), 'Inventory Manager must retrieve inventory transactions.');
            System.assertEquals(2, InventoryController.getReturnRequests().size(), 'Inventory Manager must retrieve submitted returns.');
        }
    }

    @isTest
    static void testAdminCustomPermissionsAndFinancialVisibility() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.managerUser) {
            InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Under Review', null);
        }

        System.runAs(users.adminUser) {
            System.assertEquals('Admin', InventoryController.getUserRole(), 'Admin user should resolve to Admin.');
            System.assertEquals(true, InventoryController.canProcessReturn(), 'Admin must receive processing permission.');
            System.assertEquals(true, InventoryController.canApproveRefund(), 'Admin must receive refund approval permission.');
            System.assertEquals(true, InventoryDashboardController.canViewProfitMetrics(), 'Admin must receive profit-metric access.');

            InventoryDashboardController.AdminDashboardSummary summary = InventoryDashboardController.getAdminDashboardSummary();
            System.assertEquals(300, summary.revenue, 'Admin should see revenue metrics.');
            System.assertEquals(150, summary.procurementCost, 'Admin should see procurement metrics.');
            System.assertEquals(150, summary.profit, 'Admin should see profit metrics.');
        }
    }
}
