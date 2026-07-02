// Verify Product Creation
Product__c prod = new Product__c();
prod.Name = 'Test Laptop';
prod.Product_Name__c = 'Test Laptop Pro';
prod.SKU__c = 'SKU-TEST-100';
prod.Category__c = 'Electronics';
prod.Price__c = 1200.00;
prod.Current_Stock__c = 50;
prod.Minimum_Stock__c = 10;
prod.Status__c = 'Active';
insert prod;
System.debug('Product__c successfully created! Id: ' + prod.Id);

// Verify Supplier Creation
Supplier__c supp = new Supplier__c();
supp.Name = 'Test Supplier';
supp.Supplier_Name__c = 'Test Supplier Inc';
supp.Email__c = 'supplier@test.com';
supp.Phone__c = '1234567890';
supp.Address__c = '123 Test St';
supp.Status__c = 'Active';
insert supp;
System.debug('Supplier__c successfully created! Id: ' + supp.Id);

// Verify Purchase Order Creation (Supplier -> Purchase Order Relationship)
Purchase_Order__c po = new Purchase_Order__c();
po.Supplier__c = supp.Id;
po.Order_Date__c = System.today();
po.Status__c = 'Draft';
insert po;
System.debug('Purchase_Order__c successfully created! Id: ' + po.Id);

// Verify Purchase Order Item Creation (PO & Product Relationships)
Purchase_Order_Item__c poi = new Purchase_Order_Item__c();
poi.Purchase_Order__c = po.Id;
poi.Product__c = prod.Id;
poi.Quantity__c = 10;
poi.Unit_Price__c = 1000.00;
insert poi;
System.debug('Purchase_Order_Item__c successfully created! Id: ' + poi.Id);

// Verify Sales Order Creation
Sales_Order__c so = new Sales_Order__c();
so.Customer_Name__c = 'John Customer';
so.Order_Date__c = System.today();
so.Status__c = 'Draft';
so.Total_Amount__c = 150.00;
insert so;
System.debug('Sales_Order__c successfully created! Id: ' + so.Id);

// Verify Inventory Transaction Creation (Product Relationship)
Inventory_Transaction__c txn = new Inventory_Transaction__c();
txn.Product__c = prod.Id;
txn.Transaction_Type__c = 'Stock In';
txn.Quantity__c = 5;
txn.Transaction_Date__c = System.now();
insert txn;
System.debug('Inventory_Transaction__c successfully created! Id: ' + txn.Id);

// Perform Clean Up (Delete created records)
delete txn;
delete so;
delete poi;
delete po;
delete supp;
delete prod;
System.debug('UAT Verification and cleanup complete. Phase 2 validation PASSED!');
