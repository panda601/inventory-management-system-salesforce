@isTest
public class IMS_AgentActionsTest {
    
    @isTest
    static void testAllAgentActions() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);
        
        System.runAs(users.adminUser) {
            // Test 1: IMS_GetProductDetail
            IMS_GetProductDetail.Request getDetailReq = new IMS_GetProductDetail.Request();
            getDetailReq.productId = data.productId;
            List<IMS_GetProductDetail.ProductDetails> detailRes = IMS_GetProductDetail.execute(new List<IMS_GetProductDetail.Request>{ getDetailReq });
            System.assertNotEquals(null, detailRes);
            System.assertEquals(1, detailRes.size());
            if (detailRes[0] != null) {
                System.assertEquals(data.productId, detailRes[0].productId);
            }
            
            // Test 2: IMS_GetInventoryHealth
            IMS_GetInventoryHealth.Request getHealthReq = new IMS_GetInventoryHealth.Request();
            List<IMS_GetInventoryHealth.HealthSummary> healthRes = IMS_GetInventoryHealth.execute(new List<IMS_GetInventoryHealth.Request>{ getHealthReq });
            System.assertNotEquals(null, healthRes);
            System.assertEquals(1, healthRes.size());
            
            // Test 3: IMS_CreatePurchaseOrder
            IMS_CreatePurchaseOrder.Request poReq = new IMS_CreatePurchaseOrder.Request();
            poReq.supplierId = data.supplierId;
            poReq.productId = data.productId;
            poReq.quantity = 10;
            poReq.unitPrice = 45;
            List<Id> poRes = IMS_CreatePurchaseOrder.execute(new List<IMS_CreatePurchaseOrder.Request>{ poReq });
            System.assertNotEquals(null, poRes);
            System.assertEquals(1, poRes.size());
            System.assertNotEquals(null, poRes[0]);
            
            // Test 4: IMS_CreateSalesOrder
            IMS_CreateSalesOrder.Request soReq = new IMS_CreateSalesOrder.Request();
            soReq.customerName = 'Test Agent Customer';
            soReq.productId = data.productId;
            soReq.quantity = 2;
            soReq.unitPrice = 120;
            List<Id> soRes = IMS_CreateSalesOrder.execute(new List<IMS_CreateSalesOrder.Request>{ soReq });
            System.assertNotEquals(null, soRes);
            System.assertEquals(1, soRes.size());
            System.assertNotEquals(null, soRes[0]);
            
            // Test 5: IMS_ProcessReturnRequest
            // Update return request status from Submitted to Under Review (by Manager/Admin)
            IMS_ProcessReturnRequest.Request retReq = new IMS_ProcessReturnRequest.Request();
            retReq.requestId = data.adminReturnRequestId;
            retReq.status = 'Under Review';
            List<Boolean> retRes = IMS_ProcessReturnRequest.execute(new List<IMS_ProcessReturnRequest.Request>{ retReq });
            System.assertNotEquals(null, retRes);
            System.assertEquals(1, retRes.size());
            
            // Test 6: IMS_GetSupplierPerformance
            IMS_GetSupplierPerformance.Request supPerfReq = new IMS_GetSupplierPerformance.Request();
            List<List<IMS_GetSupplierPerformance.SupplierPerformanceView>> supPerfRes = IMS_GetSupplierPerformance.execute(new List<IMS_GetSupplierPerformance.Request>{ supPerfReq });
            System.assertNotEquals(null, supPerfRes);
            System.assertEquals(1, supPerfRes.size());
            
            // Test 7: IMS_GetProductPerformance
            IMS_GetProductPerformance.Request prodPerfReq = new IMS_GetProductPerformance.Request();
            List<List<IMS_GetProductPerformance.ProductPerformanceView>> prodPerfRes = IMS_GetProductPerformance.execute(new List<IMS_GetProductPerformance.Request>{ prodPerfReq });
            System.assertNotEquals(null, prodPerfRes);
            System.assertEquals(1, prodPerfRes.size());
            
            // Test 8: IMS_GetLowStockAlerts
            IMS_GetLowStockAlerts.Request lowStockReq = new IMS_GetLowStockAlerts.Request();
            List<List<IMS_GetLowStockAlerts.LowStockAlertView>> lowStockRes = IMS_GetLowStockAlerts.execute(new List<IMS_GetLowStockAlerts.Request>{ lowStockReq });
            System.assertNotEquals(null, lowStockRes);
            System.assertEquals(1, lowStockRes.size());
            
            // Test 9: IMS_DeleteProductImage
            IMS_DeleteProductImage.Request delImgReq = new IMS_DeleteProductImage.Request();
            delImgReq.productId = data.productId;
            List<Boolean> delImgRes = IMS_DeleteProductImage.execute(new List<IMS_DeleteProductImage.Request>{ delImgReq });
            System.assertNotEquals(null, delImgRes);
            System.assertEquals(1, delImgRes.size());
            
            // Test 10: IMS_GetSystemHealth
            IMS_GetSystemHealth.Request sysHealthReq = new IMS_GetSystemHealth.Request();
            List<IMS_GetSystemHealth.SystemHealthSummary> sysHealthRes = IMS_GetSystemHealth.execute(new List<IMS_GetSystemHealth.Request>{ sysHealthReq });
            System.assertNotEquals(null, sysHealthRes);
            System.assertEquals(1, sysHealthRes.size());
            System.assertEquals('HEALTHY', sysHealthRes[0].systemStatus);
        }
    }
}
