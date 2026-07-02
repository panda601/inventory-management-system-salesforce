@isTest
public class InventoryTestSupport {
    public class TestUsers {
        public User adminUser;
        public User managerUser;
        public User salesUser;
    }

    public class SeedData {
        public Id productId;
        public Id supplierId;
        public Id purchaseOrderId;
        public Id purchaseOrderItemId;
        public Id inventoryTransactionId;
        public Id salesOrderId;
        public Id salesOrderItemId;
        public Id salesReturnRequestId;
        public Id adminReturnRequestId;
    }

    public static TestUsers createUsers() {
        Id profileId = [
            SELECT Id
            FROM Profile
            WHERE UserType = 'Standard'
            ORDER BY Name
            LIMIT 1
        ].Id;

        TestUsers users = new TestUsers();
        users.adminUser = buildUser(profileId, 'adm');
        users.managerUser = buildUser(profileId, 'mgr');
        users.salesUser = buildUser(profileId, 'sale');
        insert new List<User>{ users.adminUser, users.managerUser, users.salesUser };

        Map<String, Id> permissionSetIds = new Map<String, Id>();
        for (PermissionSet permissionSetRecord : [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name IN ('Admin_Access', 'Inventory_Manager_Access', 'Sales_Executive_Access')
        ]) {
            permissionSetIds.put(permissionSetRecord.Name, permissionSetRecord.Id);
        }

        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(
                AssigneeId = users.adminUser.Id,
                PermissionSetId = permissionSetIds.get('Admin_Access')
            ),
            new PermissionSetAssignment(
                AssigneeId = users.managerUser.Id,
                PermissionSetId = permissionSetIds.get('Inventory_Manager_Access')
            ),
            new PermissionSetAssignment(
                AssigneeId = users.salesUser.Id,
                PermissionSetId = permissionSetIds.get('Sales_Executive_Access')
            )
        };

        return users;
    }

    public static SeedData seedCoreData(TestUsers users) {
        SeedData data = new SeedData();

        System.runAs(users.adminUser) {
            Product__c productRecord = new Product__c(
                Name = 'Test Product',
                Product_Name__c = 'Test Product',
                SKU__c = 'SKU-' + uniqueSuffix(),
                Category__c = 'Electronics',
                Price__c = 100,
                Current_Stock__c = 10,
                Minimum_Stock__c = 2,
                Status__c = 'Active'
            );
            insert productRecord;
            data.productId = productRecord.Id;

            Supplier__c supplierRecord = new Supplier__c(
                Name = 'Test Supplier',
                Supplier_Name__c = 'Test Supplier',
                Status__c = 'Active',
                Email__c = 'supplier@test.example',
                Phone__c = '9999999999',
                Address__c = 'Warehouse Street'
            );
            insert supplierRecord;
            data.supplierId = supplierRecord.Id;

            Purchase_Order__c purchaseOrderRecord = new Purchase_Order__c(
                Supplier__c = supplierRecord.Id,
                Order_Date__c = System.today(),
                Status__c = 'Approved'
            );
            insert purchaseOrderRecord;
            data.purchaseOrderId = purchaseOrderRecord.Id;

            Purchase_Order_Item__c purchaseOrderItemRecord = new Purchase_Order_Item__c(
                Purchase_Order__c = purchaseOrderRecord.Id,
                Product__c = productRecord.Id,
                Quantity__c = 3,
                Unit_Price__c = 50
            );
            insert purchaseOrderItemRecord;
            data.purchaseOrderItemId = purchaseOrderItemRecord.Id;

            Inventory_Transaction__c transactionRecord = new Inventory_Transaction__c(
                Product__c = productRecord.Id,
                Transaction_Type__c = 'Adjustment',
                Quantity__c = 2,
                Transaction_Date__c = System.now()
            );
            insert transactionRecord;
            data.inventoryTransactionId = transactionRecord.Id;

        }

        System.runAs(users.salesUser) {
            Sales_Order__c salesOrderRecord = new Sales_Order__c(
                Customer_Name__c = 'Sales Customer',
                Customer_Email__c = 'customer@test.example',
                Order_Date__c = System.today(),
                Status__c = 'Delivered'
            );
            insert salesOrderRecord;
            data.salesOrderId = salesOrderRecord.Id;

            Sales_Order_Item__c salesOrderItemRecord = new Sales_Order_Item__c(
                Sales_Order__c = salesOrderRecord.Id,
                Product__c = data.productId,
                Quantity__c = 3,
                Unit_Price__c = 100
            );
            insert salesOrderItemRecord;
            data.salesOrderItemId = salesOrderItemRecord.Id;

            Return_Request__c salesReturnRequest = new Return_Request__c(
                Sales_Order__c = salesOrderRecord.Id,
                Sales_Order_Item__c = salesOrderItemRecord.Id,
                Customer_Name__c = 'Sales Customer',
                Customer_Email__c = 'customer@test.example',
                Product__c = data.productId,
                Quantity__c = 1,
                Reason__c = 'Damaged Product',
                Comments__c = 'Sales seeded return',
                Status__c = 'Submitted',
                Requested_Date__c = System.today(),
                Resolution_Type__c = 'Refund'
            );
            insert salesReturnRequest;
            data.salesReturnRequestId = salesReturnRequest.Id;
        }

        System.runAs(users.adminUser) {
            Return_Request__c adminReturnRequest = new Return_Request__c(
                Sales_Order__c = data.salesOrderId,
                Sales_Order_Item__c = data.salesOrderItemId,
                Customer_Name__c = 'Admin Customer',
                Customer_Email__c = 'admin@test.example',
                Product__c = data.productId,
                Quantity__c = 1,
                Reason__c = 'Damaged Product',
                Comments__c = 'Admin seeded return',
                Status__c = 'Submitted',
                Requested_Date__c = System.today(),
                Resolution_Type__c = 'Refund'
            );
            insert adminReturnRequest;
            data.adminReturnRequestId = adminReturnRequest.Id;
        }

        return data;
    }

    private static User buildUser(Id profileId, String aliasPrefix) {
        String suffix = uniqueSuffix();
        String aliasValue = (aliasPrefix + 'usr').substring(0, 4);
        return new User(
            Alias = aliasValue,
            Email = aliasPrefix + '.' + suffix + '@test.example',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User ' + aliasPrefix,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = aliasPrefix + '.' + suffix + '@inventory.example'
        );
    }

    private static String uniqueSuffix() {
        return String.valueOf(DateTime.now().getTime()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));
    }
}
