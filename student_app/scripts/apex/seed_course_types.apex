List<Course__c> coursesToUpdate = new List<Course__c>();
for (Course__c c : [SELECT Id, Name, Type__c FROM Course__c WHERE Status__c = 'Active']) {
    String name = c.Name.toLowerCase();
    if (name.contains('bachelor') || name.contains('intro to cs') || name.contains('data structures') || name.contains('database management') || name.contains('software engineering')) {
        c.Type__c = 'Undergraduate';
        coursesToUpdate.add(c);
    } else if (name.contains('artificial intelligence') || name.contains('master of business') || name.contains('mtech') || name.contains('mba')) {
        c.Type__c = 'Postgraduate';
        coursesToUpdate.add(c);
    } else if (name.contains('diploma') || name.contains('salesforce admin')) {
        c.Type__c = 'Diploma';
        coursesToUpdate.add(c);
    } else {
        // Fallback or capacity test
        c.Type__c = 'Undergraduate';
        coursesToUpdate.add(c);
    }
}
if (!coursesToUpdate.isEmpty()) {
    update coursesToUpdate;
    System.debug('Successfully updated ' + coursesToUpdate.size() + ' course types.');
} else {
    System.debug('No active courses found to update.');
}
