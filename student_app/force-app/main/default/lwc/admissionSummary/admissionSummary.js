import { LightningElement, api, wire, track } from 'lwc';
import getAdmissionSummary from '@salesforce/apex/AdmissionController.getAdmissionSummary';
import getAdmissionByApplication from '@salesforce/apex/AdmissionController.getAdmissionByApplication';

export default class AdmissionSummary extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track admission;
    @track error;
    @track noAdmissionFound = false;

    // Wire by Admission ID (if placed on Admission record page)
    @wire(getAdmissionSummary, { admissionId: '$recordId' })
    wiredAdmission({ error, data }) {
        if (this.objectApiName === 'Admission__c') {
            this.processResult(data, error);
        }
    }

    // Wire by Application ID (if placed on Application record page)
    @wire(getAdmissionByApplication, { appId: '$recordId' })
    wiredAdmissionByApp({ error, data }) {
        if (this.objectApiName === 'Student_Application__c') {
            this.processResult(data, error);
        }
    }

    processResult(data, error) {
        if (data) {
            this.admission = {
                ...data,
                formattedDate: data.Admission_Date__c ? new Date(data.Admission_Date__c).toLocaleDateString(undefined, {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                }) : 'N/A',
                feeStatus: data.Fees_Paid__c ? 'Paid' : 'Pending Payment',
                feeStatusClass: data.Fees_Paid__c ? 'slds-badge badge-success' : 'slds-badge badge-warning'
            };
            this.noAdmissionFound = false;
            this.error = undefined;
        } else if (error) {
            // Check if error is due to record not found
            if (error.body && error.body.message && error.body.message.includes('List has no rows')) {
                this.noAdmissionFound = true;
                this.admission = undefined;
            } else {
                this.error = error;
                console.error('Error loading admission details:', error);
            }
        } else {
            // If data is null/undefined and no error, it means query returned empty
            this.noAdmissionFound = true;
            this.admission = undefined;
        }
    }

    get hasAdmission() {
        return this.admission !== undefined && this.admission !== null;
    }

    // Call window.print() to print the confirmation slip
    handlePrint() {
        window.print();
    }

    // Opens the Visualforce page in a new window/tab to trigger PDF rendering
    handleDownloadPDF() {
        if (this.admission && this.admission.Id) {
            window.open(`/apex/AdmissionPDF?id=${this.admission.Id}`, '_blank');
        }
    }
}
