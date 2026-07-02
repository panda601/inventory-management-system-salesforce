try {
    System.debug('===== STARTING E2E SEEDING & VERIFICATION =====');

    // Fetch users
    User invManager = [SELECT Id, Username FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];
    User salesExec = [SELECT Id, Username FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
    User adminUser = [SELECT Id, Username FROM User WHERE Username = '723145roy.6036123142ec@agentforce.com' LIMIT 1];

    System.debug('Inventory Manager User: ' + invManager.Username + ' (Id: ' + invManager.Id + ')');
    System.debug('Sales Executive User: ' + salesExec.Username + ' (Id: ' + salesExec.Id + ')');
    System.debug('Admin User: ' + adminUser.Username + ' (Id: ' + adminUser.Id + ')');

    // 1. Clear old data in dependency order
    delete [SELECT Id FROM Inventory_Transaction__c];
    delete [SELECT Id FROM Return_Request__c];
    delete [SELECT Id FROM Sales_Order_Item__c];
    delete [SELECT Id FROM Sales_Order__c];
    delete [SELECT Id FROM Purchase_Order_Item__c];
    delete [SELECT Id FROM Purchase_Order__c];
    delete [SELECT Id FROM Product__c];
    delete [SELECT Id FROM Supplier__c];
    delete [SELECT Id FROM Task WHERE Subject LIKE 'Low Stock Alert%'];
    System.debug('Old data successfully cleared.');

    // 2. Seed 5 Suppliers (Owned by Manager)
    Supplier__c dellSupp = new Supplier__c(
        Name = 'Dell Technologies',
        Supplier_Name__c = 'Dell Technologies',
        Status__c = 'Active',
        Email__c = 'support@dell.com',
        Phone__c = '+1-800-888-3355',
        Address__c = 'One Dell Way, Round Rock, TX 78682',
        OwnerId = invManager.Id
    );
    Supplier__c hpSupp = new Supplier__c(
        Name = 'HP India',
        Supplier_Name__c = 'HP India',
        Status__c = 'Active',
        Email__c = 'contact@hp.com',
        Phone__c = '+91-80-2512-9000',
        Address__c = 'No. 24, Salarpuria Arena, Hosur Road, Bangalore, KA 560030',
        OwnerId = invManager.Id
    );
    Supplier__c lenovoSupp = new Supplier__c(
        Name = 'Lenovo India',
        Supplier_Name__c = 'Lenovo India',
        Status__c = 'Active',
        Email__c = 'info@lenovo.com',
        Phone__c = '+91-80-3053-3000',
        Address__c = 'Ferns Icon, Level 2, Outer Ring Road, Bangalore, KA 560037',
        OwnerId = invManager.Id
    );
    Supplier__c logitechSupp = new Supplier__c(
        Name = 'Logitech Pvt Ltd',
        Supplier_Name__c = 'Logitech Pvt Ltd',
        Status__c = 'Active',
        Email__c = 'sales@logitech.com',
        Phone__c = '+41-21-863-5111',
        Address__c = 'EPFL - Innovation Park, Daniel Borel Innovation Center, Lausanne 1015',
        OwnerId = invManager.Id
    );
    Supplier__c samsungSupp = new Supplier__c(
        Name = 'Samsung India',
        Supplier_Name__c = 'Samsung India',
        Status__c = 'Active',
        Email__c = 'helpdesk@samsung.com',
        Phone__c = '+91-124-488-8000',
        Address__c = '6th Floor, DLF Centre, Sansad Marg, New Delhi, DL 110001',
        OwnerId = invManager.Id
    );
    List<Supplier__c> suppliers = new List<Supplier__c>{dellSupp, hpSupp, lenovoSupp, logitechSupp, samsungSupp};
    insert suppliers;
    System.debug('Seeded 5 Suppliers.');

    // 3. Seed 6 Products (Owned by Manager)
    // We adjust starting stocks so that after the transaction flows execute, the final stocks match the target levels.
    Product__c prod1 = new Product__c(
        Name = 'Dell Latitude 5440',
        Product_Name__c = 'Dell Latitude 5440',
        SKU__c = 'DELL-LAT-5440',
        Category__c = 'Electronics',
        Price__c = 60000.00,
        Current_Stock__c = 22, // Target is 25. PO (+5) and SO (-2) -> 25.
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id,
        Product_Image__c = 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=300&q=80'
    );
    Product__c prod2 = new Product__c(
        Name = 'HP ProBook 450',
        Product_Name__c = 'HP ProBook 450',
        SKU__c = 'HP-PRO-450',
        Category__c = 'Electronics',
        Price__c = 55000.00,
        Current_Stock__c = 18, // Target is 18. PO (+3) and SO (-2) -> 18. (Return replace sent has net change 0)
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id,
        Product_Image__c = 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=300&q=80'
    );
    Product__c prod3 = new Product__c(
        Name = 'Lenovo ThinkPad E14',
        Product_Name__c = 'Lenovo ThinkPad E14',
        SKU__c = 'LEN-E14',
        Category__c = 'Electronics',
        Price__c = 50000.00,
        Current_Stock__c = 12, // Target is 12.
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id,
        Product_Image__c = 'https://images.unsplash.com/photo-1618424181497-157f25b6ddd5?w=300&q=80'
    );
    Product__c prod4 = new Product__c(
        Name = 'Dell Keyboard',
        Product_Name__c = 'Dell Keyboard',
        SKU__c = 'DELL-KB-1',
        Category__c = 'Electronics',
        Price__c = 1500.00,
        Current_Stock__c = 13, // Target is 10. SO (-3) -> 10.
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id,
        Product_Image__c = 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=300&q=80'
    );
    Product__c prod5 = new Product__c(
        Name = 'Logitech Mouse',
        Product_Name__c = 'Logitech Mouse',
        SKU__c = 'LOGI-MS-1',
        Category__c = 'Electronics',
        Price__c = 1000.00,
        Current_Stock__c = 35, // Target is 30. SO (-5) -> 30. (Return submitted has net change 0)
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id,
        Product_Image__c = 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=300&q=80'
    );
    Product__c prod6 = new Product__c(
        Name = 'Samsung Monitor',
        Product_Name__c = 'Samsung Monitor',
        SKU__c = 'SAM-MON-24',
        Category__c = 'Electronics',
        Price__c = 15000.00,
        Current_Stock__c = 7, // Target is 8. Return Repair (+1) -> 8.
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id,
        Product_Image__c = 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=300&q=80'
    );
    List<Product__c> products = new List<Product__c>{prod1, prod2, prod3, prod4, prod5, prod6};
    insert products;
    System.debug('Seeded 6 Products.');

    // Search and update other products that might exist
    List<Product__c> extraProducts = [SELECT Id, Name FROM Product__c WHERE Name IN ('Mac Book', 'Test Auto Product 1')];
    for (Product__c p : extraProducts) {
        if (p.Name == 'Mac Book') {
            p.Product_Image__c = 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=300&q=80';
        }
        // Test Auto Product 1 has no image to verify fallback.
    }
    if (!extraProducts.isEmpty()) {
        update extraProducts;
    }

    // 4. Seed 5 Purchase Orders
    // PO 1: Dell Technologies - Received Qty 5
    Purchase_Order__c po1 = new Purchase_Order__c(
        Supplier__c = dellSupp.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = invManager.Id
    );
    insert po1;
    Purchase_Order_Item__c poi1 = new Purchase_Order_Item__c(
        Purchase_Order__c = po1.Id,
        Product__c = prod1.Id,
        Quantity__c = 5,
        Unit_Price__c = 45000.00
    );
    insert poi1;
    po1.Status__c = 'Received';
    update po1; // Triggers flow to update stock (+5) and creates transaction

    // PO 2: HP India - Received Qty 3
    Purchase_Order__c po2 = new Purchase_Order__c(
        Supplier__c = hpSupp.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = invManager.Id
    );
    insert po2;
    Purchase_Order_Item__c poi2 = new Purchase_Order_Item__c(
        Purchase_Order__c = po2.Id,
        Product__c = prod2.Id,
        Quantity__c = 3,
        Unit_Price__c = 40000.00
    );
    insert poi2;
    po2.Status__c = 'Received';
    update po2; // Triggers flow to update stock (+3) and creates transaction

    // PO 3: Lenovo India - Ordered (Approved) Qty 10
    Purchase_Order__c po3 = new Purchase_Order__c(
        Supplier__c = lenovoSupp.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = invManager.Id
    );
    insert po3;
    Purchase_Order_Item__c poi3 = new Purchase_Order_Item__c(
        Purchase_Order__c = po3.Id,
        Product__c = prod3.Id,
        Quantity__c = 10,
        Unit_Price__c = 35000.00
    );
    insert poi3;
    po3.Status__c = 'Approved';
    update po3; // Transitions to Approved (Ordered state, no stock change)

    // PO 4: Logitech Pvt Ltd - Draft Qty 20
    Purchase_Order__c po4 = new Purchase_Order__c(
        Supplier__c = logitechSupp.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = invManager.Id
    );
    insert po4;
    Purchase_Order_Item__c poi4 = new Purchase_Order_Item__c(
        Purchase_Order__c = po4.Id,
        Product__c = prod5.Id,
        Quantity__c = 20,
        Unit_Price__c = 450.00
    );
    insert poi4;

    // PO 5: Samsung India - Draft Qty 5
    Purchase_Order__c po5 = new Purchase_Order__c(
        Supplier__c = samsungSupp.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = invManager.Id
    );
    insert po5;
    Purchase_Order_Item__c poi5 = new Purchase_Order_Item__c(
        Purchase_Order__c = po5.Id,
        Product__c = prod6.Id,
        Quantity__c = 5,
        Unit_Price__c = 9000.00
    );
    insert poi5;
    System.debug('Seeded 5 Purchase Orders.');

    // 5. Seed 6 Sales Orders (Owned by Sales Executive)
    // SO 1: Dell Latitude Confirmed (Approved) Qty 2
    Sales_Order__c so1 = new Sales_Order__c(
        Customer_Name__c = 'John Doe',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert so1;
    Sales_Order_Item__c soi1 = new Sales_Order_Item__c(
        Sales_Order__c = so1.Id,
        Product__c = prod1.Id,
        Quantity__c = 2,
        Unit_Price__c = 60000.00
    );
    insert soi1;
    so1.Status__c = 'Confirmed';
    update so1; // Triggers flow to update stock (-2) and creates transaction

    // SO 2: HP ProBook Delivered (Shipped) Qty 2
    Sales_Order__c so2 = new Sales_Order__c(
        Customer_Name__c = 'Jane Smith',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert so2;
    Sales_Order_Item__c soi2 = new Sales_Order_Item__c(
        Sales_Order__c = so2.Id,
        Product__c = prod2.Id,
        Quantity__c = 2,
        Unit_Price__c = 55000.00
    );
    insert soi2;
    so2.Status__c = 'Confirmed';
    update so2; // Stock out trigger
    so2.Status__c = 'Delivered';
    update so2; // Move to Delivered

    // SO 3: Lenovo ThinkPad Draft Qty 1
    Sales_Order__c so3 = new Sales_Order__c(
        Customer_Name__c = 'Bob Johnson',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert so3;
    Sales_Order_Item__c soi3 = new Sales_Order_Item__c(
        Sales_Order__c = so3.Id,
        Product__c = prod3.Id,
        Quantity__c = 1,
        Unit_Price__c = 50000.00
    );
    insert soi3;

    // SO 4: Dell Keyboard Confirmed (Approved) Qty 3
    Sales_Order__c so4 = new Sales_Order__c(
        Customer_Name__c = 'Alice Williams',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert so4;
    Sales_Order_Item__c soi4 = new Sales_Order_Item__c(
        Sales_Order__c = so4.Id,
        Product__c = prod4.Id,
        Quantity__c = 3,
        Unit_Price__c = 1500.00
    );
    insert soi4;
    so4.Status__c = 'Confirmed';
    update so4; // Stock out trigger

    // SO 5: Logitech Mouse Delivered (Shipped) Qty 5
    Sales_Order__c so5 = new Sales_Order__c(
        Customer_Name__c = 'Charlie Brown',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert so5;
    Sales_Order_Item__c soi5 = new Sales_Order_Item__c(
        Sales_Order__c = so5.Id,
        Product__c = prod5.Id,
        Quantity__c = 5,
        Unit_Price__c = 1000.00
    );
    insert soi5;
    so5.Status__c = 'Confirmed';
    update so5; // Stock out trigger
    so5.Status__c = 'Delivered';
    update so5; // Move to Delivered

    // SO 6: Samsung Monitor Draft Qty 2
    Sales_Order__c so6 = new Sales_Order__c(
        Customer_Name__c = 'David Miller',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert so6;
    Sales_Order_Item__c soi6 = new Sales_Order_Item__c(
        Sales_Order__c = so6.Id,
        Product__c = prod6.Id,
        Quantity__c = 2,
        Unit_Price__c = 15000.00
    );
    insert soi6;
    System.debug('Seeded 6 Sales Orders.');

    // 6. Seed 3 Return Requests (Owned by Sales Executive)
    // Return Request 1: Logitech Mouse Qty 1 - Submitted
    Return_Request__c rr1 = new Return_Request__c(
        Sales_Order__c = so5.Id,
        Sales_Order_Item__c = soi5.Id,
        Customer_Name__c = 'Charlie Brown',
        Customer_Email__c = 'charlie@mouse.com',
        Product__c = prod5.Id,
        Quantity__c = 1,
        Reason__c = 'Damaged Product',
        Comments__c = 'Left click not working',
        Status__c = 'Submitted',
        Requested_Date__c = System.today(),
        OwnerId = salesExec.Id
    );
    insert rr1;

    // Return Request 2: Samsung Monitor Qty 1 - Approved (Repair)
    Return_Request__c rr2 = new Return_Request__c(
        Sales_Order__c = so6.Id, // Link to monitor order
        Sales_Order_Item__c = soi6.Id,
        Customer_Name__c = 'David Miller',
        Customer_Email__c = 'david@monitor.com',
        Product__c = prod6.Id,
        Quantity__c = 1,
        Reason__c = 'Defective',
        Comments__c = 'Color bleeding on right side',
        Status__c = 'Submitted',
        Requested_Date__c = System.today(),
        OwnerId = salesExec.Id
    );
    insert rr2;
    // Approve for Repair using controller logic simulation
    rr2.Resolution_Type__c = 'Repair';
    rr2.Status__c = 'Approved';
    rr2.Processed_Date__c = System.today();
    rr2.Processed_By__c = invManager.Id;
    update rr2; // Runs trigger (+1 stock, Adjustment txn) and flow (status Under Inspection)

    // Return Request 3: HP ProBook Qty 1 - Approved (Replacement) -> Replacement Sent
    Return_Request__c rr3 = new Return_Request__c(
        Sales_Order__c = so2.Id,
        Sales_Order_Item__c = soi2.Id,
        Customer_Name__c = 'Jane Smith',
        Customer_Email__c = 'jane@probook.com',
        Product__c = prod2.Id,
        Quantity__c = 1,
        Reason__c = 'Damaged Product',
        Comments__c = 'Laptop shell cracked',
        Status__c = 'Submitted',
        Requested_Date__c = System.today(),
        OwnerId = salesExec.Id
    );
    insert rr3;
    // Approve for Replacement
    rr3.Resolution_Type__c = 'Replacement';
    rr3.Status__c = 'Approved';
    rr3.Processed_Date__c = System.today();
    rr3.Processed_By__c = invManager.Id;
    update rr3; // Trigger (+1 stock, Adjustment txn) and Flow (-1 stock, Stock Out txn, Status -> Replacement Sent)
    System.debug('Seeded 3 Return Requests.');

    // 7. Verification checks to confirm correct stock levels and transaction records
    System.debug('Verifying final stock levels...');
    Map<String, Decimal> expectedStocks = new Map<String, Decimal>{
        'DELL-LAT-5440' => 25,
        'HP-PRO-450' => 18,
        'LEN-E14' => 12,
        'DELL-KB-1' => 10,
        'LOGI-MS-1' => 30,
        'SAM-MON-24' => 8
    };

    for (Product__c p : [SELECT SKU__c, Current_Stock__c FROM Product__c]) {
        if (expectedStocks.containsKey(p.SKU__c)) {
            Decimal expected = expectedStocks.get(p.SKU__c);
            System.debug('Product ' + p.SKU__c + ': Current Stock = ' + p.Current_Stock__c + ' (Expected: ' + expected + ')');
            if (p.Current_Stock__c != expected) {
                throw new IllegalArgumentException('E2E Verification FAIL: Product ' + p.SKU__c + ' stock mismatch! Expected ' + expected + ', got ' + p.Current_Stock__c);
            }
        }
    }

    System.debug('===== E2E SEEDING & VERIFICATION SUCCESSFULLY COMPLETED =====');

} catch (Exception e) {
    System.debug('EXCEPTION DURING SEEDING: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
