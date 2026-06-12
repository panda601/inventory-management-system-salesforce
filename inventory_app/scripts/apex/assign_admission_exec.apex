try {
    System.debug('===== ASSIGNING ADMISSION EXECUTIVE ACCESS =====');

    // 1. Get the Sales Executive user
    User salesExec = [SELECT Id FROM User WHERE Username = 'backuproy0911.invmgr@inventory.app.com' LIMIT 1];

    // 2. Get the Admission Executive permission set
    PermissionSet admissionExecPS = [SELECT Id FROM PermissionSet WHERE Name = 'Admission_Executive_Access' LIMIT 1];

    // 3. Check for existing assignment
    List<PermissionSetAssignment> exist = [
        SELECT Id FROM PermissionSetAssignment 
        WHERE AssigneeId = :salesExec.Id AND PermissionSetId = :admissionExecPS.Id
    ];

    if (exist.isEmpty()) {
        insert new PermissionSetAssignment(
            AssigneeId = salesExec.Id,
            PermissionSetId = admissionExecPS.Id
        );
        System.debug('Successfully assigned Admission_Executive_Access to backuproy0911.invmgr@inventory.app.com!');
    } else {
        System.debug('Admission_Executive_Access is already assigned to this user.');
    }

} catch (Exception e) {
    System.debug('ASSIGNMENT EXCEPTION: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
