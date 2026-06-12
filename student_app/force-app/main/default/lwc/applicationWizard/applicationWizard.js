import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import getCourses from '@salesforce/apex/CourseController.getCourses';
import getRecordTypes from '@salesforce/apex/StudentApplicationController.getRecordTypes';
import saveApplication from '@salesforce/apex/StudentApplicationController.saveApplication';
import submitApplication from '@salesforce/apex/StudentApplicationController.submitApplication';
import createDocumentRecord from '@salesforce/apex/StudentApplicationController.createDocumentRecord';
import processPaymentAndSubmit from '@salesforce/apex/StudentApplicationController.processPaymentAndSubmit';

import ID_FIELD from '@salesforce/schema/Student_Application__c.Id';
import FIRST_NAME_FIELD from '@salesforce/schema/Student_Application__c.First_Name__c';
import LAST_NAME_FIELD from '@salesforce/schema/Student_Application__c.Last_Name__c';
import EMAIL_FIELD from '@salesforce/schema/Student_Application__c.Email__c';
import PHONE_FIELD from '@salesforce/schema/Student_Application__c.Phone__c';
import DOB_FIELD from '@salesforce/schema/Student_Application__c.Date_of_Birth__c';
import COURSE_FIELD from '@salesforce/schema/Student_Application__c.Applied_Course__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/Student_Application__c.RecordTypeId';

export default class ApplicationWizard extends LightningElement {
    @track currentStep = '1';
    @track isLoading = false;
    @track selectedCourseId = '';
    @track selectedCourseName = '';
    @track selectedCourseCode = '';
    @track selectedCourseFees = 0;
    @track selectedCourseType = 'Undergraduate';
    
    // Application properties
    _appId = '';
    @api 
    get appId() {
        return this._appId;
    }
    set appId(value) {
        this._appId = value || '';
        this.applicationId = value || '';
    }

    @track applicationId = '';
    @track applicationName = '';

    // Public API props for pre-selection
    _preselectedCourseId = '';
    @api 
    get preselectedCourseId() {
        return this._preselectedCourseId;
    }
    set preselectedCourseId(value) {
        this._preselectedCourseId = value || '';
        if (value) {
            this.selectedCourseId = value;
            this.populateCourseDetails();
        }
    }

    _preselectedCourseType = '';
    @api 
    get preselectedCourseType() {
        return this._preselectedCourseType;
    }
    set preselectedCourseType(value) {
        this._preselectedCourseType = value || '';
        this.selectedCourseType = value || 'Undergraduate';
        if (this.recordTypesMap && this.recordTypesMap[this.selectedCourseType]) {
            this.selectedRecordTypeId = this.recordTypesMap[this.selectedCourseType];
        }
    }

    _preselectedCourseName = '';
    @api 
    get preselectedCourseName() {
        return this._preselectedCourseName;
    }
    set preselectedCourseName(value) {
        this._preselectedCourseName = value || '';
        this.selectedCourseName = value || '';
    }

    _preselectedCourseCode = '';
    @api 
    get preselectedCourseCode() {
        return this._preselectedCourseCode;
    }
    set preselectedCourseCode(value) {
        this._preselectedCourseCode = value || '';
        this.selectedCourseCode = value || '';
    }

    _preselectedCourseFees = 0;
    @api 
    get preselectedCourseFees() {
        return this._preselectedCourseFees;
    }
    set preselectedCourseFees(value) {
        this._preselectedCourseFees = value || 0;
        this.selectedCourseFees = Number(value) || 0;
    }
    
    // Payment mode launch (completing existing payment)
    @api paymentMode = false;

    // Payment step tracking
    @track paymentMethod = 'UPI';
    paymentMethodOptions = [
        { label: 'UPI', value: 'UPI' },
        { label: 'Card', value: 'Card' },
        { label: 'Net Banking', value: 'Net Banking' },
        { label: 'Cash', value: 'Cash' }
    ];

    // Record types
    @track recordTypesMap = {};
    @track selectedRecordTypeId = '';

    // Form data
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';
    @track dob = '';
    @track address = '';

