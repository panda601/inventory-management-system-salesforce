import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { subscribe, MessageContext } from 'lightning/messageService';
import CourseApplyChannel from '@salesforce/messageChannel/CourseApply__c';
import getMyApplications from '@salesforce/apex/StudentApplicationController.getMyApplications';
import getRelatedDocuments from '@salesforce/apex/StudentApplicationController.getRelatedDocuments';
import getAdmissionByApplication from '@salesforce/apex/AdmissionController.getAdmissionByApplication';
import { getRecord } from 'lightning/uiRecordApi';
import getCourses from '@salesforce/apex/CourseController.getCourses';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

export default class StudentDashboard extends LightningElement {
    @track pageState = 'portal'; // portal, details, wizard, dashboard
    @track courses = [];
    @track selectedCourse = {};
    @track applications = [];
    @track error;
    @track isLoading = false;
    @track showWizard = false;
    @track preselectedCourseId = '';
    @track preselectedCourseType = '';
    @track preselectedCourseName = '';
    @track preselectedCourseCode = '';
    @track preselectedCourseFees = 0;
    @track studentName = 'Student';
    @track uploadedDocs = [];
    @track payments = [];
    @track activeTab = 'overview';
    
    // Payment Mode
    @track paymentMode = false;

    // Keep track of wired results for refreshApex
    wiredAppsResult;
    wiredAdmissionResult;
    _subscription = null;
    @track admissionRecord = null;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.studentName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching user info:', error);
        }
    }

    get latestApp() {
        return this.applications && this.applications.length > 0 ? this.applications[0] : null;
    }

    get latestAppId() {
        return this.latestApp ? this.latestApp.Id : null;
    }

    get wizardAppId() {
        return this.paymentMode ? this.latestAppId : '';
    }

    get hasUploadedDocs() {
        return this.uploadedDocs && this.uploadedDocs.length > 0;
    }

    // Semester Tuition Fee Tracker Calculations (Issue 7)
    get totalSemesters() {
        const app = this.latestApp;
        if (!app || !app.Applied_Course__r) return 4;
        
        const type = app.Applied_Course__r.Type__c;
        const name = (app.Applied_Course__r.Name || '').toLowerCase();
        
        if (type === 'Diploma') {
            return 2;
        }
        if (type === 'Postgraduate') {
            return 4;
        }
        if (type === 'Undergraduate') {
            return (name.includes('btech') || name.includes('b.tech')) ? 8 : 6;
        }
        return 4;
    }

    get paidSemestersCount() {
        const app = this.latestApp;
        if (!app || !app.Payments__r) return 0;
        
        // Count paid payments
        return app.Payments__r.filter(p => p.Payment_Status__c === 'Paid').length;
    }

    get feeSemesters() {
        const app = this.latestApp;
        if (!app) return [];
        
        const total = this.totalSemesters;
        const paidCount = this.paidSemestersCount;
        const feePerSem = this.totalCourseFees / total;
        const createdDate = app.CreatedDate ? new Date(app.CreatedDate) : new Date();
        const list = [];
        
        for (let i = 1; i <= total; i++) {
            let status = 'Pending';
            let badgeClass = 'slds-badge badge-custom badge-pending';
            let paidAmount = 0;
            let pendingAmount = feePerSem;
            
            if (i <= paidCount) {
                status = 'Paid';
                badgeClass = 'slds-badge slds-theme_success badge-custom badge-approved';
                paidAmount = feePerSem;
                pendingAmount = 0;
            }
            
            // Calculate due date (6 months increment for each semester)
            const dueDate = new Date(createdDate);
            dueDate.setMonth(dueDate.getMonth() + (i - 1) * 6);
            
            list.push({
                name: `Semester ${i}`,
                amount: `$${Number(feePerSem).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`,
                paid: `$${Number(paidAmount).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`,
                pending: `$${Number(pendingAmount).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`,
                dueDate: dueDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
                status,
                badgeClass
            });
        }
        return list;
    }

    get paymentProgressPercent() {
        const total = this.totalCourseFees;
        if (total <= 0) return 0;
        return Math.round((this.paidAmount / total) * 100);
    }

    get totalCourseFees() {
        const app = this.latestApp;
        if (!app || !app.Applied_Course__r) return 0;
        return app.Applied_Course__r.Fees__c || 0;
    }

    get paidAmount() {
        const feePerSem = this.totalCourseFees / this.totalSemesters;
        return this.paidSemestersCount * feePerSem;
    }

    get dueAmount() {
        if (this.paidSemestersCount >= this.totalSemesters) return 0;
        return this.totalCourseFees / this.totalSemesters;
    }

    get remainingAmount() {
        return Math.max(this.totalCourseFees - this.paidAmount, 0);
    }

    get formattedTotalCourseFees() {
        return Number(this.totalCourseFees).toLocaleString('en-US');
    }

    get formattedPaidAmount() {
        return Number(this.paidAmount).toLocaleString('en-US');
    }

    get formattedDueAmount() {
        return Number(this.dueAmount).toLocaleString('en-US');
    }

    get formattedRemainingAmount() {
        return Number(this.remainingAmount).toLocaleString('en-US');
    }

    get paymentStatusLabel() {
        const paid = this.paidAmount;
        const total = this.totalCourseFees;
        if (paid === 0) {
            return 'Pending';
        }
        if (paid >= total) {
            return 'Paid';
        }
        return 'Partial';
    }

    get paymentStatusClass() {
        const status = this.paymentStatusLabel;
        if (status === 'Paid') {
            return 'slds-badge slds-theme_success badge-custom badge-approved';
        } else if (status === 'Partial') {
            return 'slds-badge slds-theme_info badge-custom badge-submitted';
        }
        return 'slds-badge slds-theme_warning badge-custom badge-pending';
    }

    get currentStage() {
        const app = this.latestApp;
        if (!app) return 'N/A';
        
        const status = app.Application_Status__c || 'Draft';
        const docStatus = app.Document_Status__c || 'Pending';
        const admStatus = app.Admission_Status__c || 'Pending';
        const paymentStatus = app.paymentStatus || 'Pending';
        
        if (status === 'Rejected' || docStatus === 'Rejected' || admStatus === 'Rejected') {
            return 'Rejected';
        }
        
        // 8. Enrolled (Admission Status is Admitted)
        if (admStatus === 'Admitted' || status === 'Admitted') {
            return 'Enrolled';
        }
        
        // 7. Admission Created (Admission Status is Pending and status is Paid)
        if (admStatus === 'Pending' && status === 'Paid') {
            return 'Admission Created';
        }
        
        // 6. Paid (Application status is Paid / Fee Paid, or payment status is Paid)
        if (status === 'Paid' || paymentStatus === 'Paid') {
            return 'Paid';
        }
        
        // 5. Payment Pending (Status is Payment Pending, or status is Approved but payment is Pending)
        if (status === 'Payment Pending' || (status === 'Approved' && paymentStatus === 'Pending')) {
            return 'Payment Pending';
        }
        
        // 4. Approved (Status is Approved)
        if (status === 'Approved') {
            return 'Approved';
        }
        
        // 3. Document Verification (Document status is Verified)
        if (docStatus === 'Verified') {
            return 'Document Verification';
        }
        
        // 2. Under Review (Status is Under Review or Document Status is Uploaded)
        if (status === 'Under Review' || docStatus === 'Uploaded') {
            return 'Under Review';
        }
        
        // 1. Submitted (default submitted state)
        return 'Submitted';
    }

    get progressPercent() {
        const stage = this.currentStage;
        if (stage === 'Rejected') return 0;
        
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
        
        const index = STAGE_SEQUENCE.indexOf(stage);
        if (index < 0) return 0;
        return Math.round(((index + 1) / 8) * 100);
    }

    get courseDuration() {
        const app = this.latestApp;
        if (!app || !app.Applied_Course__r) return 'N/A';
        return this.getDurationLabel(
            app.Applied_Course__r.Name, 
            app.Applied_Course__r.Type__c, 
            app.Applied_Course__r.Credits__c
        );
    }

    get formattedFeePerSemester() {
        const total = this.totalCourseFees;
        const semesters = this.totalSemesters;
        if (semesters <= 0) return '0.00';
        return Number(total / semesters).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get syllabusLink() {
        const code = this.latestApp && this.latestApp.Applied_Course__r ? this.latestApp.Applied_Course__r.Course_Code__c : '';
        return code ? `https://example.edu/syllabus/${code.toLowerCase()}.pdf` : '#';
    }

    get notifications() {
        const app = this.latestApp;
        if (!app) return [];

        const list = [];
        
        // 1. Approval Updates
        const status = app.Application_Status__c || 'Draft';
        let approvalTitle = 'Application Status';
        let approvalMessage = 'Your application is currently under review.';
        let approvalIcon = 'utility:info';

        if (status === 'Approved') {
            approvalTitle = 'Application Approved!';
            approvalMessage = 'Your application has been approved. Please proceed to the Payments center to pay semester fees.';
            approvalIcon = 'utility:approval';
        } else if (status === 'Payment Pending') {
            approvalTitle = 'Fee Payment Required';
            approvalMessage = 'Tuition payment is pending for your approved application.';
            approvalIcon = 'utility:clock';
        } else if (status === 'Paid') {
            approvalTitle = 'Enrollment Pending';
            approvalMessage = 'Your tuition has been paid. Your admission record is being processed.';
            approvalIcon = 'utility:success';
        } else if (status === 'Enrolled' || app.Admission_Status__c === 'Admitted') {
            approvalTitle = 'Officially Enrolled';
            approvalMessage = 'Congratulations! You are officially enrolled in the program.';
            approvalIcon = 'utility:user';
        } else if (status === 'Rejected') {
            approvalTitle = 'Application Decision';
            approvalMessage = 'Your application has been rejected. Please contact support.';
            approvalIcon = 'utility:close';
        }

        list.push({
            id: 'approval',
            title: approvalTitle,
            message: approvalMessage,
            icon: approvalIcon,
            iconClass: `slds-m-right_small ${status === 'Approved' || status === 'Paid' || status === 'Enrolled' ? 'text-success' : status === 'Rejected' ? 'text-danger' : 'text-warning'}`
        });

        // 2. Document Updates
        const docStatus = app.Document_Status__c || 'Pending';
        let docTitle = 'Document Verification';
        let docMessage = 'Verification is pending. Please make sure all required documents are uploaded.';
        let docIcon = 'utility:file';

        if (docStatus === 'Verified') {
            docTitle = 'Documents Verified';
            docMessage = 'All submitted documents have been successfully verified.';
            docIcon = 'utility:check';
        } else if (docStatus === 'Uploaded') {
            docTitle = 'Documents Under Review';
            docMessage = 'Your documents have been received and are currently being verified.';
            docIcon = 'utility:clock';
        } else if (docStatus === 'Rejected') {
            docTitle = 'Action Needed: Documents Rejected';
            docMessage = 'One or more documents were rejected. Please review feedback and re-upload.';
            docIcon = 'utility:warning';
        }

        list.push({
            id: 'documents',
            title: docTitle,
            message: docMessage,
            icon: docIcon,
            iconClass: `slds-m-right_small ${docStatus === 'Verified' ? 'text-success' : docStatus === 'Rejected' ? 'text-danger' : 'text-warning'}`
        });

        // 3. Payment Updates
        const payStatus = this.paymentStatusLabel;
        let payTitle = 'Tuition Balance';
        let payMessage = 'Your tuition payment is pending.';
        let payIcon = 'utility:money';

        if (payStatus === 'Paid') {
            payTitle = 'Tuition Paid';
            payMessage = 'All semester tuition fees have been paid. No outstanding balance.';
            payIcon = 'utility:check';
        } else if (payStatus === 'Partial') {
            payTitle = 'Partial Payment Received';
            payMessage = `You have paid $${Number(this.paidAmount).toLocaleString('en-US')} of your tuition. Remaining balance: $${Number(this.remainingAmount).toLocaleString('en-US')}.`;
            payIcon = 'utility:info';
        }

        list.push({
            id: 'payments',
            title: payTitle,
            message: payMessage,
            icon: payIcon,
            iconClass: `slds-m-right_small ${payStatus === 'Paid' ? 'text-success' : 'text-warning'}`
        });

        return list;
    }

    get lastUpdated() {
        const app = this.latestApp;
        if (!app) return 'N/A';
        const dateToUse = app.LastModifiedDate || app.CreatedDate;
        if (!dateToUse) return 'N/A';
        return new Date(dateToUse).toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    get formattedAdmissionDate() {
        if (this.admissionRecord && this.admissionRecord.Admission_Date__c) {
            return new Date(this.admissionRecord.Admission_Date__c).toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric'
            });
        }
        return 'Pending';
    }

    get showPaymentAction() {
        const app = this.latestApp;
        if (!app) return false;
        
        // Show Complete Payment if application is approved / pending payment, and not all semesters are paid
        return (app.Application_Status__c === 'Payment Pending' || app.paymentStatus === 'Pending') 
            && (this.paidSemestersCount < this.totalSemesters);
    }

    // Complete Payment trigger
    handlePayTuition() {
        const app = this.latestApp;
        if (app && app.Applied_Course__r) {
            this.preselectedCourseId = app.Applied_Course__c;
            this.preselectedCourseName = app.Applied_Course__r.Name;
            this.preselectedCourseCode = app.Applied_Course__r.Course_Code__c;
            this.preselectedCourseType = app.Applied_Course__r.Type__c;
            this.preselectedCourseFees = app.Applied_Course__r.Fees__c / this.totalSemesters; // Pay single semester fee
            this.paymentMode = true;
            this.showWizard = true;
        }
    }

    handleTabActive(event) {
        this.activeTab = event.target.value;
    }

    handleScrollViewDocuments() {
        this.activeTab = 'documents';
        this.pageState = 'dashboard';
    }

    handleScrollToTracker() {
        this.activeTab = 'overview';
        this.pageState = 'dashboard';
        setTimeout(() => {
            const el = this.template.querySelector('.custom-table');
            if (el) {
                el.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        }, 50);
    }

    // Wire admission for the latest application
    @wire(getAdmissionByApplication, { appId: '$latestAppId' })
    wiredAdmission(result) {
        this.wiredAdmissionResult = result;
        if (result.data) {
            this.admissionRecord = result.data;
        } else if (result.error) {
            console.error('Error fetching dashboard admission:', result.error);
            this.admissionRecord = null;
        } else {
            this.admissionRecord = null;
        }
    }

    // Wire documents for the latest application
    wiredDocsResult;
    @wire(getRelatedDocuments, { appId: '$latestAppId' })
    wiredDocs(result) {
        this.wiredDocsResult = result;
        if (result.data) {
            this.uploadedDocs = result.data.map(docWrap => {
                const status = docWrap.document.Verification_Status__c;
                return {
                    id: docWrap.document.Id,
                    name: docWrap.document.Name,
                    type: docWrap.document.Document_Type__c,
                    status: status,
                    statusClass: this.getDocStatusBadgeClass(status),
                    uploadDate: docWrap.document.CreatedDate ? new Date(docWrap.document.CreatedDate).toLocaleDateString() : 'N/A'
                };
            });
        } else if (result.error) {
            console.error('Error fetching dashboard documents:', result.error);
        }
    }

    // Wire application list
    @wire(getMyApplications)
    wiredApplications(result) {
        this.wiredAppsResult = result;
        if (result.data) {
            this.applications = result.data.map(app => {
                // Find latest payment status
                const latestPayment = app.Payments__r && app.Payments__r.length > 0 ? app.Payments__r[0] : null;
                const payStatus = latestPayment ? latestPayment.Payment_Status__c : (app.Payment_Status__c || 'Pending');
                return {
                    ...app,
                    statusClass: this.getStatusBadgeClass(app.Application_Status__c),
                    docStatusClass: this.getDocStatusBadgeClass(app.Document_Status__c),
                    admStatusClass: this.getAdmStatusBadgeClass(app.Admission_Status__c),
                    paymentStatus: payStatus,
                    paymentStatusClass: this.getPaymentStatusBadgeClass(payStatus),
                    formattedDate: new Date(app.CreatedDate).toLocaleDateString()
                };
            });

            // Populate payment history list (Step 5)
            if (this.applications.length > 0 && this.applications[0].Payments__r) {
                this.payments = this.applications[0].Payments__r.map(pay => {
                    return {
                        id: pay.Id,
                        name: pay.Payment_Number__c || pay.Name || 'N/A',
                        amount: `$${Number(pay.Amount__c || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}`,
                        status: pay.Payment_Status__c || 'Pending',
                        statusClass: this.getPaymentStatusBadgeClass(pay.Payment_Status__c),
                        paymentDate: pay.Payment_Date__c ? new Date(pay.Payment_Date__c).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : 'N/A'
                    };
                });
            } else {
                this.payments = [];
            }
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            console.error('Error fetching applications:', result.error);
        }
    }

    connectedCallback() {
        if (!this._subscription) {
            this._subscription = subscribe(
                this.messageContext,
                CourseApplyChannel,
                (message) => this.handleCourseApplyMessage(message)
            );
        }
    }

    handleCourseApplyMessage(message) {
        this.preselectedCourseId   = message.courseId   || '';
        this.preselectedCourseType = message.courseType || '';
        this.preselectedCourseName = message.courseName || '';
        this.preselectedCourseCode = message.courseCode || '';
        this.preselectedCourseFees = Number(message.courseFees) || 0;
        
        sessionStorage.setItem('selectedCourseId', message.courseId);
        localStorage.setItem('selectedCourseId', message.courseId);

        this.paymentMode = false;
        this.pageState = 'wizard';
        this.showWizard = true;
    }

    getStatusBadgeClass(status) {
        switch (status) {
            case 'Enrolled':
            case 'Admission Created':
            case 'Payment Completed':
            case 'Approved':
            case 'Paid':
            case 'Admitted':
                return 'slds-badge slds-theme_success slds-m-around_xx-small badge-custom badge-approved';
            case 'Rejected':
                return 'slds-badge slds-theme_error slds-m-around_xx-small badge-custom badge-rejected';
            case 'Payment Pending':
            case 'Document Verification':
            case 'Under Review':
            case 'Submitted':
            case 'Draft':
            default:
                return 'slds-badge slds-theme_warning slds-m-around_xx-small badge-custom badge-submitted';
        }
    }

    getDocStatusBadgeClass(status) {
        switch (status) {
            case 'Verified':
                return 'slds-badge slds-theme_success slds-m-around_xx-small badge-custom badge-approved';
            case 'Uploaded':
                return 'slds-badge slds-theme_info slds-m-around_xx-small badge-custom badge-submitted';
            case 'Rejected':
                return 'slds-badge slds-theme_error slds-m-around_xx-small badge-custom badge-rejected';
            case 'Pending':
            default:
                return 'slds-badge slds-theme_warning slds-m-around_xx-small badge-custom badge-submitted';
        }
    }

    getAdmStatusBadgeClass(status) {
        switch (status) {
            case 'Admitted':
                return 'slds-badge slds-theme_success slds-m-around_xx-small badge-custom badge-approved';
            case 'Rejected':
            case 'Cancelled':
                return 'slds-badge slds-theme_error slds-m-around_xx-small badge-custom badge-rejected';
            case 'Waitlisted':
                return 'slds-badge slds-m-around_xx-small badge-custom badge-draft';
            case 'Pending':
            default:
                return 'slds-badge slds-theme_warning slds-m-around_xx-small badge-custom badge-submitted';
        }
    }

    getPaymentStatusBadgeClass(status) {
        switch (status) {
            case 'Paid':
                return 'slds-badge slds-theme_success slds-m-around_xx-small badge-custom badge-approved';
            case 'Failed':
                return 'slds-badge slds-theme_error slds-m-around_xx-small badge-custom badge-rejected';
            case 'Refunded':
                return 'slds-badge slds-m-around_xx-small badge-custom badge-draft';
            case 'Pending':
                return 'slds-badge slds-theme_warning slds-m-around_xx-small badge-custom badge-submitted';
            default:
                return 'slds-badge slds-m-around_xx-small badge-custom badge-draft';
        }
    }

    get latestPaymentStatus() {
        if (this.applications && this.applications.length > 0) {
            return this.applications[0].paymentStatus;
        }
        return 'N/A';
    }

    get latestPaymentStatusCardClass() {
        const status = this.latestPaymentStatus;
        switch (status) {
            case 'Paid':
                return 'kpi-card card-approved';
            case 'Failed':
            case 'Unpaid':
                return 'kpi-card card-rejected';
            case 'Refunded':
                return 'kpi-card card-total';
            case 'Pending':
                return 'kpi-card card-pending';
            default:
                return 'kpi-card card-total';
        }
    }

    get hasApplications() {
        return this.applications && this.applications.length > 0;
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await Promise.all([
                refreshApex(this.wiredAppsResult),
                refreshApex(this.wiredDocsResult),
                refreshApex(this.wiredAdmissionResult),
                refreshApex(this.wiredCoursesResult)
            ]);
        } catch (err) {
            console.error('Error refreshing data:', err);
        } finally {
            this.isLoading = false;
        }
    }

    handleNewApplication() {
        this.pageState = 'portal';
        setTimeout(() => {
            const catalogHeader = this.template.querySelector('.catalog-anchor');
            if (catalogHeader) {
                catalogHeader.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }, 100);
    }

    handleCloseWizard() {
        this.showWizard = false;
        this.preselectedCourseId = '';
        this.preselectedCourseType = '';
        this.preselectedCourseName = '';
        this.preselectedCourseCode = '';
        this.preselectedCourseFees = 0;
        this.paymentMode = false;
        this.activeTab = 'overview';
        this.pageState = 'dashboard';
        this.handleRefresh();
        
        setTimeout(() => {
            const tracker = this.template.querySelector('c-application-status-tracker');
            if (tracker) {
                tracker.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        }, 500);
    }

    // Phase 5 Portal state handlers
    handleViewDetails(event) {
        const courseId = event.currentTarget.dataset.id;
        const found = this.courses.find(c => c.id === courseId);
        if (found) {
            this.selectedCourse = found;
            this.pageState = 'details';
        }
    }

    handleCloseDetails() {
        this.pageState = 'portal';
        this.selectedCourse = {};
    }

    handleApplyNow() {
        if (this.selectedCourse && this.selectedCourse.id) {
            this.preselectedCourseId = this.selectedCourse.id;
            this.preselectedCourseName = this.selectedCourse.name;
            this.preselectedCourseCode = this.selectedCourse.code;
            this.preselectedCourseType = this.selectedCourse.type;
            this.preselectedCourseFees = this.selectedCourse.fees;
            this.paymentMode = false;

            sessionStorage.setItem('selectedCourseId', this.selectedCourse.id);
            localStorage.setItem('selectedCourseId', this.selectedCourse.id);

            this.pageState = 'wizard';
            this.showWizard = true;
        }
    }

    handleGoToPortal() {
        this.pageState = 'portal';
    }

    handleGoToDashboard() {
        this.pageState = 'dashboard';
    }

    // Dynamic Course details parsing for portal catalog
    getDurationLabel(name, type, credits) {
        const lowerName = (name || '').toLowerCase();
        if (lowerName.includes('btech') || lowerName.includes('b.tech')) {
            return '4 Years';
        }
        if (lowerName.includes('bca')) {
            return '3 Years';
        }
        if (lowerName.includes('mca') || lowerName.includes('mba') || lowerName.includes('mtech') || lowerName.includes('m.tech')) {
            return '2 Years';
        }
        if (type === 'Diploma') {
            return credits >= 40 ? '1 Year' : '6 Months';
        }
        if (type === 'Undergraduate') {
            return '3 Years';
        }
        if (type === 'Postgraduate') {
            return '2 Years';
        }
        return 'Program Duration';
    }

    getIconName(name) {
        const lowerName = (name || '').toLowerCase();
        if (lowerName.includes('btech') || lowerName.includes('mtech') || lowerName.includes('engineering')) {
            return 'utility:connected_apps';
        }
        if (lowerName.includes('bca') || lowerName.includes('mca') || lowerName.includes('computer')) {
            return 'utility:desktop';
        }
        if (lowerName.includes('mba') || lowerName.includes('business')) {
            return 'utility:chart';
        }
        return 'utility:education';
    }

    getDynamicDetails(name, type, duration, fees, remaining, capacity) {
        const semestersCount = duration.includes('4 Years') ? 8 
                             : duration.includes('3 Years') ? 6 
                             : duration.includes('2 Years') ? 4 
                             : duration.includes('1 Year') ? 2 
                             : 1;
        const totalSemesters = semestersCount + ' Semesters';
        const feePerSemVal = Math.round(fees / semestersCount);
        const formattedFeePerSemester = Number(feePerSemVal).toLocaleString('en-US');
        const semesterList = [];
        for (let i = 1; i <= semestersCount; i++) {
            semesterList.push('Semester ' + i);
        }
        
        let overview = '';
        let semesterStructure = '';
        let careerPath = '';
        let eligibility = '';

        if (type === 'Undergraduate') {
            overview = 'Comprehensive undergraduate program designed to build strong foundations in academic theory and practical applications.';
            semesterStructure = 'Core subjects in computing and engineering fundamentals. Specialization paths include Full-Stack Engineering, Cloud Architecture, and Data Science.';
            careerPath = 'Software Engineer, Systems Analyst, Business Consultant, Web Developer, database administrator, or research scientist.';
            eligibility = 'Successful completion of 12th standard (High School) or equivalent with a minimum of 60% aggregate marks.';
        } else if (type === 'Postgraduate') {
            overview = 'Advanced postgraduate program designed for deep professional development, research skills, and leadership readiness.';
            semesterStructure = 'Advanced methodologies, specialized core technologies, theory of computing, system architecture, research project and industrial internship.';
            careerPath = 'Lead Technical Specialist, Product/Project Manager, Systems Architect, Lead Developer, Research Fellow, or technical consultant.';
            eligibility = 'Undergraduate degree in a relevant discipline from an accredited university with at least 55% aggregate marks.';
        } else {
            overview = 'Intense professional training program for fast-track career skills, hands-on lab work, and industry certifications.';
            semesterStructure = 'Fundamental principles, scripting, basic laboratory practice, specialization projects, and final placement project.';
            careerPath = 'Assistant Developer, Technical Specialist, Field Support Executive, Systems Administrator, or junior consultant.';
            eligibility = 'Completion of 10th standard or equivalent with high technical inclination.';
        }

        return {
            overview,
            totalSemesters,
            semestersCount,
            semesterList,
            formattedFeePerSemester,
            semesterStructure,
            careerPath,
            eligibility
        };
    }

    wiredCoursesResult;
    @wire(getCourses)
    wiredCourses(result) {
        this.wiredCoursesResult = result;
        if (result.data) {
            this.courses = result.data.map(wrapper => {
                const course = wrapper.course || {};
                const name = course.Name || 'Course';
                const remainingSeats = Math.max(wrapper.remainingSeats || 0, 0);
                const fees = course.Fees__c || 0;
                const courseType = course.Type__c || 'Program';
                const credits = course.Credits__c || 0;
                const capacity = course.Capacity__c || 0;
                const duration = this.getDurationLabel(name, courseType, credits);
                const details = this.getDynamicDetails(name, courseType, duration, fees, remainingSeats, capacity);

                return {
                    id: course.Id,
                    name,
                    code: course.Course_Code__c || '',
                    description: course.Description__c || '',
                    fees,
                    formattedFees: Number(fees).toLocaleString('en-US'),
                    type: courseType,
                    remaining: remainingSeats,
                    capacity: capacity,
                    duration,
                    icon: this.getIconName(name),
                    isFull: remainingSeats <= 0,
                    availabilityClass: remainingSeats <= 0 ? 'availability-badge badge-full' : 'availability-badge badge-open',
                    ...details
                };
            });
        } else if (result.error) {
            console.error('Error fetching courses in dashboard:', result.error);
        }
    }

    // State template getters
    get isPortalState() {
        return this.pageState === 'portal';
    }

    get isDetailsState() {
        return this.pageState === 'details';
    }

    get isWizardState() {
        return this.pageState === 'wizard';
    }

    get isDashboardState() {
        return this.pageState === 'dashboard';
    }
}
