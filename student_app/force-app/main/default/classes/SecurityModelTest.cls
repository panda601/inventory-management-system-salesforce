@isTest
public class SecurityModelTest {

    @testSetup
    static void setupTestData() {
        // Query Profiles
        Profile platformProfile = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User' LIMIT 1];
        
        // Query Roles
        Map<String, Id> roleIds = new Map<String, Id>();
        for (UserRole ur : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN ('Admission_Manager', 'Admission_Executive', 'Document_Verifier', 'Finance_Officer', 'Student')]) {
            roleIds.put(ur.DeveloperName, ur.Id);
        }
        
        // Create Test Users in System Administrator context to avoid mixed DML issues
        User adminUser = new User(Id = UserInfo.getUserId());
        System.runAs(adminUser) {
            // Student A
            User studentA = new User(
                FirstName = 'Student',
                LastName = 'Alpha',
                Email = 'studenta@test.com',
                Username = 'studenta_' + DateTime.now().getTime() + '@test.com',
                Alias = 'studA',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = platformProfile.Id,
                UserRoleId = roleIds.get('Student')
            );
            insert studentA;
            
            // Student B
            User studentB = new User(
                FirstName = 'Student',
                LastName = 'Beta',
                Email = 'studentb@test.com',
                Username = 'studentb_' + DateTime.now().getTime() + '@test.com',
                Alias = 'studB',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = platformProfile.Id,
                UserRoleId = roleIds.get('Student')
            );
            insert studentB;

            // Admission Manager
            User mgrUser = new User(
                FirstName = 'Manager',
                LastName = 'User',
                Email = 'manager@test.com',
                Username = 'manager_' + DateTime.now().getTime() + '@test.com',
                Alias = 'mgrU',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = platformProfile.Id,
                UserRoleId = roleIds.get('Admission_Manager')
            );
            insert mgrUser;

            // Admission Executive
            User execUser = new User(
                FirstName = 'Exec',
                LastName = 'User',
                Email = 'exec@test.com',
                Username = 'exec_' + DateTime.now().getTime() + '@test.com',
                Alias = 'execU',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = platformProfile.Id,
                UserRoleId = roleIds.get('Admission_Executive')
            );
            insert execUser;

            // Document Verifier
            User verifierUser = new User(
                FirstName = 'Verifier',
                LastName = 'User',
                Email = 'verifier@test.com',
                Username = 'verifier_' + DateTime.now().getTime() + '@test.com',
                Alias = 'veriU',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = platformProfile.Id,
                UserRoleId = roleIds.get('Document_Verifier')
            );
            insert verifierUser;

            // Finance Officer
            User financeUser = new User(
                FirstName = 'Finance',
                LastName = 'User',
                Email = 'finance@test.com',
                Username = 'finance_' + DateTime.now().getTime() + '@test.com',
                Alias = 'finaU',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = platformProfile.Id,
                UserRoleId = roleIds.get('Finance_Officer')
            );
            insert financeUser;

            // Assign Permission Sets
            Map<String, Id> permSetIds = new Map<String, Id>();
            for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('Student_Access', 'Admission_Executive_Access', 'Document_Verifier_Access', 'Finance_Officer_Access', 'Admission_Manager_Access')]) {
                permSetIds.put(ps.Name, ps.Id);
            }

            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>{
                new PermissionSetAssignment(AssigneeId = studentA.Id, PermissionSetId = permSetIds.get('Student_Access')),
                new PermissionSetAssignment(AssigneeId = studentB.Id, PermissionSetId = permSetIds.get('Student_Access')),
                new PermissionSetAssignment(AssigneeId = mgrUser.Id, PermissionSetId = permSetIds.get('Admission_Manager_Access')),
                new PermissionSetAssignment(AssigneeId = execUser.Id, PermissionSetId = permSetIds.get('Admission_Executive_Access')),
                new PermissionSetAssignment(AssigneeId = verifierUser.Id, PermissionSetId = permSetIds.get('Document_Verifier_Access')),
                new PermissionSetAssignment(AssigneeId = financeUser.Id, PermissionSetId = permSetIds.get('Finance_Officer_Access'))
            };
            insert assignments;

            // Create Course
            Course__c course = new Course__c(
                Name = 'Security Audit Course',
                Course_Code__c = 'SEC101',
                Credits__c = 3,
                Capacity__c = 10,
                Status__c = 'Active',
                Fees__c = 1000
            );
            insert course;

            // Create Application owned by Student A
            System.runAs(studentA) {
                Student_Application__c app = new Student_Application__c(
                    First_Name__c = 'Alice',
                    Last_Name__c = 'Alpha',
                    Email__c = 'studenta@test.com',
                    Phone__c = '1112223333',
                    Date_of_Birth__c = Date.today().addYears(-20),
                    Applied_Course__c = course.Id,
                    Application_Status__c = Constants.APP_STATUS_DRAFT
                );
                insert app;

                // Create Document
                Document__c doc = new Document__c(
                    Student_Application__c = app.Id,
                    Document_Type__c = 'Passport / ID',
                    Verification_Status__c = 'Pending'
                );
                insert doc;

                // Create Payment record
                Payment__c pay = new Payment__c(
                    Student_Application__c = app.Id,
                    Amount__c = 1000.00,
                    Payment_Status__c = Constants.PAY_STATUS_PENDING,
                    Payment_Date__c = Date.today(),
                    Transaction_Id__c = 'TXN-SEC-101',
                    Payment_Method__c = 'UPI'
                );
                insert pay;
            }
        }
    }

    @isTest
    static void testStudentVisibility() {
        User studentA = [SELECT Id FROM User WHERE Email = 'studenta@test.com' LIMIT 1];
        User studentB = [SELECT Id FROM User WHERE Email = 'studentb@test.com' LIMIT 1];

        // Student A should see their own records
        System.runAs(studentA) {
            List<Student_Application__c> apps = [SELECT Id FROM Student_Application__c];
            Assert.areEqual(1, apps.size(), 'Student A should see their own application');
            
            List<Document__c> docs = [SELECT Id FROM Document__c];
            Assert.areEqual(1, docs.size(), 'Student A should see their own document');

            List<Payment__c> payments = [SELECT Id FROM Payment__c];
            Assert.areEqual(1, payments.size(), 'Student A should see their own payment');
            
            CourseController.getCourses();
        }

        // Student B (sibling role, different user) should see 0 records due to Private OWD
        System.runAs(studentB) {
            List<Student_Application__c> apps = [SELECT Id FROM Student_Application__c];
            Assert.areEqual(0, apps.size(), 'Student B should not see Student A\'s application');
            
            List<Document__c> docs = [SELECT Id FROM Document__c];
            Assert.areEqual(0, docs.size(), 'Student B should not see Student A\'s document');

            List<Payment__c> payments = [SELECT Id FROM Payment__c];
            Assert.areEqual(0, payments.size(), 'Student B should not see Student A\'s payment');
        }
    }

    @isTest
    static void testStudentEditRestrictions() {
        User studentA = [SELECT Id FROM User WHERE Email = 'studenta@test.com' LIMIT 1];
        
        System.runAs(studentA) {
            Student_Application__c app = [SELECT Id, Application_Status__c, Phone__c FROM Student_Application__c LIMIT 1];
            Assert.areEqual(Constants.APP_STATUS_DRAFT, app.Application_Status__c, 'Application should start in Draft');
            
            // Student can edit in Draft
            app.Phone__c = '9998887777';
            update app;
            
            // Transition application to Submitted
            app.Application_Status__c = Constants.APP_STATUS_SUBMITTED;
            update app;
            
            // Student cannot edit application after submission
            app.Phone__c = '1111111111';
            try {
                update app;
                Assert.fail('Should have thrown validation error: application locked for editing');
            } catch (DmlException e) {
                Assert.isTrue(e.getMessage().contains('You can only edit applications that are in Draft status'), 'Should contain draft status warning');
            }
        }
    }

    @isTest
    static void testOwnerSynchronization() {
        User studentA = [SELECT Id FROM User WHERE Email = 'studenta@test.com' LIMIT 1];
        
        // Query the Application created by Student A
        Student_Application__c app = [SELECT Id, OwnerId FROM Student_Application__c LIMIT 1];
        Assert.areEqual(studentA.Id, app.OwnerId, 'Student A should own their application');
        
        // Verify payment owner
        Payment__c pay = [SELECT Id, OwnerId FROM Payment__c LIMIT 1];
        Assert.areEqual(studentA.Id, pay.OwnerId, 'Payment owner should be student A');
        
        // Approve application (using admin/system context to trigger Admission creation)
        User adminUser = new User(Id = UserInfo.getUserId());
        System.runAs(adminUser) {
            // First mark document verified to satisfy approval entry criteria
            Document__c doc = [SELECT Id, Verification_Status__c FROM Document__c LIMIT 1];
            doc.Verification_Status__c = 'Verified';
            update doc;
            
            app.Application_Status__c = 'Approved';
            app.Admission_Status__c = 'Pending';
            update app;
            
            // Set status to Paid to trigger flow-based Admission creation
            app.Application_Status__c = 'Paid';
            update app;
        }
        
        // Verify Admission was created and its owner is student A
        Admission__c adm = [SELECT Id, OwnerId FROM Admission__c LIMIT 1];
        Assert.areEqual(studentA.Id, adm.OwnerId, 'Admission owner should be student A');
    }

    @isTest
    static void testAdmissionExecutiveVisibility() {
        User execUser = [SELECT Id FROM User WHERE Email = 'exec@test.com' LIMIT 1];

        System.runAs(execUser) {
            // Admission Executive should see all applications due to sharing rule
            List<Student_Application__c> apps = [SELECT Id FROM Student_Application__c];
            Assert.areEqual(1, apps.size(), 'Admission Executive should see Student A\'s application via sharing rules');
            
            // Document is ControlledByParent, so sharing is inherited
            List<Document__c> docs = [SELECT Id FROM Document__c];
            Assert.areEqual(1, docs.size(), 'Admission Executive should see Student A\'s document');

            // Admission Executive has Read access to Payments via sharing rule (DEFECT-09 fix)
            List<Payment__c> payments = [SELECT Id FROM Payment__c];
            Assert.areEqual(1, payments.size(), 'Admission Executive should see Payment records via sharing rule');
            
            CourseController.getCourses();
        }
    }

    @isTest
    static void testDocumentVerifierVisibility() {
        User verifierUser = [SELECT Id FROM User WHERE Email = 'verifier@test.com' LIMIT 1];

        System.runAs(verifierUser) {
            // Document Verifier should see all applications due to sharing rule
            List<Student_Application__c> apps = [SELECT Id FROM Student_Application__c];
            Assert.areEqual(1, apps.size(), 'Document Verifier should see Student A\'s application');
            
            // Document is ControlledByParent, so sharing is inherited
            List<Document__c> docs = [SELECT Id FROM Document__c];
            Assert.areEqual(1, docs.size(), 'Document Verifier should see Student A\'s document');
        }
    }

    @isTest
    static void testFinanceOfficerVisibility() {
        User financeUser = [SELECT Id FROM User WHERE Email = 'finance@test.com' LIMIT 1];

        System.runAs(financeUser) {
            // Finance Officer should see Payment records via sharing rule
            List<Payment__c> payments = [SELECT Id FROM Payment__c];
            Assert.areEqual(1, payments.size(), 'Finance Officer should see Student A\'s payment record via sharing rules');

            // Finance Officer does NOT have access to Student Applications (no sharing rule)
            List<Student_Application__c> apps = [SELECT Id FROM Student_Application__c];
            Assert.areEqual(0, apps.size(), 'Finance Officer should not see Student Application records');
        }
    }

    @isTest
    static void testAdmissionManagerVisibility() {
        User mgrUser = [SELECT Id FROM User WHERE Email = 'manager@test.com' LIMIT 1];

        System.runAs(mgrUser) {
            // Admission Manager should see applications via sharing (inherited or direct role hierarchy)
            List<Student_Application__c> apps = [SELECT Id FROM Student_Application__c];
            Assert.areEqual(1, apps.size(), 'Admission Manager should see applications');

            // Admission Manager should see payments via sharing rule (read access)
            List<Payment__c> payments = [SELECT Id FROM Payment__c];
            Assert.areEqual(1, payments.size(), 'Admission Manager should see payments');
            
            CourseController.getCourses();
        }
    }

    @isTest
    static void testApplicationRejectionAutomation() {
        User adminUser = new User(Id = UserInfo.getUserId());
        System.runAs(adminUser) {
            Student_Application__c app = [SELECT Id, Application_Status__c, Admission_Status__c FROM Student_Application__c LIMIT 1];
            app.Application_Status__c = 'Rejected';
            update app;

            Student_Application__c updatedApp = [SELECT Id, Admission_Status__c FROM Student_Application__c WHERE Id = :app.Id];
            Assert.areEqual('Rejected', updatedApp.Admission_Status__c, 'Admission status should be set to Rejected');
        }
    }

    @isTest
    static void testDocumentRejectionAutomation() {
        User verifierUser = [SELECT Id FROM User WHERE Email = 'verifier@test.com' LIMIT 1];
        System.runAs(verifierUser) {
            Document__c doc = [SELECT Id, Verification_Status__c FROM Document__c LIMIT 1];
            doc.Verification_Status__c = 'Rejected';
            doc.Rejection_Reason__c = 'Document does not meet requirements';
            update doc;

            Student_Application__c parentApp = [SELECT Id, Admission_Status__c, Document_Status__c FROM Student_Application__c LIMIT 1];
            Assert.areEqual('Rejected', parentApp.Admission_Status__c, 'Admission status should be updated to Rejected');
            Assert.areEqual('Rejected', parentApp.Document_Status__c, 'Document status should be updated to Rejected');
        }
    }

    @isTest
    static void testDocumentVerificationAutomation() {
        User verifierUser = [SELECT Id FROM User WHERE Email = 'verifier@test.com' LIMIT 1];
        System.runAs(verifierUser) {
            Document__c doc = [SELECT Id, Verification_Status__c FROM Document__c LIMIT 1];
            doc.Verification_Status__c = 'Verified';
            update doc;

            Student_Application__c parentApp = [
                SELECT Id, Document_Status__c
                FROM Student_Application__c
                LIMIT 1
            ];
            Assert.areEqual('Verified', parentApp.Document_Status__c, 'Document status should be updated to Verified when all files are verified');
        }
    }

    @isTest
    static void testPaymentAutoPopulation() {
        User studentA = [SELECT Id FROM User WHERE Email = 'studenta@test.com' LIMIT 1];
        Student_Application__c app = [SELECT Id, Applied_Course__c FROM Student_Application__c LIMIT 1];

        System.runAs(studentA) {
            Payment__c pay = new Payment__c(
                Student_Application__c = app.Id,
                Payment_Status__c = Constants.PAY_STATUS_PENDING,
                Payment_Date__c = Date.today(),
                Transaction_Id__c = 'TXN-AUTO-999',
                Payment_Method__c = 'UPI'
            );
            insert pay;

            Course__c cRecord = [SELECT Name FROM Course__c WHERE Id = :app.Applied_Course__c LIMIT 1];
            Payment__c insertedPay = [SELECT Id, Amount__c, Course__c FROM Payment__c WHERE Id = :pay.Id];
            Assert.areNotEqual(null, insertedPay.Amount__c, 'Payment amount should be auto-populated');
            Assert.areEqual(cRecord.Name, insertedPay.Course__c, 'Payment course should be auto-populated');
        }
    }

    @isTest
    static void testStudentControllerSubmission() {
        User studentA = [SELECT Id FROM User WHERE Email = 'studenta@test.com' LIMIT 1];
        Course__c course = [SELECT Id FROM Course__c LIMIT 1];

        System.runAs(studentA) {
            Map<String, Object> appData = new Map<String, Object>{
                'firstName' => 'StudentFirstName',
                'lastName' => 'StudentLastName',
                'email' => 'studenta@test.com',
                'phone' => '1112223333',
                'dob' => '2000-01-01',
                'courseId' => course.Id
            };
            Student_Application__c app = StudentApplicationController.saveApplication(appData);
            Assert.isNotNull(app.Id, 'Application should be created');

            StudentApplicationController.submitApplication(app.Id);
        }
    }
}
