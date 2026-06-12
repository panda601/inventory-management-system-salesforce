// 1. Delete duplicate ContentDocuments (keep oldest)
Map<String, Id> uniqueFileMap = new Map<String, Id>();
List<ContentDocument> docsToDelete = new List<ContentDocument>();

for (ContentDocument cd : [
    SELECT Id, Title, FileExtension, ContentSize, CreatedDate 
    FROM ContentDocument 
    ORDER BY CreatedDate ASC
]) {
    String key = cd.Title.trim().toLowerCase() + '|' + 
                 cd.FileExtension.trim().toLowerCase() + '|' + 
                 cd.ContentSize;
    if (uniqueFileMap.containsKey(key)) {
        docsToDelete.add(cd);
    } else {
        uniqueFileMap.put(key, cd.Id);
    }
}

if (!docsToDelete.isEmpty()) {
    delete docsToDelete;
    System.debug('STORAGE_CLEANUP: Deleted ' + docsToDelete.size() + ' duplicate ContentDocument records.');
} else {
    System.debug('STORAGE_CLEANUP: No duplicate ContentDocuments found.');
}

// 2. Delete test / duplicate records (applications, payments, admissions)
List<Student_Application__c> appsToDelete = [
    SELECT Id 
    FROM Student_Application__c 
    WHERE CreatedDate <= 2026-06-08T23:59:59Z 
       OR First_Name__c LIKE '%Test%' 
       OR First_Name__c LIKE '%Demo%' 
       OR First_Name__c LIKE '%Reject%' 
       OR First_Name__c LIKE '%Approve%' 
       OR First_Name__c LIKE '%PayTest%' 
       OR First_Name__c LIKE '%CA%' 
       OR First_Name__c LIKE '%CB%'
];

if (!appsToDelete.isEmpty()) {
    Set<Id> appIds = new Map<Id, Student_Application__c>(appsToDelete).keySet();
    
    // Delete related admissions, payments, and document custom records first
    List<Admission__c> admissionsToDelete = [SELECT Id FROM Admission__c WHERE Student_Application__c IN :appIds];
    if (!admissionsToDelete.isEmpty()) {
        delete admissionsToDelete;
    }
    
    List<Payment__c> paymentsToDelete = [SELECT Id FROM Payment__c WHERE Student_Application__c IN :appIds];
    if (!paymentsToDelete.isEmpty()) {
        delete paymentsToDelete;
    }
    
    List<Document__c> docsListToDelete = [SELECT Id FROM Document__c WHERE Student_Application__c IN :appIds];
    if (!docsListToDelete.isEmpty()) {
        delete docsListToDelete;
    }
    
    delete appsToDelete;
    System.debug('STORAGE_CLEANUP: Deleted ' + appsToDelete.size() + ' test/duplicate Student_Application__c records.');
} else {
    System.debug('STORAGE_CLEANUP: No old test Student_Application__c records found.');
}
