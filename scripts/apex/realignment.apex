// 1. Get User Roles
UserRole salesExecRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Sales_Executive' LIMIT 1];
UserRole invMgrRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Inventory_Manager' LIMIT 1];

// 2. Get Users
User salesExecUser = [SELECT Id, UserRoleId FROM User WHERE Username = 'backuproy0911.salesexec@inventory.app.com' LIMIT 1];
User invMgrUser = [SELECT Id, UserRoleId FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];

// Update Roles
salesExecUser.UserRoleId = salesExecRole.Id;
invMgrUser.UserRoleId = invMgrRole.Id;
update new List<User>{salesExecUser, invMgrUser};
System.debug('User roles updated successfully.');

// 3. Remove Swapped Permission Sets
List<PermissionSetAssignment> assignmentsToDelete = [
    SELECT Id FROM PermissionSetAssignment 
    WHERE (AssigneeId = :salesExecUser.Id AND PermissionSet.Name = 'Inventory_Manager_Access')
       OR (AssigneeId = :invMgrUser.Id AND PermissionSet.Name = 'Sales_Executive_Access')
];
if (!assignmentsToDelete.isEmpty()) {
    delete assignmentsToDelete;
    System.debug('Swapped permission set assignments deleted.');
}

// 4. Assign Correct Permission Sets
PermissionSet salesExecPS = [SELECT Id FROM PermissionSet WHERE Name = 'Sales_Executive_Access' LIMIT 1];
PermissionSet invMgrPS = [SELECT Id FROM PermissionSet WHERE Name = 'Inventory_Manager_Access' LIMIT 1];

List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
// Check if they are already assigned
List<PermissionSetAssignment> existingSalesExec = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :salesExecUser.Id AND PermissionSetId = :salesExecPS.Id];
if (existingSalesExec.isEmpty()) {
    newAssignments.add(new PermissionSetAssignment(AssigneeId = salesExecUser.Id, PermissionSetId = salesExecPS.Id));
}

List<PermissionSetAssignment> existingInvMgr = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :invMgrUser.Id AND PermissionSetId = :invMgrPS.Id];
if (existingInvMgr.isEmpty()) {
    newAssignments.add(new PermissionSetAssignment(AssigneeId = invMgrUser.Id, PermissionSetId = invMgrPS.Id));
}

if (!newAssignments.isEmpty()) {
    insert newAssignments;
    System.debug('New permission set assignments inserted.');
}
