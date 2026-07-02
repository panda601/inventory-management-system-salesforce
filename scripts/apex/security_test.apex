try {
    System.debug('===== STARTING ANONYMOUS SECURITY & SHARING AUDIT =====');

    // Get Users
    User invManager = [SELECT Id, Username FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];
    User salesExec = [SELECT Id, Username FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
    User adminUser = [SELECT Id, Username FROM User WHERE Username = '723145roy.6036123142ec@agentforce.com' LIMIT 1];

    System.debug('Inv Manager: ' + invManager.Id);
    System.debug('Sales Exec: ' + salesExec.Id);
    System.debug('Admin: ' + adminUser.Id);

    // Get records
    List<Product__c> prods = [SELECT Id, OwnerId, Name FROM Product__c];
    List<Supplier__c> supps = [SELECT Id, OwnerId, Name FROM Supplier__c];
    List<Purchase_Order__c> pos = [SELECT Id, OwnerId, Name FROM Purchase_Order__c];
    List<Sales_Order__c> sos = [SELECT Id, OwnerId, Name FROM Sales_Order__c];
    List<Return_Request__c> rrs = [SELECT Id, OwnerId, Name FROM Return_Request__c];
    List<Inventory_Transaction__c> txns = [SELECT Id, OwnerId, Name FROM Inventory_Transaction__c];

    System.debug('--- OBJECT CRUD AUDIT: SALES EXECUTIVE ---');
    // Forbidden objects (no access at all)
    Set<String> salesExecForbidden = new Set<String>{'Purchase_Order__c', 'Purchase_Order_Item__c'};
    // Read-only objects
    Set<String> salesExecReadOnly = new Set<String>{'Product__c', 'Supplier__c', 'Inventory_Transaction__c'};
    // Manageable objects
    Set<String> salesExecManage = new Set<String>{'Sales_Order__c', 'Sales_Order_Item__c', 'Return_Request__c'};

    List<ObjectPermissions> sePerms = [
        SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
        FROM ObjectPermissions
        WHERE ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :salesExec.Id)
    ];

    Boolean salesExecCrudPass = true;
    for (ObjectPermissions op : sePerms) {
        if (salesExecForbidden.contains(op.SObjectType)) {
            if (op.PermissionsRead || op.PermissionsCreate || op.PermissionsEdit || op.PermissionsDelete) {
                System.debug('FAIL: Sales Executive has permissions on forbidden object: ' + op.SObjectType);
                salesExecCrudPass = false;
            }
        }
        if (salesExecReadOnly.contains(op.SObjectType)) {
            if (op.PermissionsCreate || op.PermissionsEdit || op.PermissionsDelete) {
                System.debug('FAIL: Sales Executive has write/delete permissions on read-only object: ' + op.SObjectType);
                salesExecCrudPass = false;
            }
        }
    }
    if (salesExecCrudPass) {
        System.debug('PASS: Sales Executive CRUD constraints verified.');
    }

    System.debug('--- OBJECT CRUD AUDIT: INVENTORY MANAGER ---');
    // Allowed objects for management
    Set<String> mgrManage = new Set<String>{'Product__c', 'Supplier__c', 'Purchase_Order__c', 'Purchase_Order_Item__c', 'Return_Request__c', 'Inventory_Transaction__c'};
    List<ObjectPermissions> mgrPerms = [
        SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
        FROM ObjectPermissions
        WHERE ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :invManager.Id)
    ];

    Boolean mgrCrudPass = true;
    for (ObjectPermissions op : mgrPerms) {
        if (!mgrManage.contains(op.SObjectType)) {
            // Manager does not need to manage Sales Orders
            if (op.SObjectType == 'Sales_Order__c' && (op.PermissionsCreate || op.PermissionsDelete || op.PermissionsEdit)) {
                System.debug('FAIL: Inventory Manager can manage Sales_Order__c');
                mgrCrudPass = false;
            }
        }
    }
    if (mgrCrudPass) {
        System.debug('PASS: Inventory Manager CRUD constraints verified.');
    }

    System.debug('--- ROW-LEVEL VISIBILITY AUDIT: SALES EXECUTIVE ---');
    Boolean rowExecPass = true;
    
    // We check all Sales Orders
    for (Sales_Order__c so : sos) {
        List<UserRecordAccess> uraList = [
            SELECT RecordId, HasReadAccess, HasEditAccess
            FROM UserRecordAccess
            WHERE UserId = :salesExec.Id AND RecordId = :so.Id
            LIMIT 1
        ];
        if (!uraList.isEmpty()) {
            UserRecordAccess ura = uraList[0];
            if (so.OwnerId == salesExec.Id) {
                if (!ura.HasReadAccess) {
                    System.debug('FAIL: Sales Exec does NOT have read access to Sales Order owned by them: ' + so.Name);
                    rowExecPass = false;
                }
            } else {
                if (ura.HasReadAccess) {
                    System.debug('FAIL: Sales Exec has read access to Sales Order owned by another user: ' + so.Name + ' (OwnerId=' + so.OwnerId + ')');
                    rowExecPass = false;
                }
            }
        }
    }
    
    // Sales Exec should NOT see Purchase Orders
    for (Purchase_Order__c po : pos) {
        List<UserRecordAccess> uraList = [
            SELECT RecordId, HasReadAccess
            FROM UserRecordAccess
            WHERE UserId = :salesExec.Id AND RecordId = :po.Id
            LIMIT 1
        ];
        if (!uraList.isEmpty() && uraList[0].HasReadAccess) {
            System.debug('FAIL: Sales Exec has read access to Purchase Order: ' + po.Name);
            rowExecPass = false;
        }
    }

    if (rowExecPass) {
        System.debug('PASS: Sales Executive row-level sharing constraints verified.');
    }

    System.debug('===== ANONYMOUS SECURITY & SHARING AUDIT COMPLETED =====');

} catch (Exception e) {
    System.debug('EXCEPTION DURING AUDIT: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