    // Document tracker (Phase 3: requires 4 files)
    @track documents = [
        { type: 'Academic Transcript', uploaded: false, fileName: '', docId: '', label: 'Upload Academic Transcript (PDF/Image)' },
        { type: 'Identity Proof', uploaded: false, fileName: '', docId: '', label: 'Upload Identity Proof (PDF/Image)' },
        { type: 'Address Proof', uploaded: false, fileName: '', docId: '', label: 'Upload Address Proof (PDF/Image)' },
        { type: 'Passport Photo', uploaded: false, fileName: '', docId: '', label: 'Upload Passport Photo (PDF/Image)' }
    ];

    acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg'];
    allCourses = [];

    @wire(getRecordTypes)
    wiredRecordTypes({ data, error }) {
        if (data) {
            this.recordTypesMap = data;
            if (this.selectedCourseType && data[this.selectedCourseType]) {
                this.selectedRecordTypeId = data[this.selectedCourseType];
            } else {
                this.selectedRecordTypeId = data['Undergraduate'] || '';
            }
            this.populateCourseDetails();
        } else if (error) {
            console.error('Error fetching record types:', error);
        }
    }

    @wire(getCourses)
    wiredCourses({ data, error }) {
        if (data) {
            this.allCourses = data;
            this.populateCourseDetails();
        } else if (error) {
            console.error('Error fetching courses in wizard:', error);
        }
    }

    connectedCallback() {
        if (this.appId) {
            this.applicationId = this.appId;
        }

        // Set correct step sequence
        if (this.paymentMode) {
            this.currentStep = '4';
        } else {
            this.currentStep = '1';
        }

        this.populateCourseDetails();
    }

    populateCourseDetails() {
        // Fallback to storage values if parameters are empty
        if (!this.selectedCourseId) {
            this.selectedCourseId = sessionStorage.getItem('selectedCourseId') || localStorage.getItem('selectedCourseId') || '';
        }

        if (this.selectedCourseId && this.allCourses && this.allCourses.length > 0) {
            const found = this.allCourses.find(w => w.course.Id === this.selectedCourseId);
            if (found && found.course) {
                this.selectedCourseName = found.course.Name || '';
                this.selectedCourseCode = found.course.Course_Code__c || '';
                this.selectedCourseFees = found.course.Fees__c || 0;
                this.selectedCourseType = found.course.Type__c || 'Undergraduate';
                
                if (this.recordTypesMap && this.recordTypesMap[this.selectedCourseType]) {
                    this.selectedRecordTypeId = this.recordTypesMap[this.selectedCourseType];
                }
            }
        }
    }

    // Step navigation flags
    get isStepOne() { return this.currentStep === '1'; }
    get isStepTwo() { return this.currentStep === '2'; }
    get isStepThree() { return this.currentStep === '3'; }
    get isStepPayment() { return this.currentStep === '4'; }
    get isSuccessStep() { return this.currentStep === 'success'; }
    get hasValidApplicationId() { return this.isSalesforceId(this.applicationId); }

    // Upload progress calculations
    get uploadedCount() {
        return this.documents.filter(doc => doc.uploaded).length;
    }

    get totalRequiredCount() {
        return this.documents.length;
    }

    get uploadProgressPercent() {
        if (this.totalRequiredCount === 0) return 0;
        return (this.uploadedCount / this.totalRequiredCount) * 100;
    }

    // Amount auto-population for Step 5
    get paymentAmount() {
        return this.selectedCourseFees;
    }

