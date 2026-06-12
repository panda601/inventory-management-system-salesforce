// Assign Student_App_Access permission set to all System Administrator profile users
PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Student_App_Access' LIMIT 1];
List<User> admins = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true];
Map<Id, PermissionSetAssignment> existingMap = new Map<Id, PermissionSetAssignment>();
for(PermissionSetAssignment psa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id]) {
    existingMap.put(psa.AssigneeId, psa);
}
List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
for(User u : admins) {
    if(!existingMap.containsKey(u.Id)) {
        assignments.add(new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u.Id));
    }
}
if(!assignments.isEmpty()) {
    insert assignments;
    System.debug('SUCCESS: Assigned Student_App_Access to ' + assignments.size() + ' admin user(s).');
} else {
    System.debug('Student_App_Access already assigned to all System Administrator users.');
}
