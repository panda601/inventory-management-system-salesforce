import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getRelatedDocuments from '@salesforce/apex/StudentApplicationController.getRelatedDocuments';

export default class DocumentViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    @track documents = [];
    @track isLoading = false;
    @track error;

    wiredDocsResult;

    @wire(getRelatedDocuments, { appId: '$recordId' })
    wiredDocs(result) {
        this.wiredDocsResult = result;
        this.isLoading = false;
        if (result.data) {
            this.documents = result.data.map(docWrap => {
                const status = docWrap.document.Verification_Status__c;
                const versionId = docWrap.latestVersionId;
                const hasThumb = !!versionId;
                const thumbUrl = hasThumb ? `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB240BY180&versionId=${versionId}` : '';
                return {
                    ...docWrap,
                    statusClass: this.getStatusBadgeClass(status),
                    isRejected: status === 'Rejected',
                    hasThumbnail: hasThumb,
                    thumbnailUrl: thumbUrl,
                    iconName: this.getFileIcon(docWrap.document.Name),
                    uploadDate: docWrap.document.CreatedDate ? new Date(docWrap.document.CreatedDate).toLocaleDateString() : ''
                };
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            console.error('Error loading documents:', result.error);
        }
    }

    getFileIcon(fileName) {
        if (!fileName) return 'doctype:attachment';
        const ext = fileName.split('.').pop().toLowerCase();
        switch (ext) {
            case 'pdf': return 'doctype:pdf';
            case 'png':
            case 'jpg':
            case 'jpeg':
            case 'gif':
                return 'doctype:image';
            case 'doc':
            case 'docx':
                return 'doctype:word';
            case 'xls':
            case 'xlsx':
                return 'doctype:excel';
            default:
                return 'doctype:attachment';
        }
    }

    getStatusBadgeClass(status) {
        switch (status) {
            case 'Verified':
                return 'slds-badge slds-theme_success badge-custom';
            case 'Rejected':
                return 'slds-badge slds-theme_error badge-custom';
            case 'Pending':
            default:
                return 'slds-badge slds-theme_warning badge-custom';
        }
    }

    get hasDocuments() {
        return this.documents && this.documents.length > 0;
    }

    // Preview File using filePreview named page
    handlePreview(event) {
        const cdId = event.currentTarget.dataset.cdId;
        if (!cdId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: cdId
            }
        });
    }

    // Open ContentDocument detail page
    handleOpen(event) {
        const cdId = event.currentTarget.dataset.cdId;
        if (!cdId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: cdId,
                actionName: 'view'
            }
        });
    }

    // Download File via Shepherd servlet
    handleDownload(event) {
        const cdId = event.currentTarget.dataset.cdId;
        if (!cdId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/sfc/servlet.shepherd/document/download/${cdId}`
            }
        });
    }

    @api
    async refresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredDocsResult);
        } catch (err) {
            console.error('Error refreshing documents:', err);
        } finally {
            this.isLoading = false;
        }
    }
}