    // Progress stepper configuration
    get stepperSteps() {
        return [
            {
                label: 'Personal Info',
                circle: '1',
                itemClass: this.currentStep === '1' ? 'step-item active' : (['2', '3', '4', 'success'].includes(this.currentStep) ? 'step-item completed' : 'step-item pending'),
                lineClass: ['2', '3', '4', 'success'].includes(this.currentStep) ? 'step-line completed' : 'step-line',
                showLine: true,
                wrapperStyle: 'display: flex; align-items: center; flex: 1;'
            },
            {
                label: 'Upload Files',
                circle: '2',
                itemClass: this.currentStep === '2' ? 'step-item active' : (['3', '4', 'success'].includes(this.currentStep) ? 'step-item completed' : 'step-item pending'),
                lineClass: ['3', '4', 'success'].includes(this.currentStep) ? 'step-line completed' : 'step-line',
                showLine: true,
                wrapperStyle: 'display: flex; align-items: center; flex: 1;'
            },
            {
                label: 'Review',
                circle: '3',
                itemClass: this.currentStep === '3' ? 'step-item active' : (['4', 'success'].includes(this.currentStep) ? 'step-item completed' : 'step-item pending'),
                lineClass: ['4', 'success'].includes(this.currentStep) ? 'step-line completed' : 'step-line',
                showLine: true,
                wrapperStyle: 'display: flex; align-items: center; flex: 1;'
            },
            {
                label: 'Payment',
                circle: '4',
                itemClass: this.currentStep === '4' ? 'step-item active' : (this.currentStep === 'success' ? 'step-item completed' : 'step-item pending'),
                showLine: false,
                wrapperStyle: 'display: flex; align-items: center; flex: 0 0 auto;'
            }
        ];
    }

    get successTitle() {
        return this.paymentMode ? 'Payment Successful!' : 'Application Submitted Successfully';
    }

    get successMessage() {
        return this.paymentMode 
            ? 'Thank you! Your tuition fee payment has been successfully recorded. Your enrollment is now being finalized.'
            : `Congratulations! Your academic application has been logged under record number ${this.applicationName || ''}. You can track status updates on your dashboard.`;
    }

    // Input handlers
    handleInputChange(event) {
        const fieldName = event.target.name;
        const value = event.target.value;
        if (fieldName === 'firstName') this.firstName = value;
        else if (fieldName === 'lastName') this.lastName = value;
        else if (fieldName === 'email') this.email = value;
        else if (fieldName === 'phone') this.phone = value;
        else if (fieldName === 'dob') this.dob = value;
        else if (fieldName === 'address') this.address = value;
    }

    // Navigation and validation routing
    goToStepTwo() {
        if (this.validateStepOne()) {
            this.saveDraftApplication();
        }
    }

    goToStepThree() {
        const missingDocs = this.documents.filter(doc => !doc.uploaded);
        if (missingDocs.length > 0) {
            this.showToast('Documents Required', 'Please upload all required documentation before proceeding.', 'error');
            return;
        }
        this.currentStep = '3';
    }

    goToStepPayment() {
        this.currentStep = '4';
    }

    goBackToStepOne() {
        this.currentStep = '1';
    }

    goBackToStepTwo() {
        this.currentStep = '2';
    }

    goBackToStepThree() {
        this.currentStep = '3';
    }

    handlePaymentMethodChange(event) {
        this.paymentMethod = event.target.value;
    }

