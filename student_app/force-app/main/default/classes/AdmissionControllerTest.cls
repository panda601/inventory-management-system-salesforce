@isTest
public class AdmissionControllerTest {
    @isTest
    static void testGetAdmissionSummary() {
        // Create course
        Course__c course = new Course__c(
            Name = 'Introduction to Apex',
            Course_Code__c = 'APEX101',
            Credits__c = 3,
            Capacity__c = 5,
            Status__c = 'Active',
            Fees__c = 1000
        );
        insert course;

        // Create application
        Student_Application__c app = new Student_Application__c(
            First_Name__c = 'Jane',
            Last_Name__c = 'Smith',
            Email__c = 'jane.smith@test.com',
            Date_of_Birth__c = Date.today().addYears(-20),
            Applied_Course__c = course.Id,
            Application_Status__c = Constants.APP_STATUS_DRAFT
        );
        insert app;
        
        // Create admission
        Admission__c adm = new Admission__c(
            Student_Application__c = app.Id,
            Course__c = course.Id,
            Admission_Date__c = Date.today(),
            Fees_Paid__c = false
        );
        insert adm;
        
        Test.startTest();
        Admission__c summary = AdmissionController.getAdmissionSummary(adm.Id);
        Admission__c byApp = AdmissionController.getAdmissionByApplication(app.Id);
        Test.stopTest();
        
        Assert.isNotNull(summary, 'Summary should be retrieved');
        Assert.areEqual(adm.Id, summary.Id);
        Assert.isNotNull(byApp, 'Summary by Application should be retrieved');
        Assert.areEqual(adm.Id, byApp.Id);
    }
}
