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

    @isTest
    static void testProductImageFeatures() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.SeedData data = InventoryTestSupport.seedCoreData(users);

        System.runAs(users.adminUser) {
            System.assertEquals(true, ProductImageController.isProductImageAdmin(), 'Admin user must be an image admin.');

            ContentVersion cv = new ContentVersion(
                Title = 'Product Image File',
                PathOnClient = 'image.png',
                VersionData = Blob.valueOf('Fake image binary data'),
                IsMajorVersion = true
            );
            insert cv;

            Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = data.productId,
                ContentDocumentId = docId,
                ShareType = 'V'
            );
            insert cdl;

            Map<Id, String> fileUrls = ProductController.getProductImageUrls(new List<Id>{data.productId});
            System.assertNotEquals(null, fileUrls.get(data.productId), 'File URL should be mapped for the product.');
            System.assert(fileUrls.get(data.productId).contains(cv.Id), 'File URL should contain ContentVersion ID.');

            List<Product__c> prods = ProductController.getProducts('Test', 'Electronics');
            System.assert(prods.size() > 0);
            System.assert(prods[0].Product_Image__c.contains('/sfc/servlet.shepherd/version/download/'), 'Image URL should be overwritten by Salesforce File.');

            Product__c prodDetail = ProductController.getProductDetail(data.productId);
            System.assert(prodDetail.Product_Image__c.contains('/sfc/servlet.shepherd/version/download/'), 'Image URL in details should be overwritten.');

            ContentVersion cvNew = new ContentVersion(
                Title = 'New Product Image File',
                PathOnClient = 'new_image.jpg',
                VersionData = Blob.valueOf('Fake new image binary data'),
                IsMajorVersion = true
            );
            insert cvNew;

            Id newDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvNew.Id].ContentDocumentId;

            ContentDocumentLink cdlNew = new ContentDocumentLink(
                LinkedEntityId = data.productId,
                ContentDocumentId = newDocId,
                ShareType = 'V'
            );
            insert cdlNew;

            ProductImageController.deleteOldImages(data.productId, newDocId);

            List<ContentDocument> remainingDocs = [SELECT Id FROM ContentDocument WHERE Id = :docId];
            System.assertEquals(0, remainingDocs.size(), 'Replaced image document should be deleted.');

            ProductImageController.deleteProductImage(data.productId);

            List<ContentDocument> allDocs = [SELECT Id FROM ContentDocument WHERE Id = :newDocId];
            System.assertEquals(0, allDocs.size(), 'Deleted image document should be deleted.');
        }

        System.runAs(users.salesUser) {
            System.assertEquals(false, ProductImageController.isProductImageAdmin(), 'Sales Executive must not be an image admin.');

            try {
                ProductImageController.deleteProductImage(data.productId);
                System.assert(false, 'Sales Executive must be blocked from deleting.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }

            try {
                ProductImageController.deleteOldImages(data.productId, '069000000000000AAA');
                System.assert(false, 'Sales Executive must be blocked from replacing.');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
    }
}
