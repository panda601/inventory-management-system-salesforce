public with sharing class ProductImageController {
    @AuraEnabled(cacheable=true)
    public static Boolean isProductImageAdmin() {
        Profile profileRecord = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        if (profileRecord.Name == 'System Administrator') {
            return true;
        }

        for (PermissionSetAssignment assignment : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            WITH USER_MODE
        ]) {
            if (assignment.PermissionSet.Name == 'Admin_Access') {
                return true;
            }
        }
        return false;
    }

    @AuraEnabled
    public static void deleteProductImage(Id productId) {
        if (productId == null) {
            throw new AuraHandledException('Product ID cannot be null.');
        }

        if (!isProductImageAdmin()) {
            throw new AuraHandledException('You do not have permission to delete product images.');
        }

        // Query ContentDocumentLink
        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :productId
            WITH USER_MODE
        ];

        if (cdls.isEmpty()) {
            return;
        }

        List<Id> docIds = new List<Id>();
        for (ContentDocumentLink cdl : cdls) {
            docIds.add(cdl.ContentDocumentId);
        }

        // Query latest ContentVersion for those ContentDocuments that are images to prevent deleting unrelated files if any
        List<ContentVersion> cvs = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
            AND IsLatest = true
            AND FileExtension IN ('jpg', 'jpeg', 'png', 'webp')
            WITH USER_MODE
        ];

        if (cvs.isEmpty()) {
            return;
        }

        List<ContentDocument> docsToDelete = new List<ContentDocument>();
        for (ContentVersion cv : cvs) {
            docsToDelete.add(new ContentDocument(Id = cv.ContentDocumentId));
        }

        if (!docsToDelete.isEmpty()) {
            try {
                // Delete docs
                delete docsToDelete;
            } catch (Exception e) {
                throw new AuraHandledException('Error deleting product image: ' + e.getMessage());
            }
        }
    }

    @AuraEnabled
    public static void deleteOldImages(Id productId, Id newContentDocumentId) {
        if (productId == null || newContentDocumentId == null) {
            return;
        }
        
        if (!isProductImageAdmin()) {
            throw new AuraHandledException('You do not have permission to modify product images.');
        }
        
        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :productId
            AND ContentDocumentId != :newContentDocumentId
            WITH USER_MODE
        ];
        
        if (cdls.isEmpty()) {
            return;
        }
        
        List<Id> docIds = new List<Id>();
        for (ContentDocumentLink cdl : cdls) {
            docIds.add(cdl.ContentDocumentId);
        }
        
        List<ContentVersion> cvs = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
            AND IsLatest = true
            AND FileExtension IN ('jpg', 'jpeg', 'png', 'webp')
            WITH USER_MODE
        ];
        
        if (cvs.isEmpty()) {
            return;
        }
        
        List<ContentDocument> docsToDelete = new List<ContentDocument>();
        for (ContentVersion cv : cvs) {
            docsToDelete.add(new ContentDocument(Id = cv.ContentDocumentId));
        }
        
        if (!docsToDelete.isEmpty()) {
            try {
                delete docsToDelete;
            } catch (Exception e) {
                throw new AuraHandledException('Error cleaning up replaced image: ' + e.getMessage());
            }
        }
    }
}
