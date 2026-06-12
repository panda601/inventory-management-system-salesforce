try {
    System.debug('===== ASSIGNING RECORD OWNERSHIP =====');

    // 1. Get the users
    User invManager = [SELECT Id FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
    User salesExec = [SELECT Id FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];

    // 2. Assign Products
    List<Product__c> products = [SELECT Id, OwnerId FROM Product__c];
    for (Product__c p : products) {
        p.OwnerId = invManager.Id;
    }
    update products;
    System.debug('Updated ' + products.size() + ' Products ownership to Inventory Manager.');

    // 3. Assign Suppliers
    List<Supplier__c> suppliers = [SELECT Id, OwnerId FROM Supplier__c];
    for (Supplier__c s : suppliers) {
        s.OwnerId = invManager.Id;
    }
    update suppliers;
    System.debug('Updated ' + suppliers.size() + ' Suppliers ownership to Inventory Manager.');

    // 4. Assign Purchase Orders
    List<Purchase_Order__c> pos = [SELECT Id, OwnerId FROM Purchase_Order__c];
    for (Purchase_Order__c po : pos) {
        po.OwnerId = invManager.Id;
    }
    update pos;
    System.debug('Updated ' + pos.size() + ' Purchase Orders ownership to Inventory Manager.');

    // 5. Assign Inventory Transactions
    List<Inventory_Transaction__c> txns = [SELECT Id, OwnerId FROM Inventory_Transaction__c];
    for (Inventory_Transaction__c t : txns) {
        t.OwnerId = invManager.Id;
    }
    update txns;
    System.debug('Updated ' + txns.size() + ' Inventory Transactions ownership to Inventory Manager.');

    // 6. Assign Sales Orders
    List<Sales_Order__c> sos = [SELECT Id, OwnerId FROM Sales_Order__c];
    for (Sales_Order__c so : sos) {
        so.OwnerId = salesExec.Id;
    }
    update sos;
    System.debug('Updated ' + sos.size() + ' Sales Orders ownership to Sales Executive.');

    System.debug('===== RECORD OWNERSHIP ASSIGNMENT COMPLETED SUCCESSFULLY =====');

} catch (Exception e) {
    System.debug('ASSIGNMENT EXCEPTION: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
