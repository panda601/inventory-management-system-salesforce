@isTest
public class PaymentTest {
    @isTest
    static void testPaymentAndDocumentMetrics() {
        // Create Course
        Course__c course = new Course__c(
            Name = 'Introduction to Salesforce Test',
            Course_Code__c = 'SF101',
            Credits__c = 4,
            Capacity__c = 10,
            Status__c = 'Active',
            Fees__c = 1500
        );
        insert course;

        // Create Student Application with current user email
        Student_Application__c app = new Student_Application__c(
            First_Name__c = 'Alice',
            Last_Name__c = 'Tester',
            Email__c = UserInfo.getUserEmail(),
            Phone__c = '9876543210',
            Date_of_Birth__c = Date.today().addYears(-22),
            Applied_Course__c = course.Id,
            Application_Status__c = Constants.APP_STATUS_DRAFT
        );
        insert app;

        // Create ContentVersion to link files
        ContentVersion cv = new ContentVersion(
            Title = 'Identification Doc',
            PathOnClient = 'id.png',
            VersionData = Blob.valueOf('ID Document Content')
        );
        insert cv;
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Use controller to create Document record and link it
        Document__c doc = StudentApplicationController.createDocumentRecord(
            String.valueOf(app.Id),
            'Passport / ID',
            String.valueOf(contentDocId),
            'id.png'
        );
        Assert.isNotNull(doc.Id, 'Document record should be created');

        // Create Payments with all statuses (updated to new picklist values)
        Payment__c paidPay = new Payment__c(
            Student_Application__c = app.Id,
            Amount__c = 1500.00,
            Payment_Status__c = Constants.PAY_STATUS_PAID,
            Payment_Date__c = Date.today(),
            Transaction_Id__c = 'TXN-PAID-123',
            Payment_Method__c = 'Card'
        );
        insert paidPay;

        Payment__c pendingPay = new Payment__c(
            Student_Application__c = app.Id,
            Amount__c = 1500.00,
            Payment_Status__c = Constants.PAY_STATUS_PENDING,
            Payment_Date__c = Date.today(),
            Transaction_Id__c = 'TXN-PENDING-456',
            Payment_Method__c = 'UPI'
        );
        insert pendingPay;

        Payment__c failedPay = new Payment__c(
            Student_Application__c = app.Id,
            Amount__c = 1500.00,
            Payment_Status__c = Constants.PAY_STATUS_FAILED,
            Payment_Date__c = Date.today(),
            Transaction_Id__c = 'TXN-FAILED-789',
            Payment_Method__c = 'Net Banking'
        );
        insert failedPay;

        Payment__c refundedPay = new Payment__c(
            Student_Application__c = app.Id,
            Amount__c = 1500.00,
            Payment_Status__c = Constants.PAY_STATUS_REFUNDED,
            Payment_Date__c = Date.today(),
            Transaction_Id__c = 'TXN-REFUND-999',
            Payment_Method__c = 'Card'
        );
        insert refundedPay;

        Test.startTest();
        // Test StudentApplicationController methods
        List<Student_Application__c> apps = StudentApplicationController.getMyApplications();
        Assert.isFalse(apps.isEmpty(), 'getMyApplications should return applications');
        Assert.areEqual(app.Id, apps[0].Id, 'Should return the created application');
        Assert.isFalse(apps[0].Payments__r.isEmpty(), 'Application should have payments subquery populated');

        List<StudentApplicationController.DocumentWrapper> docWrappers =
            StudentApplicationController.getRelatedDocuments(String.valueOf(app.Id));
        Assert.isFalse(docWrappers.isEmpty(), 'getRelatedDocuments should return documents');
        Assert.areEqual(contentDocId, docWrappers[0].contentDocumentId, 'ContentDocumentId should match');

        // Test DashboardController payment metrics (new Paid status)
        Map<String, Object> adminMetrics = DashboardController.getAdminDashboardMetrics();
        Assert.isNotNull(adminMetrics, 'Admin dashboard metrics should be returned');
        Assert.areEqual(4, adminMetrics.get('totalPayments'), 'Total payments should be 4');
        Assert.areEqual(1, adminMetrics.get('successPayments'), 'Paid payments count should be 1');
        Assert.areEqual(1, adminMetrics.get('pendingPayments'), 'Pending payments should be 1');
        Assert.areEqual(1, adminMetrics.get('failedPayments'), 'Failed payments should be 1');
        Assert.areEqual(1500.00, (Decimal)adminMetrics.get('totalRevenue'), 'Total revenue should be 1500.00');

        List<Payment__c> recentPayments = (List<Payment__c>)adminMetrics.get('recentPayments');
        Assert.isFalse(recentPayments.isEmpty(), 'Recent payments list should not be empty');

        // Test new analytics methods
        List<Map<String, Object>> trends = DashboardController.getMonthlyTrends();
        Assert.isNotNull(trends, 'Monthly trends should be returned');

        List<Map<String, Object>> courseAnalytics = DashboardController.getCourseAnalytics();
        Assert.isNotNull(courseAnalytics, 'Course analytics should be returned');
        Assert.isFalse(courseAnalytics.isEmpty(), 'Course analytics should contain our test data');

        Test.stopTest();
    }

