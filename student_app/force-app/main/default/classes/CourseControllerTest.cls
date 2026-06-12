@isTest
public class CourseControllerTest {
    @isTest
    static void testGetCourses() {
        // Create an active course with seats
        Course__c course = new Course__c(
            Name = 'Introduction to Apex',
            Course_Code__c = 'APEX101',
            Description__c = 'Learn basic Apex programming.',
            Credits__c = 3,
            Capacity__c = 5,
            Status__c = 'Active',
            Fees__c = 1000
        );
        insert course;
        
        Test.startTest();
        List<CourseController.CourseWrapper> courseList = CourseController.getCourses();
        Test.stopTest();
        
        Assert.isFalse(courseList.isEmpty(), 'Active course list should not be empty');
        Assert.areEqual('Introduction to Apex', courseList[0].course.Name);
        Assert.isTrue(courseList[0].remainingSeats >= 0, 'Available seats should be >= 0');
    }

    @isTest
    static void testGetCoursesWithZeroCapacity() {
        // Edge case: course with 0 capacity
        Course__c zeroCourse = new Course__c(
            Name = 'Zero Cap Course',
            Course_Code__c = 'ZERO001',
            Description__c = 'Zero capacity course.',
            Credits__c = 1,
            Capacity__c = 0,
            Status__c = 'Active',
            Fees__c = 500
        );
        insert zeroCourse;

        Test.startTest();
        List<CourseController.CourseWrapper> courseList = CourseController.getCourses();
        Test.stopTest();

        Assert.isFalse(courseList.isEmpty(), 'Should return courses including zero-cap');
        // Find the zero-cap course and verify available seats is 0
        CourseController.CourseWrapper found = null;
        for (CourseController.CourseWrapper w : courseList) {
            if (w.course.Course_Code__c == 'ZERO001') {
                found = w;
                break;
            }
        }
        Assert.isNotNull(found, 'Zero-cap course should appear in the list');
        Assert.areEqual(0, found.remainingSeats, 'Zero-cap course should show 0 available seats');
    }

    @isTest
    static void testGetCoursesEmpty() {
        // No courses exist - list should be empty or contain only system-level test data
        Test.startTest();
        List<CourseController.CourseWrapper> courseList = CourseController.getCourses();
        Test.stopTest();
        // Simply verify no exception is thrown and result is a valid list
        Assert.isNotNull(courseList, 'Result should be a non-null list even if empty');
    }
}
