// Retest Automation Script for Inventory Management System
try {
    System.debug('===== STARTING RETEST AUTOMATION =====');

    // Clean up any old test records first to ensure clean test runs
    delete [SELECT Id FROM Inventory_Transaction__c WHERE Product__r.SKU__c IN ('SKU-AUTO-001', 'SKU-AUTO-002')];
    delete [SELECT Id FROM Sales_Order_Item__c WHERE Product__r.SKU__c IN ('SKU-AUTO-001', 'SKU-AUTO-002')];
    delete [SELECT Id FROM Sales_Order__c WHERE Customer_Name__c = 'Test Customer'];
    delete [SELECT Id FROM Purchase_Order_Item__c WHERE Product__r.SKU__c IN ('SKU-AUTO-001', 'SKU-AUTO-002')];
    delete [SELECT Id FROM Purchase_Order__c WHERE Supplier__r.Supplier_Name__c = 'Test Supplier Auto'];
    delete [SELECT Id FROM Supplier__c WHERE Supplier_Name__c = 'Test Supplier Auto'];
    delete [SELECT Id FROM Product__c WHERE SKU__c IN ('SKU-AUTO-001', 'SKU-AUTO-002')];
    delete [SELECT Id FROM Task WHERE Subject LIKE 'Low Stock Alert%'];

    // Create Supplier
    Supplier__c supp = new Supplier__c(
        Name = 'Test Supplier Auto',
        Supplier_Name__c = 'Test Supplier Auto',
        Email__c = 'supplier.auto@test.com',
        Phone__c = '9999999999',
        Status__c = 'Active'
    );
    insert supp;

    // SCENARIO 1: Create Product (Stock = 0), Receive PO (Qty = 50), Expected Stock = 50
    Product__c prod = new Product__c(
        Name = 'Test Auto Product 1',
        Product_Name__c = 'Test Auto Product 1',
        SKU__c = 'SKU-AUTO-001',
        Category__c = 'Electronics',
        Price__c = 100.00,
        Current_Stock__c = 0,
        Minimum_Stock__c = 10,
        Status__c = 'Active'
    );
    insert prod;
    System.debug('Scenario 1: Created Product with Current Stock = 0');

    Purchase_Order__c po = new Purchase_Order__c(
        Supplier__c = supp.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft'
    );
    insert po;

    Purchase_Order_Item__c poi = new Purchase_Order_Item__c(
        Purchase_Order__c = po.Id,
        Product__c = prod.Id,
        Quantity__c = 50,
        Unit_Price__c = 80.00
    );
    insert poi;
    System.debug('Scenario 1: Inserted PO Item with Qty = 50');

    // Trigger Flow 1 by changing status to Received
    po.Status__c = 'Received';
    update po;
    System.debug('Scenario 1: Purchase Order status updated to Received');

    // Verify Product Stock
    prod = [SELECT Id, Current_Stock__c FROM Product__c WHERE Id = :prod.Id];
    System.debug('Scenario 1 Result: Product Stock on Hand = ' + prod.Current_Stock__c);
    if (prod.Current_Stock__c != 50) {
        throw new IllegalArgumentException('Scenario 1 FAIL: Stock is ' + prod.Current_Stock__c + ', expected 50');
    }

    // Verify Inventory Transaction Created
    List<Inventory_Transaction__c> txns = [SELECT Id, Transaction_Type__c, Quantity__c FROM Inventory_Transaction__c WHERE Product__c = :prod.Id];
    System.debug('Scenario 1 Result: Number of Inventory Transactions = ' + txns.size());
    if (txns.isEmpty() || txns[0].Transaction_Type__c != 'Stock In' || txns[0].Quantity__c != 50) {
        throw new IllegalArgumentException('Scenario 1 FAIL: Inventory Transaction was not created correctly');
    }
    System.debug('Scenario 1: PASSED');

    // SCENARIO 2: Create Sales Order (Qty = 2), Expected Stock = 48, Inventory Transaction Created
    Sales_Order__c so = new Sales_Order__c(
        Customer_Name__c = 'Test Customer',
        Order_Date__c = System.today(),
        Status__c = 'Draft'
    );
    insert so;

    Sales_Order_Item__c soi = new Sales_Order_Item__c(
        Sales_Order__c = so.Id,
        Product__c = prod.Id,
        Quantity__c = 2,
        Unit_Price__c = 100.00
    );
    insert soi;
    System.debug('Scenario 2: Created Sales Order Item with Qty = 2');

    // Trigger Flow 2 by confirming the Sales Order
    so.Status__c = 'Confirmed';
    update so;
    System.debug('Scenario 2: Sales Order status updated to Confirmed');

    // Verify Product Stock
    prod = [SELECT Id, Current_Stock__c FROM Product__c WHERE Id = :prod.Id];
    System.debug('Scenario 2 Result: Product Stock on Hand = ' + prod.Current_Stock__c);
    if (prod.Current_Stock__c != 48) {
        throw new IllegalArgumentException('Scenario 2 FAIL: Stock is ' + prod.Current_Stock__c + ', expected 48');
    }

    // Verify Stock Out Transaction
    List<Inventory_Transaction__c> outTxns = [SELECT Id, Transaction_Type__c, Quantity__c FROM Inventory_Transaction__c WHERE Product__c = :prod.Id AND Transaction_Type__c = 'Stock Out'];
    System.debug('Scenario 2 Result: Number of Stock Out Transactions = ' + outTxns.size());
    if (outTxns.isEmpty() || outTxns[0].Quantity__c != 2) {
        throw new IllegalArgumentException('Scenario 2 FAIL: Stock Out Inventory Transaction not created correctly');
    }
    System.debug('Scenario 2: PASSED');

    // SCENARIO 3: Stock = 8, Minimum = 10, Expected: Low Stock Alert (Task) Created
    prod.Current_Stock__c = 8;
    update prod;
    System.debug('Scenario 3: Product Stock updated directly to 8 (Min Stock is 10)');

    // Verify Task Alert
    List<Task> alerts = [SELECT Id, Subject, Priority, Status, OwnerId FROM Task WHERE WhatId = :prod.Id];
    System.debug('Scenario 3 Result: Number of Tasks Created = ' + alerts.size());
    if (alerts.isEmpty()) {
        throw new IllegalArgumentException('Scenario 3 FAIL: Low Stock Alert Task was not created');
    }
    Task alert = alerts[0];
    System.debug('Scenario 3 Result: Subject=' + alert.Subject + ', Priority=' + alert.Priority + ', Status=' + alert.Status);
    if (!alert.Subject.contains('Low Stock Alert') || alert.Priority != 'High' || alert.Status != 'Not Started') {
        throw new IllegalArgumentException('Scenario 3 FAIL: Low Stock Alert Task properties are incorrect');
    }
    System.debug('Scenario 3: PASSED');

    // VALIDATION RULES RETEST
    // VR-002: Quantity > 0
    try {
        Sales_Order_Item__c invalidQtyItem = new Sales_Order_Item__c(
            Sales_Order__c = so.Id,
            Product__c = prod.Id,
            Quantity__c = 0,
            Unit_Price__c = 10.00
        );
        insert invalidQtyItem;
        throw new IllegalArgumentException('VR-002 FAIL: Allowed saving Sales Order Item with Quantity = 0');
    } catch (DmlException e) {
        System.debug('VR-002 PASS: Caught expected validation error: ' + e.getMessage());
    }

    // VR-003: Price > 0
    try {
        Product__c invalidPriceProd = new Product__c(
            Name = 'Invalid Price Product',
            Product_Name__c = 'Invalid Price Product',
            SKU__c = 'SKU-AUTO-002',
            Category__c = 'Electronics',
            Price__c = -5.00,
            Current_Stock__c = 10,
            Minimum_Stock__c = 2,
            Status__c = 'Active'
        );
        insert invalidPriceProd;
        throw new IllegalArgumentException('VR-003 FAIL: Allowed saving Product with negative price');
    } catch (DmlException e) {
        System.debug('VR-003 PASS: Caught expected validation error: ' + e.getMessage());
    }

    // VR-004: Cannot Confirm Sales Order if Stock < Ordered Quantity
    Sales_Order__c so2 = new Sales_Order__c(
        Customer_Name__c = 'Test Customer',
        Order_Date__c = System.today(),
        Status__c = 'Draft'
    );
    insert so2;

    Sales_Order_Item__c soi2 = new Sales_Order_Item__c(
        Sales_Order__c = so2.Id,
        Product__c = prod.Id,
        Quantity__c = 100, // Stock is 8 (Scenario 3 set it to 8)
        Unit_Price__c = 100.00
    );
    insert soi2;

    try {
        so2.Status__c = 'Confirmed';
        update so2;
        throw new IllegalArgumentException('VR-004 FAIL: Confirmed Sales Order when stock is insufficient');
    } catch (DmlException e) {
        System.debug('VR-004 PASS: Caught expected validation error: ' + e.getMessage());
    }

    System.debug('===== ALL SCENARIOS RETESTED AND PASSED SUCCESSFULLY =====');

} catch (Exception e) {
    System.debug('RETEST EXCEPTION: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