    @isTest
    static void testConstantsPaymentValues() {
        // Cover Constants class new payment status literals
        Assert.areEqual('Pending',  Constants.PAY_STATUS_PENDING,  'Pending constant');
        Assert.areEqual('Paid',     Constants.PAY_STATUS_PAID,     'Paid constant');
        Assert.areEqual('Failed',   Constants.PAY_STATUS_FAILED,   'Failed constant');
        Assert.areEqual('Refunded', Constants.PAY_STATUS_REFUNDED, 'Refunded constant');
    }

    @isTest
    static void testPaymentVerificationAssignmentFlow() {
        // Create Course
        Course__c course = new Course__c(
            Name = 'Test CS Course',
            Course_Code__c = 'CS202',
            Credits__c = 3,
            Capacity__c = 15,
            Status__c = 'Active',
            Fees__c = 1200
        );
        insert course;

        // Create Student Application
        Student_Application__c app = new Student_Application__c(
            First_Name__c = 'Bob',
            Last_Name__c = 'Builder',
            Email__c = 'bob.builder@test.com',
            Phone__c = '1234567890',
            Date_of_Birth__c = Date.today().addYears(-20),
            Applied_Course__c = course.Id,
            Application_Status__c = Constants.APP_STATUS_DRAFT
        );
        insert app;

        // Transition to Submitted so flow will process the payment
        app.Application_Status__c = Constants.APP_STATUS_SUBMITTED;
        update app;

        Test.startTest();

        // Create Payment in Pending status
        Payment__c payment = new Payment__c(
            Student_Application__c = app.Id,
            Amount__c = 1200.00,
            Payment_Status__c = Constants.PAY_STATUS_PENDING,
            Payment_Date__c = Date.today(),
            Transaction_Id__c = 'TXN-TEST-111',
            Payment_Method__c = 'Card'
        );
        insert payment;

        // Query application and verify Payment Status and Application Status
        Student_Application__c updatedApp = [
            SELECT Id, Application_Status__c, Payment_Status__c 
            FROM Student_Application__c 
            WHERE Id = :app.Id
        ];
        Assert.areEqual(Constants.APP_STATUS_PAYMENT_PENDING, updatedApp.Application_Status__c, 'Application Status should be updated to Payment Pending');
        Assert.areEqual('Pending', updatedApp.Payment_Status__c, 'Payment Status should be updated to Pending');

        // Verify task creation
        List<Task> tasks = [
            SELECT Id, Subject, Status, Description 
            FROM Task 
            WHERE WhatId = :app.Id
        ];
        Assert.isFalse(tasks.isEmpty(), 'A verification task should be created');
        Assert.areEqual('Verify Payment', tasks[0].Subject, 'Task subject should match');

        // Update Payment to Paid status
        payment.Payment_Status__c = Constants.PAY_STATUS_PAID;
        update payment;

        Student_Application__c updatedAppPaid = [
            SELECT Id, Application_Status__c, Payment_Status__c 
            FROM Student_Application__c 
            WHERE Id = :app.Id
        ];
        Assert.areEqual(Constants.APP_STATUS_PAID, updatedAppPaid.Application_Status__c, 'Application Status should be updated to Paid');
        Assert.areEqual('Paid', updatedAppPaid.Payment_Status__c, 'Payment Status should be updated to Paid');

        Test.stopTest();
    }
}
