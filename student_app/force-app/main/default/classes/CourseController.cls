public with sharing class CourseController {
    public static List<CourseWrapper> getCourses() {
        return getCourses((String)null);
    }

    @AuraEnabled(cacheable=true)
    public static List<CourseWrapper> getCourses(String type) {
        List<CourseWrapper> results = new List<CourseWrapper>();
        
        // Query active courses - class is 'with sharing' for record-level security
        // Required fields (Capacity__c, Course_Code__c) cannot have FLS in permission sets
        // so WITH USER_MODE is not used here to prevent blocking non-admin users
        String queryStr = 'SELECT Id, Name, Course_Code__c, Description__c, Credits__c, Capacity__c, Status__c, Fees__c, Type__c FROM Course__c WHERE Status__c = \'Active\'';
        if (String.isNotBlank(type)) {
            queryStr += ' AND Type__c = :type';
        }
        List<Course__c> courses = Database.query(queryStr);
        
        // Aggregate admissions count grouped by Course__c
        Map<Id, Integer> courseEnrolledMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Course__c, COUNT(Id) enrolledCount 
            FROM Admission__c 
            GROUP BY Course__c
        ]) {
            courseEnrolledMap.put((Id)ar.get('Course__c'), (Integer)ar.get('enrolledCount'));
        }
        
        for (Course__c course : courses) {
            Integer enrolled = courseEnrolledMap.containsKey(course.Id) ? courseEnrolledMap.get(course.Id) : 0;
            Integer remaining = (Integer)course.Capacity__c - enrolled;
            results.add(new CourseWrapper(course, enrolled, remaining));
        }
        
        return results;
    }
    
    public class CourseWrapper {
        @AuraEnabled public Course__c course {get; set;}
        @AuraEnabled public Integer enrolledSeats {get; set;}
        @AuraEnabled public Integer remainingSeats {get; set;}
        
        public CourseWrapper(Course__c c, Integer enrolled, Integer remaining) {
            this.course = c;
            this.enrolledSeats = enrolled;
            this.remainingSeats = remaining;
        }
    }
}