    // Submit Action (Process Payment and finalize application)
    async handlePayAndSubmit() {
        if (!this.hasValidApplicationId) {
            this.showToast('Application Error', 'Your application reference is invalid.', 'error');
            return;
        }

        this.isLoading = true;
        try {
            await processPaymentAndSubmit({
                appId: this.applicationId,
                paymentMethod: this.paymentMethod,
                amount: this.selectedCourseFees
            });
            this.currentStep = 'success';
            this.showToast('Success', 'Application submitted and payment recorded successfully!', 'success');
        } catch (error) {
            console.error('Error processing application submission:', error);
            const message = this.getErrorMessage(error) || 'Unknown error during payment submission.';
            this.showToast('Submission Error', message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Step 1 validation
    validateStepOne() {
        const allInputsValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);

        if (!allInputsValid) {
            return false;
        }

        // Validate birth date (must be >= 16 years of age)
        if (this.dob) {
            const birthDate = new Date(this.dob);
            const today = new Date();
            let age = today.getFullYear() - birthDate.getFullYear();
            const monthDiff = today.getMonth() - birthDate.getMonth();
            if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
                age--;
            }
            if (age < 16) {
                this.showToast('Age Validation Error', 'Applicants must be at least 16 years of age.', 'error');
                return false;
            }
        }

        return true;
    }

    // Saves application record as Draft in DB
    async saveDraftApplication() {
        this.isLoading = true;
        try {
            // Populate course parameters if still missing
            this.populateCourseDetails();

            if (!this.applicationId) {
                const appFields = {
                    firstName: this.firstName,
                    lastName: this.lastName,
                    email: this.email,
                    phone: this.phone,
                    dob: this.dob,
                    courseId: this.selectedCourseId,
                    recordTypeId: this.selectedRecordTypeId
                };
                const draftApp = await saveApplication({ appData: appFields });
                this.applicationId = draftApp.Id;
                this.applicationName = draftApp.Name;
            } else {
                if (!this.hasValidApplicationId) {
                    throw new Error('The current application reference is invalid.');
                }

                const fields = {};
                fields[ID_FIELD.fieldApiName] = this.applicationId;
                fields[FIRST_NAME_FIELD.fieldApiName] = this.firstName;
                fields[LAST_NAME_FIELD.fieldApiName] = this.lastName;
                fields[EMAIL_FIELD.fieldApiName] = this.email;
                fields[PHONE_FIELD.fieldApiName] = this.phone;
                fields[DOB_FIELD.fieldApiName] = this.dob;
                fields[COURSE_FIELD.fieldApiName] = this.selectedCourseId;
                fields[RECORD_TYPE_ID_FIELD.fieldApiName] = this.selectedRecordTypeId;

                const recordInput = { fields };
                await updateRecord(recordInput);
            }
            this.currentStep = '2';
        } catch (error) {
            console.error('Error saving draft application:', error);
            const message = this.getErrorMessage(error) || 'Unknown error saving application.';
            this.showToast('Database Error', message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // File upload callback
    async handleUploadFinished(event) {
        const docType = event.currentTarget.dataset.type;
        const uploadedFiles = event.detail.files;
        if (uploadedFiles && uploadedFiles.length > 0) {
            if (!this.hasValidApplicationId) {
                this.showToast('Upload Error', 'A valid application must exist to link documents.', 'error');
                return;
            }

            this.isLoading = true;
            const file = uploadedFiles[0];
            try {
                const docRecord = await createDocumentRecord({
                    appId: this.applicationId,
                    docType: docType,
                    contentDocId: file.documentId,
                    fileName: file.name
                });
                
                // Update tracker properties
                this.documents = this.documents.map(doc => {
                    if (doc.type === docType) {
                        const lowerName = file.name.toLowerCase();
                        const isImg = lowerName.endsWith('.png') || lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg');
                        const status = docRecord.Verification_Status__c || 'Pending';
                        let badgeCls = 'slds-badge slds-theme_warning badge-custom';
                        if (status === 'Verified') {
                            badgeCls = 'slds-badge slds-theme_success badge-custom';
                        } else if (status === 'Rejected') {
                            badgeCls = 'slds-badge slds-theme_error badge-custom';
                        }
                        
                        return {
                            ...doc,
                            uploaded: true,
                            fileName: file.name,
                            docId: docRecord.Id,
                            documentId: file.documentId,
                            previewUrl: `/sfc/servlet.shepherd/document/download/${file.documentId}`,
                            isImage: isImg,
                            verificationStatus: status,
                            badgeClass: badgeCls
                        };
                    }
                    return doc;
                });
                this.showToast('Success', `${docType} uploaded successfully.`, 'success');
            } catch (error) {
                console.error('Error linking uploaded file:', error);
                this.showToast('Upload Error', 'Failed to link document to your application.', 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closewizard', {
            bubbles: true,
            composed: true
        }));
    }

    isSalesforceId(value) {
        return typeof value === 'string' && /^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$/.test(value);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    getErrorMessage(error) {
        if (!error) return '';
        if (error.body) {
            if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors[0].message;
            }
            if (error.body.fieldErrors && Object.keys(error.body.fieldErrors).length > 0) {
                const firstField = Object.keys(error.body.fieldErrors)[0];
                const fieldError = error.body.fieldErrors[firstField];
                if (fieldError && fieldError.length > 0) {
                    return fieldError[0].message;
                }
            }
            if (error.body.message) {
                return error.body.message;
            }
        }
        if (error.message) {
            return error.message;
        }
        return '';
    }
}
