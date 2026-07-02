@isTest
public class InventoryDashboardControllerTest {
    @isTest
    static void testAdminFinancialSummary() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.seedCoreData(users);

        System.runAs(users.adminUser) {
            InventoryDashboardController.InventorySummary inventorySummary = InventoryDashboardController.getInventorySummary();
            InventoryDashboardController.AdminDashboardSummary adminSummary = InventoryDashboardController.getAdminDashboardSummary();
            List<InventoryDashboardController.MonthlyPnLPoint> pnlPoints = InventoryDashboardController.getMonthlyPnLData();
            InventoryDashboardController.SalesSummary salesSummary = InventoryDashboardController.getSalesSummary();
            List<Map<String, Object>> inventoryTrendData = InventoryDashboardController.getInventoryTrendData();
            List<Map<String, Object>> salesRevenueData = InventoryDashboardController.getSalesRevenueData();

            System.assertEquals(1, inventorySummary.totalProducts, 'Inventory summary should include the seeded product.');
            System.assertEquals(10, inventorySummary.availableStock, 'Inventory summary should total the seeded stock.');
            System.assertEquals(300, adminSummary.revenue, 'Admin summary should expose revenue.');
            System.assertEquals(150, adminSummary.procurementCost, 'Admin summary should expose procurement cost.');
            System.assertEquals(150, adminSummary.profit, 'Admin summary should expose profit.');
            System.assertEquals(6, pnlPoints.size(), 'Monthly PnL should return six buckets.');
            System.assertEquals(1, salesSummary.totalOrders, 'Sales summary should count the seeded sales order.');
            System.assertEquals(300, salesSummary.totalRevenue, 'Sales summary should expose seeded revenue.');
            System.assert(inventoryTrendData.size() > 0, 'Inventory trend data should include the seeded transaction.');
            System.assert(salesRevenueData.size() > 0, 'Sales revenue data should include the seeded delivered order.');

            Boolean hasRevenuePoint = false;
            for (InventoryDashboardController.MonthlyPnLPoint point : pnlPoints) {
                if (point.revenue > 0) {
                    hasRevenuePoint = true;
                    break;
                }
            }
            System.assertEquals(true, hasRevenuePoint, 'Monthly PnL should include the seeded revenue bucket.');
        }
    }

    @isTest
    static void testNonAdminFinancialMetricsAreMasked() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.seedCoreData(users);

        System.runAs(users.salesUser) {
            InventoryDashboardController.AdminDashboardSummary adminSummary = InventoryDashboardController.getAdminDashboardSummary();
            List<InventoryDashboardController.MonthlyPnLPoint> pnlPoints = InventoryDashboardController.getMonthlyPnLData();

            System.assertEquals(0, adminSummary.revenue, 'Sales user must not see revenue through the admin summary endpoint.');
            System.assertEquals(0, adminSummary.procurementCost, 'Sales user must not see procurement cost through the admin summary endpoint.');
            System.assertEquals(0, adminSummary.profit, 'Sales user must not see profit through the admin summary endpoint.');

            for (InventoryDashboardController.MonthlyPnLPoint point : pnlPoints) {
                System.assertEquals(0, point.revenue, 'Sales user PnL revenue should be masked.');
                System.assertEquals(0, point.procurementCost, 'Sales user PnL procurement cost should be masked.');
                System.assertEquals(0, point.profit, 'Sales user PnL profit should be masked.');
            }
        }
    }

    @isTest
    static void testNewDashboardEndpoints() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.seedCoreData(users);

        System.runAs(users.adminUser) {
            List<InventoryDashboardController.SupplierPerformance> suppliers = InventoryDashboardController.getSupplierPerformanceData();
            List<InventoryDashboardController.ProductPerformance> products = InventoryDashboardController.getProductPerformanceData();
            InventoryDashboardController.InventoryHealthData health = InventoryDashboardController.getInventoryHealthData();
            InventoryDashboardController.ForecastData forecast = InventoryDashboardController.getForecastingData();

            System.assert(suppliers.size() > 0, 'Should return simulated supplier performance records');
            System.assert(products.size() > 0, 'Should return simulated product performance records');
            System.assertNotEquals(null, health, 'Should return inventory health data');
            System.assertNotEquals(null, forecast, 'Should return forecast data');
        }
    }
}
