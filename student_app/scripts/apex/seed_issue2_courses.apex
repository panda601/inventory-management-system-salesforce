List<Course__c> newCourses = new List<Course__c>();

// Helper to check if a course already exists
Map<String, Course__c> existingMap = new Map<String, Course__c>();
for (Course__c c : [SELECT Id, Course_Code__c FROM Course__c]) {
    existingMap.put(c.Course_Code__c, c);
}

// BTech
if (!existingMap.containsKey('BTECH-101')) {
    newCourses.add(new Course__c(
        Name = 'BTech in Computer Science',
        Course_Code__c = 'BTECH-101',
        Type__c = 'Undergraduate',
        Credits__c = 80,
        Capacity__c = 50,
        Status__c = 'Active',
        Fees__c = 120000,
        Description__c = 'Four-year undergraduate degree program focusing on software engineering, algorithms, and computing systems.'
    ));
}

// BCA
if (!existingMap.containsKey('BCA-102')) {
    newCourses.add(new Course__c(
        Name = 'BCA in Software Development',
        Course_Code__c = 'BCA-102',
        Type__c = 'Undergraduate',
        Credits__c = 60,
        Capacity__c = 45,
        Status__c = 'Active',
        Fees__c = 75000,
        Description__c = 'Three-year professional undergraduate degree program in computer applications and information technology.'
    ));
}

// MCA
if (!existingMap.containsKey('MCA-201')) {
    newCourses.add(new Course__c(
        Name = 'MCA in Cloud Computing',
        Course_Code__c = 'MCA-201',
        Type__c = 'Postgraduate',
        Credits__c = 90,
        Capacity__c = 40,
        Status__c = 'Active',
        Fees__c = 95000,
        Description__c = 'Two-year postgraduate degree program with advanced training in database systems and cloud architecture.'
    ));
}

// MBA (Update existing MBA-201 name to contain 'MBA' explicitly if needed, or insert if not present)
if (!existingMap.containsKey('MBA-201')) {
    newCourses.add(new Course__c(
        Name = 'MBA in Business Analytics',
        Course_Code__c = 'MBA-201',
        Type__c = 'Postgraduate',
        Credits__c = 90,
        Capacity__c = 40,
        Status__c = 'Active',
        Fees__c = 150000,
        Description__c = 'Two-year postgraduate business program specializing in data-driven decisions and managerial analytics.'
    ));
}

// MTech
if (!existingMap.containsKey('MTECH-301')) {
    newCourses.add(new Course__c(
        Name = 'MTech in Artificial Intelligence',
        Course_Code__c = 'MTECH-301',
        Type__c = 'Postgraduate',
        Credits__c = 95,
        Capacity__c = 30,
        Status__c = 'Active',
        Fees__c = 180000,
        Description__c = 'Two-year research-focused postgraduate engineering program specializing in machine learning and robotics.'
    ));
}

if (!newCourses.isEmpty()) {
    insert newCourses;
    System.debug('Seeded ' + newCourses.size() + ' new courses.');
} else {
    System.debug('Courses already seeded.');
}
