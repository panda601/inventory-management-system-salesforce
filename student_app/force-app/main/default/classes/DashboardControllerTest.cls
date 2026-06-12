@isTest
public class DashboardControllerTest {
    @isTest
    static void testGetDashboardMetrics() {
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
            Email__c = UserInfo.getUserEmail(),
            Date_of_Birth__c = Date.today().addYears(-20),
            Applied_Course__c = course.Id,
            Application_Status__c = Constants.APP_STATUS_DRAFT
        );
        insert app;
        
        Test.startTest();
        Map<String, Integer> studentMetrics = DashboardController.getStudentMetrics();
        Map<String, Object> adminMetrics = DashboardController.getAdminDashboardMetrics();
        Test.stopTest();
        
        Assert.isNotNull(studentMetrics, 'Student metrics should be returned');
        Assert.isNotNull(adminMetrics, 'Admin metrics should be returned');
    }
}
