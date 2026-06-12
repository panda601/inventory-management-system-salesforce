@isTest
public class StudentApplicationControllerTest {
    @isTest
    static void testSaveAndSubmitApplication() {
        // Create a course
        Course__c course = new Course__c(
            Name = 'Introduction to Apex',
            Course_Code__c = 'APEX101',
            Credits__c = 3,
            Capacity__c = 5,
            Status__c = 'Active',
            Fees__c = 1000
        );
        insert course;
        
        Map<String, Object> appData = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'email' => UserInfo.getUserEmail(),
            'phone' => '1234567890',
            'dob' => '2000-01-01',
            'courseId' => course.Id
        };
        
        Test.startTest();
        Student_Application__c app = StudentApplicationController.saveApplication(appData);
        Assert.isNotNull(app.Id, 'Application record should be saved');
        
        // Test getMyApplications
        List<Student_Application__c> myApps = StudentApplicationController.getMyApplications();
        Assert.isFalse(myApps.isEmpty(), 'Current user application list should not be empty');
        
        // Link document record
        // Create ContentVersion to get a documentId
        ContentVersion cv = new ContentVersion(
            Title = 'Transcript',
            PathOnClient = 'Transcript.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        Document__c doc = StudentApplicationController.createDocumentRecord(
            String.valueOf(app.Id),
            'Academic Transcript',
            String.valueOf(contentDocId),
            'Transcript.pdf'
        );
        Assert.isNotNull(doc.Id, 'Document record should be created');

        Student_Application__c uploadedApp = [
            SELECT Document_Status__c
            FROM Student_Application__c
            WHERE Id = :app.Id
        ];
        Assert.areEqual('Uploaded', uploadedApp.Document_Status__c, 'Document status should move to Uploaded after file link');

        List<StudentApplicationController.DocumentWrapper> docWrappers =
            StudentApplicationController.getRelatedDocuments(String.valueOf(app.Id));
        Assert.areEqual(1, docWrappers.size(), 'Document wrapper list should include the uploaded file');
        Assert.areEqual(contentDocId, docWrappers[0].contentDocumentId, 'ContentDocumentId should match the uploaded file');
        
        // Submit application
        StudentApplicationController.submitApplication(String.valueOf(app.Id));
        Test.stopTest();
        
        Student_Application__c updatedApp = [SELECT Application_Status__c FROM Student_Application__c WHERE Id = :app.Id];
        Assert.areEqual(Constants.APP_STATUS_SUBMITTED, updatedApp.Application_Status__c);
    }

    @isTest
    static void testInvalidIdValidationUsesFriendlyErrors() {
        Map<String, Object> invalidAppData = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'email' => UserInfo.getUserEmail(),
            'dob' => '2000-01-01',
            'courseId' => '123'
        };

        try {
            StudentApplicationController.saveApplication(invalidAppData);
            Assert.fail('An invalid course Id should be rejected.');
        } catch (AuraHandledException ex) {
            Assert.isFalse(ex.getMessage().contains('Invalid id'), 'The controller should not leak a raw Invalid id error.');
        }

        List<StudentApplicationController.DocumentWrapper> blankResult =
            StudentApplicationController.getRelatedDocuments(null);
        Assert.areEqual(0, blankResult.size(), 'Blank application ids should safely return no documents.');
    }

    @isTest
    static void testRecordTypesAndPaymentSubmission() {
        Course__c course = new Course__c(
            Name = 'Business Analytics',
            Course_Code__c = 'MBA201',
            Credits__c = 4,
            Capacity__c = 8,
            Status__c = 'Active',
            Fees__c = 2500
        );
        insert course;

        Map<String, Id> recordTypes = StudentApplicationController.getRecordTypes();
        Assert.isFalse(recordTypes.isEmpty(), 'Student application record types should be available.');

        Id recordTypeId = new List<Id>(recordTypes.values())[0];
        Map<String, Object> appData = new Map<String, Object>{
            'firstName' => 'Priya',
            'lastName' => 'Shah',
            'email' => UserInfo.getUserEmail(),
            'phone' => '9999999999',
            'dob' => '1999-08-15',
            'courseId' => String.valueOf(course.Id),
            'recordTypeId' => String.valueOf(recordTypeId)
        };

        Student_Application__c app = StudentApplicationController.saveApplication(appData);

        Test.startTest();
        StudentApplicationController.processPaymentAndSubmit(String.valueOf(app.Id), 'Card', 2500);
        Test.stopTest();

        List<Payment__c> payments = [
            SELECT Id, Payment_Status__c, Student_Application__c
            FROM Payment__c
            WHERE Student_Application__c = :app.Id
        ];
        Assert.areEqual(1, payments.size(), 'A payment record should be created during submit.');
        Assert.areEqual('Paid', payments[0].Payment_Status__c, 'The generated payment should be marked as Paid.');
    }
}
