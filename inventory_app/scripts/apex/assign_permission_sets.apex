// Get Permission Sets
PermissionSet invManagerPS = [SELECT Id FROM PermissionSet WHERE Name = 'Inventory_Manager_Access' LIMIT 1];
PermissionSet salesExecPS = [SELECT Id FROM PermissionSet WHERE Name = 'Sales_Executive_Access' LIMIT 1];
PermissionSet adminPS = [SELECT Id FROM PermissionSet WHERE Name = 'Admin_Access' LIMIT 1];

// Get Users
User invManager = [SELECT Id FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
User salesExec = [SELECT Id FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];
User adminUser = [SELECT Id FROM User WHERE Username = '723145roy.6036123142ec@agentforce.com' LIMIT 1];

// Clean up old incorrect assignments first
List<PermissionSetAssignment> oldAssignments = [
    SELECT Id FROM PermissionSetAssignment 
    WHERE (AssigneeId = :invManager.Id AND PermissionSetId = :salesExecPS.Id)
       OR (AssigneeId = :salesExec.Id AND PermissionSetId = :invManagerPS.Id)
];
if (!oldAssignments.isEmpty()) {
    delete oldAssignments;
    System.debug('Removed old incorrect permission set assignments.');
}

List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

// Check for existing assignment for Inventory Manager (salesexec username)
List<PermissionSetAssignment> existInv = [
    SELECT Id FROM PermissionSetAssignment 
    WHERE AssigneeId = :invManager.Id AND PermissionSetId = :invManagerPS.Id
];
if (existInv.isEmpty()) {
    assignments.add(new PermissionSetAssignment(
        AssigneeId = invManager.Id,
        PermissionSetId = invManagerPS.Id
    ));
}

// Check for existing assignment for Sales Executive (invmgr username)
List<PermissionSetAssignment> existSales = [
    SELECT Id FROM PermissionSetAssignment 
    WHERE AssigneeId = :salesExec.Id AND PermissionSetId = :salesExecPS.Id
];
if (existSales.isEmpty()) {
    assignments.add(new PermissionSetAssignment(
        AssigneeId = salesExec.Id,
        PermissionSetId = salesExecPS.Id
    ));
}

// Check for existing assignment for Admin
List<PermissionSetAssignment> existAdmin = [
    SELECT Id FROM PermissionSetAssignment 
    WHERE AssigneeId = :adminUser.Id AND PermissionSetId = :adminPS.Id
];
if (existAdmin.isEmpty()) {
    assignments.add(new PermissionSetAssignment(
        AssigneeId = adminUser.Id,
        PermissionSetId = adminPS.Id
    ));
}

if (!assignments.isEmpty()) {
    insert assignments;
    System.debug('Permission sets successfully assigned to users!');
} else {
    System.debug('All permission sets are already assigned.');
}
