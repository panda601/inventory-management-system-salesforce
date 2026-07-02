try {
    System.debug('===== STARTING MANUAL RECORD SHARING =====');

    // 1. Get the users
    User invManager = [SELECT Id FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
    User salesExec = [SELECT Id FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];

    // 2. Query/Create a Supplier first since Supplier is required for Purchase Order
    Supplier__c supplier;
    List<Supplier__c> suppliers = [SELECT Id FROM Supplier__c WHERE Supplier_Name__c = 'Test Supplier Auto' LIMIT 1];
    if (suppliers.isEmpty()) {
        supplier = new Supplier__c(
            Name = 'Shared Supplier',
            Supplier_Name__c = 'Shared Supplier',
            Email__c = 'shared@supplier.com',
            Phone__c = '1234567890',
            Status__c = 'Active'
        );
        insert supplier;
    } else {
        supplier = suppliers[0];
    }

    // 3. Create a Purchase Order record (owned by the running Admin user)
    Purchase_Order__c po = new Purchase_Order__c(
        Supplier__c = supplier.Id,
        Order_Date__c = System.today(),
        Status__c = 'Draft'
    );
    insert po;
    System.debug('Created Purchase Order record: ' + po.Id);

    // 4. Create Purchase_Order__Share records for both users
    List<Purchase_Order__Share> shares = new List<Purchase_Order__Share>();

    // Share with Inventory Manager
    shares.add(new Purchase_Order__Share(
        ParentId = po.Id,
        UserOrGroupId = invManager.Id,
        AccessLevel = 'Read',
        RowCause = 'Manual'
    ));

    // Share with Sales Executive
    shares.add(new Purchase_Order__Share(
        ParentId = po.Id,
        UserOrGroupId = salesExec.Id,
        AccessLevel = 'Read',
        RowCause = 'Manual'
    ));

    insert shares;
    System.debug('Successfully shared Purchase Order record ' + po.Id + ' with both users!');

} catch (Exception e) {
    System.debug('SHARING EXCEPTION: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
