@isTest
public class TriggerFrameworkTest {
    
    // Custom subclass to test TriggerHandler virtual base class fully
    private class TestHandler extends TriggerHandler {
        public override void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldMap) {}
        public override void afterDelete(List<SObject> oldRecords, Map<Id, SObject> oldMap) {}
        public override void afterUndelete(List<SObject> newRecords, Map<Id, SObject> newMap) {}
    }
    
    @isTest
    static void testVirtualHandlerMethods() {
        TriggerHandler baseHandler = new TriggerHandler();
        // Invoke virtual methods directly to cover the empty base methods
        baseHandler.beforeInsert(null);
        baseHandler.afterInsert(null, null);
        baseHandler.beforeUpdate(null, null, null, null);
        baseHandler.afterUpdate(null, null, null, null);
        baseHandler.beforeDelete(null, null);
        baseHandler.afterDelete(null, null);
        baseHandler.afterUndelete(null, null);
        
        // Assert that creating a non-handler throws exception
        try {
            TriggerFactory.createAndExecuteHandler(String.class);
            Assert.fail('Should throw exception for non TriggerHandler type');
        } catch (TriggerFactory.TriggerException e) {
            Assert.isTrue(e.getMessage().contains('Handler must extend TriggerHandler'), 'Correct exception message');
        }
    }
    
    @isTest
    static void testDuplicatePreventionTrigger() {
        Course__c course = new Course__c(
            Name = 'Introduction to Apex',
            Course_Code__c = 'APEX101',
            Credits__c = 3,
            Capacity__c = 5,
            Status__c = 'Active',
            Fees__c = 1000
        );
        insert course;

        Student_Application__c app1 = new Student_Application__c(
            First_Name__c = 'DupCheck',
            Last_Name__c = 'Test',
            Email__c = 'dup@test.com',
            Date_of_Birth__c = Date.today().addYears(-20),
            Applied_Course__c = course.Id,
            Application_Status__c = Constants.APP_STATUS_DRAFT
        );
        insert app1;
        
        // Attempt insert duplicate
        Student_Application__c app2 = new Student_Application__c(
            First_Name__c = 'DupCheck',
            Last_Name__c = 'Test',
            Email__c = 'dup@test.com',
            Date_of_Birth__c = Date.today().addYears(-20),
            Applied_Course__c = course.Id,
            Application_Status__c = Constants.APP_STATUS_DRAFT
        );
        
        try {
            insert app2;
            Assert.fail('Should block duplicate creation');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('An application with the same name and email already exists'), 'Correct error message: ' + e.getMessage());
        }
    }

    @isTest
    static void testCourseCapacityLimitTrigger() {
        // Course with capacity = 1
        Course__c course = new Course__c(
            Name = 'Limited Course',
            Course_Code__c = 'LIM101',
            Credits__c = 3,
            Capacity__c = 1,
            Status__c = 'Active',
            Fees__c = 1000
        );
        insert course;

        Student_Application__c app1 = new Student_Application__c(
            First_Name__c = 'Student1',
            Last_Name__c = 'One',
            Email__c = 'stud1@test.com',
            Date_of_Birth__c = Date.today().addYears(-20),
            Applied_Course__c = course.Id,
            Application_Status__c = Constants.APP_STATUS_DRAFT
        );
        insert app1;

        Student_Application__c app2 = new Student_Application__c(
            First_Name__c = 'Student2',
            Last_Name__c = 'Two',
            Email__c = 'stud2@test.com',
            Date_of_Birth__c = Date.today().addYears(-20),
            Applied_Course__c = course.Id,
            Application_Status__c = Constants.APP_STATUS_DRAFT
        );
        insert app2;
        
        // Admission 1
        Admission__c adm1 = new Admission__c(
            Student_Application__c = app1.Id,
            Course__c = course.Id,
            Admission_Date__c = Date.today()
        );
        insert adm1;
        
        // Admission 2 (should fail because capacity = 1)
        Admission__c adm2 = new Admission__c(
            Student_Application__c = app2.Id,
            Course__c = course.Id,
            Admission_Date__c = Date.today()
        );
        
        try {
            insert adm2;
            Assert.fail('Should block over capacity admission');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('maximum capacity'), 'Correct capacity block error message: ' + e.getMessage());
        }
    }
}
