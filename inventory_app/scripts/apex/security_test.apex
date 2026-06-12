try {
    System.debug('===== STARTING SECURITY TEST =====');

    // Fetch users
    User invManager = [SELECT Id FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
    User salesExec = [SELECT Id FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];

    // Get any existing Product and Supplier
    Product__c prod = [SELECT Id FROM Product__c LIMIT 1];
    Supplier__c supp = [SELECT Id FROM Supplier__c LIMIT 1];

    // TEST 1: Sales Executive User Run-as check
    System.runAs(salesExec) {
        // Can access Product (Read)
        try {
            List<Product__c> prods = [SELECT Id FROM Product__c WITH USER_MODE];
            System.debug('Security Test: Sales Executive CAN read Product__c - PASS');
        } catch (Exception e) {
            System.debug('Security Test: Sales Executive CANNOT read Product__c - FAIL: ' + e.getMessage());
        }

        // Can access Sales Order
        try {
            Sales_Order__c so = new Sales_Order__c(Customer_Name__c = 'Test Security', Order_Date__c = System.today(), Status__c = 'Draft');
            insert as user so;
            System.debug('Security Test: Sales Executive CAN insert Sales_Order__c - PASS');
        } catch (Exception e) {
            System.debug('Security Test: Sales Executive CANNOT insert Sales_Order__c - FAIL: ' + e.getMessage());
        }

        // Cannot access Supplier
        try {
            List<Supplier__c> supps = [SELECT Id FROM Supplier__c WITH USER_MODE];
            System.debug('Security Test: Sales Executive CAN read Supplier__c - FAIL');
        } catch (Exception e) {
            System.debug('Security Test: Sales Executive CANNOT read Supplier__c - PASS (Expected: ' + e.getMessage() + ')');
        }

        // Cannot access Purchase Order
        try {
            List<Purchase_Order__c> pos = [SELECT Id FROM Purchase_Order__c WITH USER_MODE];
            System.debug('Security Test: Sales Executive CAN read Purchase_Order__c - FAIL');
        } catch (Exception e) {
            System.debug('Security Test: Sales Executive CANNOT read Purchase_Order__c - PASS (Expected: ' + e.getMessage() + ')');
        }

        // Cannot access Inventory Transaction
        try {
            List<Inventory_Transaction__c> txns = [SELECT Id FROM Inventory_Transaction__c WITH USER_MODE];
            System.debug('Security Test: Sales Executive CAN read Inventory_Transaction__c - FAIL');
        } catch (Exception e) {
            System.debug('Security Test: Sales Executive CANNOT read Inventory_Transaction__c - PASS (Expected: ' + e.getMessage() + ')');
        }
    }

    // TEST 2: Inventory Manager User Run-as check
    System.runAs(invManager) {
        // Can access Product
        try {
            List<Product__c> prods = [SELECT Id FROM Product__c WITH USER_MODE];
            System.debug('Security Test: Inventory Manager CAN read Product__c - PASS');
        } catch (Exception e) {
            System.debug('Security Test: Inventory Manager CANNOT read Product__c - FAIL: ' + e.getMessage());
        }

        // Can access Supplier
        try {
            Supplier__c testSupp = new Supplier__c(Supplier_Name__c = 'Test Security Supp', Status__c = 'Active');
            insert as user testSupp;
            System.debug('Security Test: Inventory Manager CAN insert Supplier__c - PASS');
        } catch (Exception e) {
            System.debug('Security Test: Inventory Manager CANNOT insert Supplier__c - FAIL: ' + e.getMessage());
        }

        // Can access Purchase Order
        try {
            Purchase_Order__c testPo = new Purchase_Order__c(Supplier__c = supp.Id, Order_Date__c = System.today(), Status__c = 'Draft');
            insert as user testPo;
            System.debug('Security Test: Inventory Manager CAN insert Purchase_Order__c - PASS');
        } catch (Exception e) {
            System.debug('Security Test: Inventory Manager CANNOT insert Purchase_Order__c - FAIL: ' + e.getMessage());
        }

        // Can access Inventory Transaction (Read only)
        try {
            List<Inventory_Transaction__c> txns = [SELECT Id FROM Inventory_Transaction__c WITH USER_MODE];
            System.debug('Security Test: Inventory Manager CAN read Inventory_Transaction__c - PASS');
        } catch (Exception e) {
            System.debug('Security Test: Inventory Manager CANNOT read Inventory_Transaction__c - FAIL: ' + e.getMessage());
        }

        // Cannot insert Inventory Transaction (Read only check)
        try {
            Inventory_Transaction__c testTxn = new Inventory_Transaction__c(Product__c = prod.Id, Quantity__c = 5, Transaction_Type__c = 'Adjustment', Transaction_Date__c = System.now());
            insert as user testTxn;
            System.debug('Security Test: Inventory Manager CAN insert Inventory_Transaction__c - FAIL');
        } catch (Exception e) {
            System.debug('Security Test: Inventory Manager CANNOT insert Inventory_Transaction__c - PASS (Expected: ' + e.getMessage() + ')');
        }
    }

    System.debug('===== SECURITY TEST COMPLETED =====');
} catch (Exception e) {
    System.debug('EXCEPTION: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
