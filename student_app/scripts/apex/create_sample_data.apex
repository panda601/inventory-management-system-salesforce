// 1. Create Courses
List<Course__c> courses = new List<Course__c>{
    new Course__c(Name = 'Introduction to Computer Science', Course_Code__c = 'CS101', Credits__c = 4, Capacity__c = 50, Status__c = 'Active', Fees__c = 1500.00),
    new Course__c(Name = 'Advanced Calculus', Course_Code__c = 'MATH301', Credits__c = 3, Capacity__c = 30, Status__c = 'Active', Fees__c = 1200.00),
    new Course__c(Name = 'Data Science & Machine Learning', Course_Code__c = 'DS202', Credits__c = 4, Capacity__c = 40, Status__c = 'Active', Fees__c = 1800.00)
};
insert courses;

// 2. Create Student Applications
List<Student_Application__c> apps = new List<Student_Application__c>{
    new Student_Application__c(First_Name__c = 'Alice', Last_Name__c = 'Smith', Email__c = 'alice.smith@example.com', Date_of_Birth__c = Date.newInstance(2005, 4, 15), Applied_Course__c = courses[0].Id, Application_Status__c = 'Draft'),
    new Student_Application__c(First_Name__c = 'Bob', Last_Name__c = 'Johnson', Email__c = 'bob.johnson@example.com', Date_of_Birth__c = Date.newInstance(2004, 11, 22), Applied_Course__c = courses[1].Id, Application_Status__c = 'Submitted'),
    new Student_Application__c(First_Name__c = 'Charlie', Last_Name__c = 'Brown', Email__c = 'charlie.brown@example.com', Date_of_Birth__c = Date.newInstance(2003, 7, 30), Applied_Course__c = courses[2].Id, Application_Status__c = 'Under Review')
};
insert apps;

// 3. Create Verification Documents for the applications
List<Document__c> docs = new List<Document__c>{
    new Document__c(Name = 'Alice Academic Transcript', Student_Application__c = apps[0].Id, Document_Type__c = 'Academic Transcript', Verification_Status__c = 'Pending'),
    new Document__c(Name = 'Alice ID Card', Student_Application__c = apps[0].Id, Document_Type__c = 'Identity Proof', Verification_Status__c = 'Pending'),
    new Document__c(Name = 'Bob Academic Transcript', Student_Application__c = apps[1].Id, Document_Type__c = 'Academic Transcript', Verification_Status__c = 'Pending'),
    new Document__c(Name = 'Bob ID Card', Student_Application__c = apps[1].Id, Document_Type__c = 'Identity Proof', Verification_Status__c = 'Pending'),
    new Document__c(Name = 'Charlie Academic Transcript', Student_Application__c = apps[2].Id, Document_Type__c = 'Academic Transcript', Verification_Status__c = 'Pending'),
    new Document__c(Name = 'Charlie ID Card', Student_Application__c = apps[2].Id, Document_Type__c = 'Identity Proof', Verification_Status__c = 'Pending')
};
insert docs;

System.debug('Sample test data successfully generated! Courses: 3, Applications: 3, Documents: 6.');
