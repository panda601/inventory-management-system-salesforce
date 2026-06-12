import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import STATUS_FIELD from '@salesforce/schema/Student_Application__c.Application_Status__c';
import DOC_STATUS_FIELD from '@salesforce/schema/Student_Application__c.Document_Status__c';
import ADM_STATUS_FIELD from '@salesforce/schema/Student_Application__c.Admission_Status__c';
import PAYMENT_STATUS_FIELD from '@salesforce/schema/Student_Application__c.Payment_Status__c';
import NAME_FIELD from '@salesforce/schema/Student_Application__c.Name';

const FIELDS = [STATUS_FIELD, DOC_STATUS_FIELD, ADM_STATUS_FIELD, PAYMENT_STATUS_FIELD, NAME_FIELD];

// Exact 8 UAT Stages (Phase 4)
const STAGE_SEQUENCE = [
    'Submitted', 
    'Under Review', 
    'Document Verification', 
    'Approved', 
    'Payment Pending', 
    'Paid', 
    'Admission Created', 
    'Enrolled'
];

export default class ApplicationStatusTracker extends LightningElement {
    @api recordId;
    @api objectApiName;

    application;
    status = 'Draft';
    docStatus = 'Pending';
    admStatus = 'Pending';
    paymentStatus = 'Pending';
    applicationNumber = '';
    error;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.application = data;
            this.status = data.fields.Application_Status__c.value || 'Draft';
            this.docStatus = data.fields.Document_Status__c.value || 'Pending';
            this.admStatus = data.fields.Admission_Status__c.value || 'Pending';
            this.paymentStatus = data.fields.Payment_Status__c?.value || 'Pending';
            this.applicationNumber = data.fields.Name.value || '';
            this.error = undefined;
        } else if (error) {
            this.error = error;
            console.error('Error loading application record:', error);
        }
    }

    // Dynamic 8-stage label resolution
    get currentStageLabel() {
        if (this.isRejected) {
            return 'Rejected';
        }
        
        // 8. Enrolled (Admission Status is Admitted)
        if (this.admStatus === 'Admitted' || this.status === 'Admitted') {
            return 'Enrolled';
        }
        
        // 7. Admission Created (Admission Status is Pending and status is Paid)
        if (this.admStatus === 'Pending' && this.status === 'Paid') {
            return 'Admission Created';
        }
        
        // 6. Paid (Application status is Paid / Fee Paid, or payment status is Paid)
        if (this.status === 'Paid' || this.paymentStatus === 'Paid') {
            return 'Paid';
        }
        
        // 5. Payment Pending (Status is Payment Pending, or status is Approved but payment is Pending)
        if (this.status === 'Payment Pending' || (this.status === 'Approved' && this.paymentStatus === 'Pending')) {
            return 'Payment Pending';
        }
        
        // 4. Approved (Status is Approved)
        if (this.status === 'Approved') {
            return 'Approved';
        }
        
        // 3. Document Verification (Document status is Verified)
        if (this.docStatus === 'Verified') {
            return 'Document Verification';
        }
        
        // 2. Under Review (Status is Under Review or Document Status is Uploaded)
        if (this.status === 'Under Review' || this.docStatus === 'Uploaded') {
            return 'Under Review';
        }
        
        // 1. Submitted (default submitted state)
        return 'Submitted';
    }

    get timelineSteps() {
        const currentIndex = STAGE_SEQUENCE.indexOf(this.currentStageLabel);
        const rejectedIndex = this.getRejectedStageIndex();

        return STAGE_SEQUENCE.map((stage, index) => {
            let itemClass = 'timeline-step';
            let iconName = 'utility:lock';
            let iconVariant = '';
            let statusTag = 'Pending';

            if (this.isRejected) {
                if (index < rejectedIndex) {
                    itemClass += ' step-completed';
                    iconName = 'utility:check';
                    iconVariant = 'inverse';
                    statusTag = 'Completed';
                } else if (index === rejectedIndex) {
                    itemClass += ' step-rejected';
                    iconName = 'utility:close';
                    iconVariant = 'inverse';
                    statusTag = 'Rejected';
                } else {
                    itemClass += ' step-pending';
                }
            } else if (index < currentIndex) {
                itemClass += ' step-completed';
                iconName = 'utility:check';
                iconVariant = 'inverse';
                statusTag = 'Completed';
            } else if (index === currentIndex) {
                itemClass += ' step-active';
                iconName = 'utility:clock';
                iconVariant = 'inverse';
                statusTag = 'Current';
            } else {
                itemClass += ' step-pending';
            }

            return {
                label: stage,
                value: stage,
                itemClass,
                iconName,
                iconVariant,
                statusTag
            };
        });
    }

    get isRejected() {
        return this.status === 'Rejected' || this.docStatus === 'Rejected' || this.admStatus === 'Rejected';
    }

    get isApproved() {
        return ['Approved', 'Payment Pending', 'Paid', 'Admission Created', 'Enrolled'].includes(this.currentStageLabel);
    }

    get statusDescription() {
        if (this.isRejected) {
            return 'The application requires attention because a review stage resulted in rejection. Please check document or admission feedback for the latest decision.';
        }

        switch (this.currentStageLabel) {
            case 'Submitted':
                return 'The application has been submitted successfully and is waiting to enter the admissions review queue.';
            case 'Under Review':
                return 'Admissions is reviewing the submitted application and uploaded documents before the final verification decision.';
            case 'Document Verification':
                return 'All required documents are verified and the application is ready for the admissions approval decision.';
            case 'Approved':
                return 'The application is approved and is ready to move into the payment stage.';
            case 'Payment Pending':
                return 'The application is approved. Tuition payment is pending before the record can move to the fee paid stage.';
            case 'Paid':
                return 'Payment is complete and the application is waiting for final admission confirmation.';
            case 'Admission Created':
                return 'The admission record has been created and is being finalized.';
            case 'Enrolled':
                return 'The admission process is complete and the student has been admitted to the selected program.';
            default:
                return 'Application progress is being updated.';
        }
    }

    get statusHeaderClass() {
        if (this.isRejected) {
            return 'status-header-text text-rejected';
        }
        if (this.isApproved) {
            return 'status-header-text text-approved';
        }
        return 'status-header-text text-primary';
    }

    get docBadgeClass() {
        switch (this.docStatus) {
            case 'Verified':
                return 'badge-success';
            case 'Rejected':
                return 'badge-error';
            case 'Uploaded':
                return 'badge-info';
            case 'Pending':
            default:
                return 'badge-warning';
        }
    }

    get admBadgeClass() {
        switch (this.admStatus) {
            case 'Admitted':
                return 'badge-success';
            case 'Rejected':
            case 'Cancelled':
                return 'badge-error';
            case 'Waitlisted':
                return 'badge-info';
            case 'Pending':
            default:
                return 'badge-warning';
        }
    }

    get paymentBadgeClass() {
        switch (this.paymentStatus) {
            case 'Paid':
                return 'badge-success';
            case 'Failed':
                return 'badge-error';
            case 'Pending':
            default:
                return 'badge-warning';
        }
    }

    getRejectedStageIndex() {
        if (this.docStatus === 'Rejected') {
            return STAGE_SEQUENCE.indexOf('Under Review');
        }
        if (this.status === 'Rejected' && this.docStatus === 'Verified') {
            return STAGE_SEQUENCE.indexOf('Document Verification');
        }
        return STAGE_SEQUENCE.indexOf('Under Review');
    }
}
