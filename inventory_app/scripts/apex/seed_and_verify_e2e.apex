try {
    System.debug('===== STARTING E2E SEEDING & VERIFICATION =====');

    // Fetch users
    User invManager = [SELECT Id, Username FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
    User salesExec = [SELECT Id, Username FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];

    System.debug('Inventory Manager User: ' + invManager.Username + ' (Id: ' + invManager.Id + ')');
    System.debug('Sales Executive User: ' + salesExec.Username + ' (Id: ' + salesExec.Id + ')');

    // 1. Clear old data
    delete [SELECT Id FROM Inventory_Transaction__c];
    delete [SELECT Id FROM Sales_Order_Item__c];
    delete [SELECT Id FROM Sales_Order__c];
    delete [SELECT Id FROM Purchase_Order_Item__c];
    delete [SELECT Id FROM Purchase_Order__c];
    delete [SELECT Id FROM Product__c];
    delete [SELECT Id FROM Supplier__c];
    delete [SELECT Id FROM Task WHERE Subject LIKE 'Low Stock Alert%'];
    System.debug('Old data successfully cleared.');

    // 2. Seed Suppliers
    Supplier__c dellSupp = new Supplier__c(
        Name = 'Dell Technologies',
        Supplier_Name__c = 'Dell Technologies',
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Supplier__c hpSupp = new Supplier__c(
        Name = 'HP India',
        Supplier_Name__c = 'HP India',
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Supplier__c lenovoSupp = new Supplier__c(
        Name = 'Lenovo India',
        Supplier_Name__c = 'Lenovo India',
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    List<Supplier__c> suppliers = new List<Supplier__c>{dellSupp, hpSupp, lenovoSupp};
    insert suppliers;
    System.debug('Seeded 3 Suppliers.');

    // 3. Seed Products
    Product__c dellProd = new Product__c(
        Name = 'Dell Latitude 5440',
        Product_Name__c = 'Dell Latitude 5440',
        SKU__c = 'DELL-LAT-5440',
        Category__c = 'Electronics',
        Price__c = 60000.00,
        Current_Stock__c = 0,
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c hpProd = new Product__c(
        Name = 'HP ProBook 450',
        Product_Name__c = 'HP ProBook 450',
        SKU__c = 'HP-PRO-450',
        Category__c = 'Electronics',
        Price__c = 55000.00,
        Current_Stock__c = 0,
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c lenovoProd = new Product__c(
        Name = 'Lenovo ThinkPad E14',
        Product_Name__c = 'Lenovo ThinkPad E14',
        SKU__c = 'LEN-THINK-E14',
        Category__c = 'Electronics',
        Price__c = 50000.00,
        Current_Stock__c = 0,
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c logitechProd = new Product__c(
        Name = 'Logitech Mouse',
        Product_Name__c = 'Logitech Mouse',
        SKU__c = 'LOGI-MS-1',
        Category__c = 'Electronics',
        Price__c = 1000.00,
        Current_Stock__c = 0,
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c dellKbProd = new Product__c(
        Name = 'Dell Keyboard',
        Product_Name__c = 'Dell Keyboard',
        SKU__c = 'DELL-KB-1',
        Category__c = 'Electronics',
        Price__c = 1500.00,
        Current_Stock__c = 0,
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    List<Product__c> products = new List<Product__c>{dellProd, hpProd, lenovoProd, logitechProd, dellKbProd};
    insert products;
    System.debug('Seeded 5 Products.');

    // SCENARIO 3: Create Purchase Order (po1) -> Qty=50, Unit Price=80
    Purchase_Order__c po1 = new Purchase_Order__c(
        Supplier__c = dellSupp.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = invManager.Id
    );
    insert po1;

    Purchase_Order_Item__c poi1 = new Purchase_Order_Item__c(
        Purchase_Order__c = po1.Id,
        Product__c = dellProd.Id,
        Quantity__c = 50,
        Unit_Price__c = 80.00
    );
    insert poi1;
    System.debug('Created Purchase Order 1 (Draft) with 50 Dell Latitudes @ 80 each.');

    // Query and Verify totals
    poi1 = [SELECT Id, Line_Total__c FROM Purchase_Order_Item__c WHERE Id = :poi1.Id];
    po1 = [SELECT Id, Total_Amount__c FROM Purchase_Order__c WHERE Id = :po1.Id];
    System.debug('Scenario 3 Verification: Line_Total__c = ' + poi1.Line_Total__c + ', Total_Amount__c = ' + po1.Total_Amount__c);
    if (poi1.Line_Total__c != 4000.00 || po1.Total_Amount__c != 4000.00) {
        throw new IllegalArgumentException('Scenario 3 FAIL: Expected totals to be 4000.00');
    }
    System.debug('Scenario 3: PASSED');

    // SCENARIO 4: Transition Purchase Order to Received -> verify stock increases and transaction created
    po1.Status__c = 'Received';
    update po1;
    System.debug('Updated Purchase Order 1 status to Received.');

    // Verify Dell Latitude stock increased to 50
    dellProd = [SELECT Id, Current_Stock__c FROM Product__c WHERE Id = :dellProd.Id];
    System.debug('Scenario 4 Verification: Product stock = ' + dellProd.Current_Stock__c);
    if (dellProd.Current_Stock__c != 50) {
        throw new IllegalArgumentException('Scenario 4 FAIL: Expected product stock to be 50, got ' + dellProd.Current_Stock__c);
    }

    // Verify Stock In transaction is created
    List<Inventory_Transaction__c> txnsIn = [
        SELECT Id, Transaction_Type__c, Quantity__c 
        FROM Inventory_Transaction__c 
        WHERE Product__c = :dellProd.Id AND Transaction_Type__c = 'Stock In'
    ];
    System.debug('Scenario 4 Verification: Number of Stock In transactions = ' + txnsIn.size());
    if (txnsIn.isEmpty() || txnsIn[0].Quantity__c != 50) {
        throw new IllegalArgumentException('Scenario 4 FAIL: Expected Stock In transaction of Qty 50');
    }
    System.debug('Scenario 4: PASSED');

    // Seed PO-1002 for completeness
    Purchase_Order__c po2 = new Purchase_Order__c(
        Supplier__c = hpSupp.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = invManager.Id
    );
    insert po2;
    Purchase_Order_Item__c poi2 = new Purchase_Order_Item__c(
        Purchase_Order__c = po2.Id,
        Product__c = hpProd.Id,
        Quantity__c = 10,
        Unit_Price__c = 50.00
    );
    insert poi2;
    po2.Status__c = 'Received';
    update po2;
    System.debug('Seeded Purchase Order 2 and marked Received.');

    // SCENARIO 5: Create Sales Order (so1) -> Qty=2 -> verify stock reduces by 2 and transaction created
    Sales_Order__c so1 = new Sales_Order__c(
        Customer_Name__c = 'Test Customer 1',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert so1;

    Sales_Order_Item__c soi1 = new Sales_Order_Item__c(
        Sales_Order__c = so1.Id,
        Product__c = dellProd.Id,
        Quantity__c = 2,
        Unit_Price__c = 100.00
    );
    insert soi1;
    System.debug('Created Sales Order 1 (Draft) with Qty = 2.');

    // Confirm the Sales Order
    so1.Status__c = 'Confirmed';
    update so1;
    System.debug('Updated Sales Order 1 status to Confirmed.');

    // Verify Dell Latitude stock reduced to 48
    dellProd = [SELECT Id, Current_Stock__c FROM Product__c WHERE Id = :dellProd.Id];
    System.debug('Scenario 5 Verification: Product stock = ' + dellProd.Current_Stock__c);
    if (dellProd.Current_Stock__c != 48) {
        throw new IllegalArgumentException('Scenario 5 FAIL: Expected product stock to be 48, got ' + dellProd.Current_Stock__c);
    }

    // Verify Stock Out transaction is created
    List<Inventory_Transaction__c> txnsOut = [
        SELECT Id, Transaction_Type__c, Quantity__c 
        FROM Inventory_Transaction__c 
        WHERE Product__c = :dellProd.Id AND Transaction_Type__c = 'Stock Out'
    ];
    System.debug('Scenario 5 Verification: Number of Stock Out transactions = ' + txnsOut.size());
    if (txnsOut.isEmpty() || txnsOut[0].Quantity__c != 2) {
        throw new IllegalArgumentException('Scenario 5 FAIL: Expected Stock Out transaction of Qty 2');
    }
    System.debug('Scenario 5: PASSED');

    // Seed SO-1002 for completeness
    Sales_Order__c so2 = new Sales_Order__c(
        Customer_Name__c = 'Test Customer 2',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert so2;
    Sales_Order_Item__c soi2 = new Sales_Order_Item__c(
        Sales_Order__c = so2.Id,
        Product__c = hpProd.Id,
        Quantity__c = 5,
        Unit_Price__c = 110.00
    );
    insert soi2;
    so2.Status__c = 'Confirmed';
    update so2;
    System.debug('Seeded Sales Order 2 and marked Confirmed.');

    // SCENARIO 6: Low Stock Alert -> Logitech Mouse stock set to 8 (Min Stock is 10)
    logitechProd.Current_Stock__c = 8;
    logitechProd.Minimum_Stock__c = 10;
    update logitechProd;
    System.debug('Updated Logitech Mouse stock to 8 (Min Stock = 10).');

    // Add a 5th Inventory Transaction (Adjustment) to meet the 5 transactions requirement
    Inventory_Transaction__c adjTxn = new Inventory_Transaction__c(
        Product__c = lenovoProd.Id,
        Transaction_Type__c = 'Adjustment',
        Quantity__c = 10,
        Transaction_Date__c = System.now()
    );
    insert adjTxn;
    System.debug('Seeded a 5th Inventory Transaction (Adjustment).');

    // Verify Task Alert
    List<Task> alerts = [SELECT Id, Subject, Priority, Status, OwnerId FROM Task WHERE WhatId = :logitechProd.Id];
    System.debug('Scenario 6 Verification: Number of tasks created = ' + alerts.size());
    if (alerts.isEmpty()) {
        throw new IllegalArgumentException('Scenario 6 FAIL: Low Stock Alert Task was not created');
    }
    Task alert = alerts[0];
    System.debug('Scenario 6 Verification Details: Subject="' + alert.Subject + '", OwnerId=' + alert.OwnerId + ', Priority=' + alert.Priority + ', Status=' + alert.Status);
    if (!alert.Subject.contains('Low Stock Alert') || alert.OwnerId != invManager.Id || alert.Priority != 'High' || alert.Status != 'Not Started') {
        throw new IllegalArgumentException('Scenario 6 FAIL: Low Stock Alert Task properties or Assignee is incorrect');
    }
    System.debug('Scenario 6: PASSED');

    System.debug('===== E2E SEEDING & VERIFICATION SUCCESSFULLY COMPLETED =====');

} catch (Exception e) {
    System.debug('EXCEPTION: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
