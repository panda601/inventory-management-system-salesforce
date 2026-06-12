try {
    System.debug('===== STARTING SEED SALES EXEC APPLICATIONS =====');

    String salesExecUsername = 'backuproy0911.invmgr@inventory.app.com';
    User salesExec = [SELECT Id FROM User WHERE Username = :salesExecUsername LIMIT 1];

    // Ensure Sales Executive and Admission Executive permission sets are assigned
    List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();

    PermissionSet salesExecPS = [SELECT Id FROM PermissionSet WHERE Name = 'Sales_Executive_Access' LIMIT 1];
    List<PermissionSetAssignment> existSales = [
        SELECT Id FROM PermissionSetAssignment 
        WHERE AssigneeId = :salesExec.Id AND PermissionSetId = :salesExecPS.Id
    ];
    if (existSales.isEmpty()) {
        newAssignments.add(new PermissionSetAssignment(
            AssigneeId = salesExec.Id,
            PermissionSetId = salesExecPS.Id
        ));
    }

    PermissionSet admissionExecPS = [SELECT Id FROM PermissionSet WHERE Name = 'Admission_Executive_Access' LIMIT 1];
    List<PermissionSetAssignment> existAdm = [
        SELECT Id FROM PermissionSetAssignment 
        WHERE AssigneeId = :salesExec.Id AND PermissionSetId = :admissionExecPS.Id
    ];
    if (existAdm.isEmpty()) {
        newAssignments.add(new PermissionSetAssignment(
            AssigneeId = salesExec.Id,
            PermissionSetId = admissionExecPS.Id
        ));
    }

    if (!newAssignments.isEmpty()) {
        insert newAssignments;
        System.debug('Assigned missing permission sets to Sales Executive.');
    }

    // Find Course
    Course__c course = [SELECT Id, Name, Fees__c FROM Course__c WHERE Name = 'Salesforce Admin' OR Course_Code__c = 'SA-1' LIMIT 1];
    System.debug('Target course found: ' + course.Name + ' (' + course.Id + ')');

    // Clean up existing applications with the test emails first to prevent duplicate rule block
    Set<String> emails = new Set<String>{
        'john.doe.sa@example.com',
        'jane.doe.sa@example.com',
        'alex.smith.sa@example.com'
    };
    
    // Clean up payments first
    List<Payment__c> oldPayments = [SELECT Id FROM Payment__c WHERE Student_Application__r.Email__c IN :emails];
    if (!oldPayments.isEmpty()) {
        delete oldPayments;
        System.debug('Cleaned up old payments.');
    }

    // Clean up admissions
    List<Admission__c> oldAdmissions = [SELECT Id FROM Admission__c WHERE Student_Application__r.Email__c IN :emails];
    if (!oldAdmissions.isEmpty()) {
        delete oldAdmissions;
        System.debug('Cleaned up old admissions.');
    }

    // Query related documents first to prevent deleting restricted children issues if any
    List<Document__c> oldDocs = [SELECT Id FROM Document__c WHERE Student_Application__r.Email__c IN :emails];
    if (!oldDocs.isEmpty()) {
        delete oldDocs;
        System.debug('Cleaned up old documents.');
    }

    List<Student_Application__c> oldApps = [SELECT Id FROM Student_Application__c WHERE Email__c IN :emails];
    if (!oldApps.isEmpty()) {
        delete oldApps;
        System.debug('Cleaned up old test applications.');
    }

    // Create 3 new student applications
    Student_Application__c app1 = new Student_Application__c(
        First_Name__c = 'John',
        Last_Name__c = 'Doe',
        Email__c = 'john.doe.sa@example.com',
        Date_of_Birth__c = Date.newInstance(2000, 1, 1),
        Applied_Course__c = course.Id,
        Application_Status__c = 'Draft',
        OwnerId = salesExec.Id
    );

    Student_Application__c app2 = new Student_Application__c(
        First_Name__c = 'Jane',
        Last_Name__c = 'Doe',
        Email__c = 'jane.doe.sa@example.com',
        Date_of_Birth__c = Date.newInstance(2001, 2, 2),
        Applied_Course__c = course.Id,
        Application_Status__c = 'Submitted',
        OwnerId = salesExec.Id
    );

    Student_Application__c app3 = new Student_Application__c(
        First_Name__c = 'Alex',
        Last_Name__c = 'Smith',
        Email__c = 'alex.smith.sa@example.com',
        Date_of_Birth__c = Date.newInstance(1999, 12, 31),
        Applied_Course__c = course.Id,
        Application_Status__c = 'Draft',
        OwnerId = salesExec.Id
    );

    List<Student_Application__c> apps = new List<Student_Application__c>{app1, app2, app3};
    insert apps;
    System.debug('Inserted 3 Student Applications.');

    // Create Documents
    List<Document__c> docs = new List<Document__c>();
    for (Student_Application__c app : apps) {
        docs.add(new Document__c(
            Name = app.First_Name__c + ' ' + app.Last_Name__c + ' ID Proof',
            Student_Application__c = app.Id,
            Document_Type__c = 'Identity Proof',
            Verification_Status__c = 'Verified'
        ));
        docs.add(new Document__c(
            Name = app.First_Name__c + ' ' + app.Last_Name__c + ' Academic Transcript',
            Student_Application__c = app.Id,
            Document_Type__c = 'Academic Transcript',
            Verification_Status__c = 'Verified'
        ));
    }
    insert docs;
    System.debug('Inserted 6 Documents.');

    // For app3, update to Approved (and make sure Document_Status__c is Verified)
    app3.Document_Status__c = 'Verified';
    app3.Application_Status__c = 'Approved';
    update app3;
    System.debug('Approved Application 3.');

    // Retrieve the newly created Payment record and update its owner and status to Paid
    List<Payment__c> payments = [SELECT Id, OwnerId FROM Payment__c WHERE Student_Application__c = :app3.Id];
    for (Payment__c pay : payments) {
        pay.OwnerId = salesExec.Id;
        pay.Payment_Status__c = 'Paid';
        pay.Payment_Date__c = System.today();
        pay.Transaction_Id__c = 'TXN-' + Crypto.getRandomInteger();
        pay.Payment_Method__c = 'UPI';
    }
    if (!payments.isEmpty()) {
        update payments;
        System.debug('Updated Payment status to Paid and ownership to Sales Executive.');
    }

    // Retrieve newly created Admission record (triggered by payment becoming Paid) and set its owner to the Sales Executive user
    List<Admission__c> admissions = [SELECT Id, OwnerId FROM Admission__c WHERE Student_Application__c = :app3.Id];
    for (Admission__c adm : admissions) {
        adm.OwnerId = salesExec.Id;
    }
    if (!admissions.isEmpty()) {
        update admissions;
        System.debug('Updated Admission ownership to Sales Executive.');
    }

    System.debug('All records seeded successfully for Salesforce Admin course and owned by ' + salesExecUsername);
    System.debug('===== SEED SALES EXEC APPLICATIONS COMPLETED SUCCESSFULLY =====');
} catch (Exception e) {
    System.debug('EXCEPTION: ' + e.getMessage() + '\n' + e.getStackTraceString());
    throw e;
}
