public with sharing class StudentApplicationController {
    // Save new application
    @AuraEnabled
    public static Student_Application__c saveApplication(Map<String, Object> appData) {
        if (appData == null || appData.isEmpty()) {
            throw new AuraHandledException('Application details are required.');
        }
        
        Student_Application__c app = new Student_Application__c();
        app.First_Name__c = getTrimmedValue(appData.get('firstName'));
        app.Last_Name__c = getTrimmedValue(appData.get('lastName'));
        app.Email__c = getTrimmedValue(appData.get('email'));
        app.Phone__c = getTrimmedValue(appData.get('phone'));
        
        String dobString = getTrimmedValue(appData.get('dob'));
        if (String.isNotBlank(dobString)) {
            app.Date_of_Birth__c = Date.valueOf(dobString);
        }
        
        app.Applied_Course__c = requireTypedId(
            getTrimmedValue(appData.get('courseId')),
            Schema.Course__c.SObjectType,
            'course'
        );
        app.Application_Status__c = Constants.APP_STATUS_DRAFT;
        
        Id recordTypeId = parseStudentApplicationRecordTypeId(getTrimmedValue(appData.get('recordTypeId')));
        if (recordTypeId != null) {
            app.RecordTypeId = recordTypeId;
        }
        
        insert as user app;
        return app;
    }
    
    // Submit application for approval
    @AuraEnabled
    public static void submitApplication(String appId) {
        Id applicationId = requireTypedId(appId, Schema.Student_Application__c.SObjectType, 'student application');
        Student_Application__c app = [
            SELECT Id, Application_Status__c, Document_Status__c 
            FROM Student_Application__c 
            WHERE Id = :applicationId
            WITH USER_MODE
        ];
        
        // Instantiate a clean record to avoid updating read-only fields (like Document_Status__c) that were queried
        Student_Application__c appToUpdate = new Student_Application__c(
            Id = app.Id,
            Application_Status__c = Constants.APP_STATUS_SUBMITTED
        );
        update as user appToUpdate;
        
        // Submit to approval process programmatically
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitted automatically from Student Portal.');
        req.setObjectId(app.Id);
        Approval.process(req);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Student_Application__c> getMyApplications() {
        Id userId = UserInfo.getUserId();
        
        // Fetch current user details in System Mode to ensure we get contact/email details
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

        StudentApplicationDataHelper helper = new StudentApplicationDataHelper();
        return helper.queryMyApplications(userId, possibleEmails);
    }
    
    // Get related custom Document__c records and their ContentDocumentIds for file preview
    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getRelatedDocuments(String appId) {
        List<DocumentWrapper> wrappers = new List<DocumentWrapper>();
        Id applicationId = parseTypedId(appId, Schema.Student_Application__c.SObjectType, 'student application');
        if (applicationId == null) {
            return wrappers;
        }
        
        // Verify user owns/matches the application first
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

        StudentApplicationDataHelper helper = new StudentApplicationDataHelper();
        List<Student_Application__c> verifiedApps = helper.queryMyApplications(userId, possibleEmails);
        
        Boolean isVerified = false;
        for (Student_Application__c app : verifiedApps) {
            if (app.Id == applicationId) {
                isVerified = true;
                break;
            }
        }
        
        if (!isVerified) {
            return wrappers; // Unauthorized access
        }
        
        return helper.queryRelatedDocuments(applicationId);
    }
    
    public class DocumentWrapper {
        @AuraEnabled public Document__c document {get; set;}
        @AuraEnabled public Id contentDocumentId {get; set;}
        @AuraEnabled public Id latestVersionId {get; set;}
        
        public DocumentWrapper(Document__c doc, Id cdlId, Id versionId) {
            this.document = doc;
            this.contentDocumentId = cdlId;
            this.latestVersionId = versionId;
        }
    }
    
    // Link content document to custom Document__c record
    @AuraEnabled
    public static Document__c createDocumentRecord(String appId, String docType, String contentDocId, String fileName) {
        Id applicationId = requireTypedId(appId, Schema.Student_Application__c.SObjectType, 'student application');
        Id linkedContentDocumentId = requireTypedId(contentDocId, Schema.ContentDocument.SObjectType, 'content document');
        String documentType = getTrimmedValue(docType);
        
        if (String.isBlank(documentType)) {
            throw new AuraHandledException('Document type is required.');
        }
        
        // Use system-mode helper class (without sharing) to bypass FLS/sharing rules on Document__c and parent app
        DocumentLinkerHelper helper = new DocumentLinkerHelper();
        return helper.createDocumentAndLink(applicationId, documentType, fileName, linkedContentDocumentId);
    }
    
    // System-mode helper to bypass FLS on read-only/parent fields and link ContentDocumentLink
    private without sharing class DocumentLinkerHelper {
        public Document__c createDocumentAndLink(Id applicationId, String documentType, String fileName, Id linkedContentDocumentId) {
            Document__c doc = new Document__c();
            doc.Student_Application__c = applicationId;
            doc.Document_Type__c = documentType;
            doc.Name = String.isBlank(fileName) ? documentType : fileName.trim();
            doc.Verification_Status__c = Constants.VERIFY_STATUS_PENDING;
            insert doc;
            
            // Link ContentDocument to the newly created Document__c in System Mode
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = linkedContentDocumentId;
            cdl.LinkedEntityId = doc.Id;
            cdl.ShareType = 'V';
            insert cdl;
            
            // Update parent Student_Application__c Document_Status__c to 'Uploaded' in System Mode
            Student_Application__c parentApp = new Student_Application__c(
                Id = applicationId,
                Document_Status__c = 'Uploaded'
            );
            update parentApp;
            
            return doc;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getRecordTypes() {
        Map<String, Id> rtMap = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SobjectType = 'Student_Application__c' AND IsActive = true
        ]) {
            rtMap.put(rt.DeveloperName, rt.Id);
        }
        return rtMap;
    }
    
    @AuraEnabled
    public static void processPaymentAndSubmit(String appId, String paymentMethod, Decimal amount) {
        Id applicationId = requireTypedId(appId, Schema.Student_Application__c.SObjectType, 'student application');
        if (String.isBlank(paymentMethod)) {
            throw new AuraHandledException('Payment method is required.');
        }
        if (amount == null || amount <= 0) {
            throw new AuraHandledException('A valid payment amount is required.');
        }
        
        Student_Application__c app = [
            SELECT Id, Applied_Course__c, Application_Status__c
            FROM Student_Application__c
            WHERE Id = :applicationId
            WITH SYSTEM_MODE
        ];
        
        if (app.Applied_Course__c == null) {
            throw new AuraHandledException('Please select a course before submitting payment.');
        }
        
        PaymentCompleterHelper helper = new PaymentCompleterHelper();
        helper.completePayment(applicationId, paymentMethod, amount);
        
        if (app.Application_Status__c == 'Draft') {
            submitApplication(String.valueOf(applicationId));
        }
    }
    
    private without sharing class PaymentCompleterHelper {
        public void completePayment(Id applicationId, String paymentMethod, Decimal amount) {
            List<Payment__c> payments = [
                SELECT Id, Payment_Status__c, Payment_Method__c, Amount__c, Payment_Date__c, Transaction_Id__c 
                FROM Payment__c 
                WHERE Student_Application__c = :applicationId
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            Payment__c pay;
            if (!payments.isEmpty()) {
                pay = payments[0];
            } else {
                pay = new Payment__c();
                pay.Student_Application__c = applicationId;
            }
            
            pay.Payment_Method__c = paymentMethod.trim();
            pay.Amount__c = amount;
            pay.Payment_Date__c = System.today();
            pay.Payment_Status__c = 'Paid';
            pay.Transaction_Id__c = 'TXN-' + String.valueOf(Crypto.getRandomInteger()).substring(1, 8);
            
            upsert pay;
        }
    }
    
    private static String getTrimmedValue(Object rawValue) {
        return rawValue == null ? null : String.valueOf(rawValue).trim();
    }
    
    private static Id requireTypedId(String rawId, Schema.SObjectType expectedType, String entityLabel) {
        Id typedId = parseTypedId(rawId, expectedType, entityLabel);
        if (typedId == null) {
            throw new AuraHandledException(entityLabel.substring(0, 1).toUpperCase() + entityLabel.substring(1) + ' is required.');
        }
        return typedId;
    }
    
    private static Id parseTypedId(String rawId, Schema.SObjectType expectedType, String entityLabel) {
        if (String.isBlank(rawId)) {
            return null;
        }
        
        Id typedId;
        try {
            typedId = Id.valueOf(rawId.trim());
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid ' + entityLabel + ' reference.');
        }
        
        String expectedPrefix = expectedType.getDescribe().getKeyPrefix();
        if (String.isNotBlank(expectedPrefix) && !String.valueOf(typedId).startsWith(expectedPrefix)) {
            throw new AuraHandledException('Invalid ' + entityLabel + ' reference.');
        }
        
        return typedId;
    }
    
    private static Id parseStudentApplicationRecordTypeId(String rawRecordTypeId) {
        if (String.isBlank(rawRecordTypeId)) {
            return null;
        }

        Id recordTypeId;
        try {
            recordTypeId = Id.valueOf(rawRecordTypeId.trim());
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid record type reference.');
        }

        if (!String.valueOf(recordTypeId).startsWith('012')) {
            throw new AuraHandledException('Invalid record type reference.');
        }
        
        List<RecordType> recordTypes = [
            SELECT Id
            FROM RecordType
            WHERE Id = :recordTypeId
              AND SObjectType = 'Student_Application__c'
              AND IsActive = true
            LIMIT 1
        ];
        
        if (recordTypes.isEmpty()) {
            throw new AuraHandledException('Selected program type is unavailable.');
        }
        
        return recordTypeId;
    }

    private without sharing class StudentApplicationDataHelper {
        public List<Student_Application__c> queryMyApplications(Id userId, Set<String> possibleEmails) {
            return [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c, Date_of_Birth__c, 
                       Applied_Course__c, Applied_Course__r.Name, Applied_Course__r.Fees__c, Applied_Course__r.Course_Code__c, Applied_Course__r.Type__c, Application_Status__c, Document_Status__c,
                       Admission_Status__c, Payment_Status__c, CreatedDate, LastModifiedDate, RecordType.Name,
                       (SELECT Id, Payment_Number__c, Payment_Status__c, Amount__c, Payment_Method__c, Payment_Date__c, Transaction_Id__c, Receipt_Number__c FROM Payments__r ORDER BY CreatedDate DESC)
                FROM Student_Application__c
                WHERE OwnerId = :userId 
                   OR Email__c IN :possibleEmails
                ORDER BY CreatedDate DESC
            ];
        }

        public List<DocumentWrapper> queryRelatedDocuments(Id applicationId) {
            List<DocumentWrapper> wrappers = new List<DocumentWrapper>();
            List<Document__c> docs = [
                SELECT Id, Name, Document_Type__c, Verification_Status__c, Rejection_Reason__c, CreatedDate,
                       (SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLinks LIMIT 1)
                FROM Document__c 
                WHERE Student_Application__c = :applicationId
            ];
            
            for (Document__c doc : docs) {
                Id contentDocId = null;
                Id versionId = null;
                if (doc.ContentDocumentLinks != null && !doc.ContentDocumentLinks.isEmpty()) {
                    contentDocId = doc.ContentDocumentLinks[0].ContentDocumentId;
                    versionId = doc.ContentDocumentLinks[0].ContentDocument.LatestPublishedVersionId;
                }
                wrappers.add(new DocumentWrapper(doc, contentDocId, versionId));
            }
            return wrappers;
        }
    }
}
