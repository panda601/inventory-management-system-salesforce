@isTest
public class InventoryControllerTest {
    @isTest
    static void testRoleBasedCollections() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.salesUser) {
            System.assertEquals(0, InventoryController.getPurchaseOrders().size(), 'Sales user must not retrieve purchase orders.');
            System.assertEquals(0, InventoryController.getRecentTransactions().size(), 'Sales user must not retrieve transactions.');
            System.assert(InventoryController.getRecentSalesOrders().size() > 0, 'Sales user must retrieve sales orders.');
            System.assert(InventoryController.getMonitorData().size() > 0, 'Sales user must retrieve monitor data.');
        }

        System.runAs(users.managerUser) {
            System.assert(InventoryController.getPurchaseOrders().size() > 0, 'Manager must retrieve purchase orders.');
            System.assert(InventoryController.getRecentTransactions().size() > 0, 'Manager must retrieve transactions.');
            System.assert(InventoryController.getRecentSalesOrders().size() > 0, 'Manager must retrieve sales orders.');
            System.assert(InventoryController.getSalesOrders().size() > 0, 'Manager must retrieve sales order collections.');
            System.assert(InventoryController.getSuppliers().size() > 0, 'Manager must retrieve suppliers.');
            System.assert(InventoryController.getMonitorData().size() > 0, 'Manager must retrieve monitor data.');
            System.assertNotEquals(null, InventoryController.getReorderPrefillInfo(data.productId), 'Manager must retrieve reorder prefill data.');
        }
    }

    @isTest
    static void testManagerToAdminReturnFlow() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.managerUser) {
            InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Under Review', null);
        }

        Return_Request__c afterManagerReview = [
            SELECT Status__c, Processed_By__c, Processed_Date__c
            FROM Return_Request__c
            WHERE Id = :data.salesReturnRequestId
        ];
        System.assertEquals('Under Review', afterManagerReview.Status__c, 'Manager should move submitted requests to Under Review.');

        System.runAs(users.adminUser) {
            InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Refunded', null);
        }

        Return_Request__c afterAdminDecision = [
            SELECT Status__c, Resolution_Type__c, Processed_By__c, Processed_Date__c
            FROM Return_Request__c
            WHERE Id = :data.salesReturnRequestId
        ];
        System.assertEquals('Refunded', afterAdminDecision.Status__c, 'Admin should be able to refund an under-review return.');
        System.assertEquals('Refund', afterAdminDecision.Resolution_Type__c, 'Refund action should stamp the refund resolution type.');
        System.assertEquals(users.adminUser.Id, afterAdminDecision.Processed_By__c, 'Processed by should reflect the admin user.');
        System.assertEquals(System.today(), afterAdminDecision.Processed_Date__c, 'Processed date should reflect the admin action date.');
    }

    @isTest
    static void testManagerCannotRefundDirectly() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.managerUser) {
            try {
                InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Refunded', null);
                System.assert(false, 'Manager must not be able to refund a submitted request.');
            } catch (AuraHandledException expectedException) {
                System.assert(String.isNotBlank(expectedException.getMessage()), 'Manager refund must fail with an error.');
            }
        }
    }

    @isTest
    static void testManagerReorderActions() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.managerUser) {
            InventoryController.ReorderPrefillInfo prefillInfo = InventoryController.getReorderPrefillInfo(data.productId);
            System.assertNotEquals(null, prefillInfo, 'Manager must receive reorder prefill info.');
            System.assertEquals(data.supplierId, prefillInfo.supplierId, 'The last supplier should seed reorder info.');
            System.assertEquals(50, prefillInfo.unitPrice, 'The last PO item should seed reorder pricing.');

            Id quickReorderId = InventoryController.quickReorder(data.productId, 4);
            Id manualReorderId = InventoryController.createPurchaseOrderWithItem(data.supplierId, data.productId, 2, 45);
            System.assertNotEquals(null, quickReorderId, 'Quick reorder should create a purchase order.');
            System.assertNotEquals(null, manualReorderId, 'Manual reorder helper should create a purchase order.');
        }
    }

    @isTest
    static void testAdminReportIdsAndReturnQueries() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.seedCoreData(users);

        System.runAs(users.adminUser) {
            Map<String, Id> reportIds = InventoryController.getReportIds();
            System.assertNotEquals(null, reportIds, 'Report lookup should return a map.');
            System.assert(InventoryController.getReturnRequests().size() > 0, 'Admin should retrieve return requests.');
        }
    }

    @isTest
    static void testNegativeAndValidationScenarios() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.salesUser) {
            try {
                InventoryController.processReturnRequest(data.salesReturnRequestId, 'Approved');
                System.assert(false, 'Sales user should be blocked from processing returns.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
            
            try {
                InventoryController.quickReorder(data.productId, 10);
                System.assert(false, 'Sales user should be blocked from quick reordering.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }

            try {
                InventoryController.createPurchaseOrderWithItem(data.supplierId, data.productId, 10, 100);
                System.assert(false, 'Sales user should be blocked from creating PO.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }

        System.runAs(users.managerUser) {
            // Manager cannot transition to Approved directly
            try {
                InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Approved', 'Repair');
                System.assert(false, 'Manager cannot transition directly to Approved.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }

            // Manager cannot process non-submitted request
            Return_Request__c req = new Return_Request__c(Id = data.salesReturnRequestId, Status__c = 'Under Review');
            update req;
            try {
                InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Under Review', null);
                System.assert(false, 'Manager cannot process non-submitted return request.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }

        System.runAs(users.adminUser) {
            // Admin must provide resolution type for Approved status
            Return_Request__c req = new Return_Request__c(Id = data.salesReturnRequestId, Status__c = 'Under Review');
            update req;
            try {
                InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Approved', null);
                System.assert(false, 'Admin must specify resolution type when approving.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }

            // Admin cannot process non-under review requests
            req.Status__c = 'Submitted';
            update req;
            try {
                InventoryController.processReturnRequestExtended(data.salesReturnRequestId, 'Approved', 'Repair');
                System.assert(false, 'Admin cannot process non-under review return requests.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
    }

    @isTest
    static void testQuickReorderNoSupplier() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        
        System.runAs(users.adminUser) {
            delete [SELECT Id FROM Supplier__c];
            delete [SELECT Id FROM Purchase_Order_Item__c];
            delete [SELECT Id FROM Purchase_Order__c];
            
            Product__c prod = new Product__c(
                Name = 'No Supplier Product',
                Product_Name__c = 'No Supplier Product',
                SKU__c = 'NS-123',
                Category__c = 'Electronics',
                Price__c = 100,
                Current_Stock__c = 5,
                Minimum_Stock__c = 2,
                Status__c = 'Active'
            );
            insert prod;
            
            try {
                InventoryController.quickReorder(prod.Id, 10);
                System.assert(false, 'Quick reorder should fail when no supplier exists.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
    }
}
