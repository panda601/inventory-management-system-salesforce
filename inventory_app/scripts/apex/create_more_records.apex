try {
    System.debug('===== SEEDING ADDITIONAL REALISTIC RECORDS =====');

    // Fetch users
    User invManager = [SELECT Id FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
    User salesExec = [SELECT Id FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];

    // Create New Suppliers
    Supplier__c appleSupp = new Supplier__c(
        Name = 'Apple Store Wholesale',
        Supplier_Name__c = 'Apple Store Wholesale',
        Email__c = 'wholesale@apple.com',
        Phone__c = '1-800-MY-APPLE',
        Address__c = '1 Infinite Loop, Cupertino, CA',
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Supplier__c officeSupp = new Supplier__c(
        Name = 'Apex Office Solutions',
        Supplier_Name__c = 'Apex Office Solutions',
        Email__c = 'sales@apexoffice.com',
        Phone__c = '555-0199',
        Address__c = '742 Evergreen Terrace, Springfield',
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    insert new List<Supplier__c>{appleSupp, officeSupp};

    // Create New Products
    Product__c sonyProd = new Product__c(
        Name = 'Sony WH-1000XM4',
        Product_Name__c = 'Sony WH-1000XM4 Headset',
        SKU__c = 'SONY-WH4',
        Category__c = 'Electronics',
        Price__c = 300.00,
        Current_Stock__c = 25,
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c samsungProd = new Product__c(
        Name = 'Samsung 27 Inch Monitor',
        Product_Name__c = 'Samsung 27 Inch Monitor',
        SKU__c = 'SAM-27M',
        Category__c = 'Electronics',
        Price__c = 250.00,
        Current_Stock__c = 8,
        Minimum_Stock__c = 12, // Low Stock!
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c ipadProd = new Product__c(
        Name = 'Apple iPad Air',
        Product_Name__c = 'Apple iPad Air',
        SKU__c = 'AP-IPAD-AIR',
        Category__c = 'Electronics',
        Price__c = 600.00,
        Current_Stock__c = 0, // Out of Stock!
        Minimum_Stock__c = 5,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c jacketProd = new Product__c(
        Name = 'Classic Leather Jacket',
        Product_Name__c = 'Classic Leather Jacket',
        SKU__c = 'CL-LJ-01',
        Category__c = 'Apparel',
        Price__c = 150.00,
        Current_Stock__c = 15,
        Minimum_Stock__c = 5,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c coffeeProd = new Product__c(
        Name = 'Organic Coffee Beans',
        Product_Name__c = 'Organic Coffee Beans (1kg)',
        SKU__c = 'ORG-COF-1',
        Category__c = 'Food',
        Price__c = 15.00,
        Current_Stock__c = 50,
        Minimum_Stock__c = 10,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    Product__c chairProd = new Product__c(
        Name = 'Ergonomic Desk Chair',
        Product_Name__c = 'Ergonomic Desk Chair',
        SKU__c = 'ERG-CH-01',
        Category__c = 'Home',
        Price__c = 200.00,
        Current_Stock__c = 3, // Low Stock!
        Minimum_Stock__c = 8,
        Status__c = 'Active',
        OwnerId = invManager.Id
    );
    insert new List<Product__c>{sonyProd, samsungProd, ipadProd, jacketProd, coffeeProd, chairProd};

    // Create Draft Purchase Order
    Purchase_Order__c poDraft = new Purchase_Order__c(
        Supplier__c = appleSupp.Id,
        Order_Date__c = System.today().addDays(-2),
        Status__c = 'Draft',
        OwnerId = invManager.Id
    );
    insert poDraft;
    Purchase_Order_Item__c poiDraft = new Purchase_Order_Item__c(
        Purchase_Order__c = poDraft.Id,
        Product__c = ipadProd.Id,
        Quantity__c = 10,
        Unit_Price__c = 450.00
    );
    insert poiDraft;

    // Create Approved Purchase Order
    Purchase_Order__c poApp = new Purchase_Order__c(
        Supplier__c = officeSupp.Id,
        Order_Date__c = System.today().addDays(-1),
        Status__c = 'Approved',
        OwnerId = invManager.Id
    );
    insert poApp;
    Purchase_Order_Item__c poiApp = new Purchase_Order_Item__c(
        Purchase_Order__c = poApp.Id,
        Product__c = chairProd.Id,
        Quantity__c = 15,
        Unit_Price__c = 120.00
    );
    insert poiApp;

    // Create Draft Sales Order
    Sales_Order__c soDraft = new Sales_Order__c(
        Customer_Name__c = 'Jane Miller',
        Order_Date__c = System.today(),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert soDraft;
    Sales_Order_Item__c soiDraft = new Sales_Order_Item__c(
        Sales_Order__c = soDraft.Id,
        Product__c = sonyProd.Id,
        Quantity__c = 1,
        Unit_Price__c = 300.00
    );
    insert soiDraft;

    // Create Confirmed Sales Order
    Sales_Order__c soConf = new Sales_Order__c(
        Customer_Name__c = 'John Smith',
        Order_Date__c = System.today().addDays(-3),
        Status__c = 'Draft',
        OwnerId = salesExec.Id
    );
    insert soConf;
    Sales_Order_Item__c soiConf = new Sales_Order_Item__c(
        Sales_Order__c = soConf.Id,
        Product__c = jacketProd.Id,
        Quantity__c = 3,
        Unit_Price__c = 150.00
    );
    insert soiConf;
    soConf.Status__c = 'Confirmed';
    update soConf;

    System.debug('===== ADDITIONAL RECORDS SEEDED SUCCESSFULLY =====');
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
