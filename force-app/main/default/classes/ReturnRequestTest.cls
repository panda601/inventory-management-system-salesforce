@isTest
public class ReturnRequestTest {
    @isTest
    static void testReturnRequestScenarios() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();

        Product__c productRecord;
        System.runAs(users.adminUser) {
            productRecord = new Product__c(
                Name = 'Test Product',
                Product_Name__c = 'Test Product',
                SKU__c = 'TEST-SKU-1',
                Category__c = 'Electronics',
                Price__c = 100.00,
                Current_Stock__c = 10,
                Minimum_Stock__c = 2,
                Status__c = 'Active'
            );
            insert productRecord;
        }

        Sales_Order__c salesOrderRecord;
        Sales_Order_Item__c salesOrderItemRecord;
        Return_Request__c repairRequest;
        Return_Request__c replacementRequest;
        Return_Request__c rejectedRequest;

        System.runAs(users.salesUser) {
            salesOrderRecord = new Sales_Order__c(
                Customer_Name__c = 'Test Customer',
                Customer_Email__c = 'customer@test.com',
                Order_Date__c = System.today(),
                Status__c = 'Draft'
            );
            insert salesOrderRecord;

            salesOrderItemRecord = new Sales_Order_Item__c(
                Sales_Order__c = salesOrderRecord.Id,
                Product__c = productRecord.Id,
                Quantity__c = 5,
                Unit_Price__c = 100.00
            );
            insert salesOrderItemRecord;

            repairRequest = createReturnRequest(
                salesOrderRecord.Id,
                salesOrderItemRecord.Id,
                productRecord.Id,
                salesOrderRecord.Customer_Name__c,
                'Repair'
            );
            replacementRequest = createReturnRequest(
                salesOrderRecord.Id,
                salesOrderItemRecord.Id,
                productRecord.Id,
                salesOrderRecord.Customer_Name__c,
                'Replacement'
            );
            rejectedRequest = createReturnRequest(
                salesOrderRecord.Id,
                salesOrderItemRecord.Id,
                productRecord.Id,
                salesOrderRecord.Customer_Name__c,
                'Refund'
            );

            List<Return_Request__c> visibleRequests = InventoryController.getReturnRequests();
            System.assertEquals(3, visibleRequests.size(), 'Sales user should see the submitted return requests.');
        }

        Return_Request__c insertedReq = [SELECT OwnerId, Status__c FROM Return_Request__c WHERE Id = :repairRequest.Id];
        System.assertEquals('Submitted', insertedReq.Status__c, 'Status should start as Submitted.');
        System.assertEquals(users.salesUser.Id, insertedReq.OwnerId, 'Submitted flow must not reassign ownership.');

        Product__c updatedProd = [SELECT Current_Stock__c, Status__c FROM Product__c WHERE Id = :productRecord.Id];
        System.assertEquals(10, updatedProd.Current_Stock__c, 'Submitting a return request must not change stock.');

        System.runAs(users.managerUser) {
            InventoryController.processReturnRequestExtended(repairRequest.Id, 'Under Review', null);
            InventoryController.processReturnRequestExtended(replacementRequest.Id, 'Under Review', null);
            InventoryController.processReturnRequestExtended(rejectedRequest.Id, 'Rejected', null);
        }

        Return_Request__c repairUnderReview = [SELECT Status__c FROM Return_Request__c WHERE Id = :repairRequest.Id];
        Return_Request__c replacementUnderReview = [SELECT Status__c FROM Return_Request__c WHERE Id = :replacementRequest.Id];
        Return_Request__c rejectedResult = [SELECT Status__c FROM Return_Request__c WHERE Id = :rejectedRequest.Id];
        System.assertEquals('Under Review', repairUnderReview.Status__c, 'Requests should be routable to Under Review.');
        System.assertEquals('Under Review', replacementUnderReview.Status__c, 'Replacement request should move to Under Review before admin action.');
        System.assertEquals('Rejected', rejectedResult.Status__c, 'Rejected requests should remain Rejected for user tracking.');

        Test.startTest();
        System.runAs(users.adminUser) {
            InventoryController.processReturnRequestExtended(repairRequest.Id, 'Approved', 'Repair');
            InventoryController.processReturnRequestExtended(replacementRequest.Id, 'Approved', 'Replacement');
        }
        Test.stopTest();

        Return_Request__c approvedRepair = [
            SELECT Status__c, Processed_Date__c, Processed_By__c, Resolution_Type__c
            FROM Return_Request__c
            WHERE Id = :repairRequest.Id
        ];
        Return_Request__c approvedReplacement = [
            SELECT Status__c, Resolution_Type__c
            FROM Return_Request__c
            WHERE Id = :replacementRequest.Id
        ];

        System.assertEquals('Approved', approvedRepair.Status__c, 'Admin repair approval should keep the request in Approved.');
        System.assertEquals('Repair', approvedRepair.Resolution_Type__c, 'Repair approval should preserve the repair resolution.');
        System.assertEquals(System.today(), approvedRepair.Processed_Date__c, 'Processed date should be updated on admin decision.');
        System.assertEquals(users.adminUser.Id, approvedRepair.Processed_By__c, 'Processed by should reflect the admin user.');
        System.assertEquals('Replacement Sent', approvedReplacement.Status__c, 'Replacement approval should complete as Replacement Sent.');
        System.assertEquals('Replacement', approvedReplacement.Resolution_Type__c, 'Replacement approval should preserve the replacement resolution.');

        updatedProd = [SELECT Current_Stock__c, Status__c FROM Product__c WHERE Id = :productRecord.Id];
        System.assertEquals(10, updatedProd.Current_Stock__c, 'Repair and replacement approvals together should net to the original stock quantity.');
        System.assertEquals('Under Inspection', updatedProd.Status__c, 'Repair approval should mark the product as Under Inspection.');

        List<Inventory_Transaction__c> txns = [
            SELECT Transaction_Type__c, Quantity__c, Product__c
            FROM Inventory_Transaction__c
            WHERE Product__c = :productRecord.Id
            ORDER BY CreatedDate ASC
        ];
        System.assertEquals(2, txns.size(), 'Repair and replacement approvals should each create one inventory transaction.');
        System.assertEquals('Adjustment', txns[0].Transaction_Type__c, 'Repair approval should create an Adjustment transaction.');
        System.assertEquals('Stock Out', txns[1].Transaction_Type__c, 'Replacement approval should create a Stock Out transaction.');
        System.assertEquals(3, txns[0].Quantity__c, 'Adjustment quantity should match the repair request quantity.');
        System.assertEquals(3, txns[1].Quantity__c, 'Stock out quantity should match the replacement request quantity.');
    }

    private static Return_Request__c createReturnRequest(
        Id salesOrderId,
        Id salesOrderItemId,
        Id productId,
        String customerName,
        String resolutionType
    ) {
        Return_Request__c requestRecord = new Return_Request__c(
            Sales_Order__c = salesOrderId,
            Sales_Order_Item__c = salesOrderItemId,
            Customer_Name__c = customerName,
            Customer_Email__c = 'customer@test.com',
            Product__c = productId,
            Quantity__c = 3,
            Reason__c = 'Damaged Product',
            Comments__c = 'Broken Screen',
            Status__c = 'Submitted',
            Resolution_Type__c = resolutionType,
            Requested_Date__c = System.today()
        );
        insert requestRecord;
        return requestRecord;
    }
}
