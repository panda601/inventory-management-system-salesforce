// Query Profile
Profile standardPlatformProfile = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User' LIMIT 1];

// Query Roles
UserRole invManagerRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Inventory_Manager' LIMIT 1];
UserRole salesExecRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Sales_Executive' LIMIT 1];

// User 1: Inventory Manager
String invManagerUsername = 'backuproy0911.salesexec@inventory.app.com';
List<User> invManagerUsers = [SELECT Id FROM User WHERE Username = :invManagerUsername];
User invManager;

if (invManagerUsers.isEmpty()) {
    invManager = new User();
    invManager.FirstName = 'Inventory';
    invManager.LastName = 'Manager';
    invManager.Email = 'backuproy0911@gmail.com';
    invManager.Username = invManagerUsername;
    invManager.Alias = 'invmgr';
    invManager.ProfileId = standardPlatformProfile.Id;
    invManager.UserRoleId = invManagerRole.Id;
    invManager.EmailEncodingKey = 'UTF-8';
    invManager.LanguageLocaleKey = 'en_US';
    invManager.LocaleSidKey = 'en_US';
    invManager.TimeZoneSidKey = 'America/Los_Angeles';
    invManager.UserPermissionsSFContentUser = false;
    insert invManager;
    System.debug('Inventory Manager user created successfully!');
} else {
    invManager = invManagerUsers[0];
    invManager.UserRoleId = invManagerRole.Id;
    invManager.UserPermissionsSFContentUser = false;
    invManager.IsActive = true;
    update invManager;
    System.debug('Inventory Manager user updated successfully!');
}

// User 2: Sales Executive
String salesExecUsername = 'backuproy0911.invmgr@inventory.app.com';
List<User> salesExecUsers = [SELECT Id FROM User WHERE Username = :salesExecUsername];
User salesExec;

if (salesExecUsers.isEmpty()) {
    salesExec = new User();
    salesExec.FirstName = 'Sales';
    salesExec.LastName = 'Executive';
    salesExec.Email = 'backuproy0911@gmail.com';
    salesExec.Username = salesExecUsername;
    salesExec.Alias = 'salesex';
    salesExec.ProfileId = standardPlatformProfile.Id;
    salesExec.UserRoleId = salesExecRole.Id;
    salesExec.EmailEncodingKey = 'UTF-8';
    salesExec.LanguageLocaleKey = 'en_US';
    salesExec.LocaleSidKey = 'en_US';
    salesExec.TimeZoneSidKey = 'America/Los_Angeles';
    salesExec.UserPermissionsSFContentUser = false;
    insert salesExec;
    System.debug('Sales Executive user created successfully!');
} else {
    salesExec = salesExecUsers[0];
    salesExec.UserRoleId = salesExecRole.Id;
    salesExec.UserPermissionsSFContentUser = false;
    salesExec.IsActive = true;
    update salesExec;
    System.debug('Sales Executive user updated successfully!');
}
