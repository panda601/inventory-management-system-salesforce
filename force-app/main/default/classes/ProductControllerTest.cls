@isTest
public class ProductControllerTest {
    @isTest
    static void testSalesExecutiveProductVisibility() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.salesUser) {
            System.assertNotEquals(null, ProductController.getProductDetail(data.productId), 'Sales user must retrieve product detail.');
            System.assertNotEquals(null, ProductController.getProduct(data.productId), 'Sales user must retrieve product view data.');
            System.assertEquals(null, ProductController.getProductCostPrice(data.productId).costPrice, 'Sales user must not retrieve cost price.');
            System.assertEquals(null, ProductController.getProductSupplier(data.productId), 'Sales user must not retrieve supplier details.');
            System.assertEquals(0, ProductController.getProductTransactions(data.productId).size(), 'Sales user must not retrieve inventory transactions.');
            System.assert(ProductController.getProducts(null, null).size() > 0, 'Sales user must retrieve the default product list.');
            System.assert(ProductController.getProducts('Test', null).size() > 0, 'Sales user must retrieve search-filtered products.');
            System.assert(ProductController.getProducts(null, 'Electronics').size() > 0, 'Sales user must retrieve category-filtered products.');
        }
    }

    @isTest
    static void testManagerProductOperationalVisibility() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.adminUser) {
            Product__c p = [SELECT Id FROM Product__c WHERE Id = :data.productId];
            p.Product_Image__c = 'https://example.com/image.png';
            update p;
        }

        System.runAs(users.managerUser) {
            ProductController.ProductDetailView detailView = ProductController.getProduct(data.productId);
            System.assertNotEquals(null, detailView, 'Manager must retrieve product detail view.');
            System.assertEquals('https://example.com/image.png', detailView.productImage, 'Image must be returned.');
            System.assertEquals(50, ProductController.getProductCostPrice(data.productId).costPrice, 'Manager must retrieve the current cost price.');
            System.assertNotEquals(null, ProductController.getProductSupplier(data.productId), 'Manager must retrieve supplier details.');
            System.assertEquals(1, ProductController.getProductTransactions(data.productId).size(), 'Manager must retrieve product transactions.');
            System.assertNotEquals(null, ProductController.getInventory(data.productId), 'Manager must retrieve inventory state.');
            System.assertNotEquals(null, ProductController.getSupplier(data.productId), 'Manager must retrieve supplier through the compatibility helper.');
            System.assertEquals(1, ProductController.getTransactions(data.productId).size(), 'Manager must retrieve transactions through the compatibility helper.');
        }
    }

    @isTest
    static void testNullAndNegativeScenarios() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.managerUser) {
            // Null checks
            System.assertEquals(null, ProductController.getProductDetail(null));
            System.assertEquals(null, ProductController.getProduct(null));
            System.assertEquals(null, ProductController.getProductCostPrice(null).costPrice);
            System.assertEquals(null, ProductController.getProductSupplier(null));
            System.assertEquals(0, ProductController.getProductTransactions(null).size());
            System.assertEquals(null, ProductController.getInventory(null));

            // Unknown ID checks
            Id dummyId = 'a00000000000000AAA';
            System.assertEquals(null, ProductController.getProductDetail(dummyId));
            System.assertEquals(null, ProductController.getProduct(dummyId));

            // Multiple filter checks
            System.assertNotEquals(null, ProductController.getProducts('Test', 'Electronics'));
        }
    }
}
