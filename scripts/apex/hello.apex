PermissionSet adminPS = [SELECT Id FROM PermissionSet WHERE Name = 'Admin_Access' LIMIT 1];
User targetAdmin = [SELECT Id FROM User WHERE Username = '723145roy.6036123142ec@agentforce.com' LIMIT 1];
List<PermissionSetAssignment> exist = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :targetAdmin.Id AND PermissionSetId = :adminPS.Id];
if (exist.isEmpty()) {
    insert new PermissionSetAssignment(AssigneeId = targetAdmin.Id, PermissionSetId = adminPS.Id);
    System.debug('Admin_Access assigned to target admin successfully.');
} else {
    System.debug('Admin_Access already assigned to target admin.');
}