public without sharing class AdmissionController {
    @AuraEnabled(cacheable=true)
    public static Admission__c getAdmissionSummary(Id admissionId) {
        if (admissionId == null) {
            return null;
        }
        
        // Query the admission to find the application Id in System Mode
        List<Admission__c> admissions = [
            SELECT Id, Student_Application__c
            FROM Admission__c
            WHERE Id = :admissionId
            LIMIT 1
        ];
        if (admissions.isEmpty()) {
            return null;
        }
        
        verifyApplicationOwnership(admissions[0].Student_Application__c);
        
        return [
            SELECT Id, Name, Student_Application__c, Student_Name__c, Enrollment_Number__c, Fees_Paid__c, Admission_Date__c,
                   Course__r.Name, Course__r.Course_Code__c, Course__r.Credits__c, Course__r.Fees__c,
                   Student_Application__r.First_Name__c, Student_Application__r.Last_Name__c, Student_Application__r.Email__c, Student_Application__r.Phone__c
            FROM Admission__c
            WHERE Id = :admissionId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Admission__c getAdmissionByApplication(Id appId) {
        if (appId == null) {
            return null;
        }
        
        verifyApplicationOwnership(appId);
        
        List<Admission__c> admissions = [
            SELECT Id, Name, Student_Application__c, Student_Name__c, Enrollment_Number__c, Fees_Paid__c, Admission_Date__c,
                   Course__r.Name, Course__r.Course_Code__c, Course__r.Credits__c, Course__r.Fees__c,
                   Student_Application__r.First_Name__c, Student_Application__r.Last_Name__c, Student_Application__r.Email__c, Student_Application__r.Phone__c
            FROM Admission__c
            WHERE Student_Application__c = :appId
            LIMIT 1
        ];
        return admissions.isEmpty() ? null : admissions[0];
    }

    private static void verifyApplicationOwnership(Id appId) {
        if (appId == null) {
            throw new AuraHandledException('Invalid Application Reference.');
        }
        Id userId = UserInfo.getUserId();
        
        User currentUser = [
            SELECT Id, Email, Username, Contact.Email 
            FROM User 
            WHERE Id = :userId 
            LIMIT 1
        ];
        
        String userEmail = currentUser.Email;
        String cleanUserEmail = userEmail != null ? userEmail.replace('.invalid', '') : '';
        String contactEmail = currentUser.Contact?.Email;
        String cleanContactEmail = contactEmail != null ? contactEmail.replace('.invalid', '') : '';
        String username = currentUser.Username;
        String cleanUsername = username != null ? username.substringBeforeLast('.studentapp') : '';
        String infoEmail = UserInfo.getUserEmail();
        String cleanInfoEmail = infoEmail != null ? infoEmail.replace('.invalid', '') : '';

        Set<String> possibleEmails = new Set<String>{
            userEmail, cleanUserEmail,
            contactEmail, cleanContactEmail,
            username, cleanUsername,
            infoEmail, cleanInfoEmail
        };
        possibleEmails.remove(null);
        possibleEmails.remove('');

        List<Student_Application__c> apps = [
            SELECT Id 
            FROM Student_Application__c
            WHERE Id = :appId 
              AND (OwnerId = :userId OR Email__c IN :possibleEmails)
        ];
        if (apps.isEmpty()) {
            throw new AuraHandledException('Unauthorized access to application admission details.');
        }
    }
}
