import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getReturnRequests from '@salesforce/apex/InventoryController.getReturnRequests';
import processReturnRequestExtended from '@salesforce/apex/InventoryController.processReturnRequestExtended';
import getUserRole from '@salesforce/apex/InventoryController.getUserRole';

export default class ReturnManagementDashboard extends NavigationMixin(LightningElement) {
    @api userRole; // Loaded dynamically or passed
    @api variant = 'default';
    @track returnRequests = [];
    @track searchKey = '';
    @track activeFilter = 'All';
    @track isLoading = false;
    @track error;

    // Creation Modal state
    @track isCreateModalOpen = false;

    // Processing Modal state
    @track isProcessModalOpen = false;
    @track selectedRequestId = '';
    @track selectedRequestName = '';
    @track processStatus = 'manager_approve';

    wiredReturnRequestsResult;

    @wire(getReturnRequests)
    wiredRequests(result) {
        this.wiredReturnRequestsResult = result;
        if (result.data) {
            this.returnRequests = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.returnRequests = [];
        }
    }

    connectedCallback() {
        if (!this.userRole) {
            this.isLoading = true;
            getUserRole()
                .then(result => {
                    this.userRole = result;
                })
                .catch(err => {
                    this.error = err;
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    }

    // Role checks
    get isAdmin() {
        return this.userRole === 'Admin';
    }

    get isManager() {
        return this.userRole === 'Manager';
    }

    get isSales() {
        return this.userRole === 'Sales';
    }

    get isManagerOrAdmin() {
        return this.userRole === 'Admin' || this.userRole === 'Manager';
    }

    get isApprovedSelected() {
        return this.processStatus === 'admin_repair' || this.processStatus === 'admin_replace';
    }

    get isAdminVariant() {
        return this.variant === 'admin';
    }

    // Metric Getters (6 Cards for Admin/Manager)
    get pendingReturnsCount() {
        return this.returnRequests.filter(req => req.Status__c === 'Submitted').length;
    }

    get underReviewCount() {
        return this.returnRequests.filter(req => req.Status__c === 'Under Review').length;
    }

    get approvedCount() {
        return this.returnRequests.filter(req => req.Status__c === 'Approved').length;
    }

    get replacementSentCount() {
        return this.returnRequests.filter(req => req.Status__c === 'Replacement Sent').length;
    }

    get rejectedCount() {
        return this.returnRequests.filter(req => req.Status__c === 'Rejected' || req.Status__c === 'Closed').length;
    }

    get replacementRequestsCount() {
        return this.returnRequests.filter(req => req.Resolution_Type__c === 'Replacement').length;
    }

    get refundRequestsCount() {
        return this.returnRequests.filter(
            req => req.Resolution_Type__c === 'Refund' && req.Status__c !== 'Rejected'
        ).length;
    }

    // Metric Getters for Sales Executive
    get myReturnRequestsCount() {
        return this.returnRequests.length;
    }

    get myPendingReturnsCount() {
        return this.returnRequests.filter(req => req.Status__c === 'Submitted' || req.Status__c === 'Under Review').length;
    }

    get myReplacementStatusCount() {
        return this.returnRequests.filter(req => req.Status__c === 'Replacement Sent').length;
    }

    // Filter tabs available based on role
    get filterOptions() {
        if (this.isAdminVariant) {
            return [
                { label: 'All Returns', value: 'All' },
                { label: 'Pending Returns', value: 'Pending' },
                { label: 'Under Review', value: 'Under Review' },
                { label: 'Replacement Sent', value: 'Replacement Sent' },
                { label: 'Rejected', value: 'Rejected' },
                { label: 'Refunded', value: 'Refunded' }
            ].map(opt => ({
                ...opt,
                activeClass: this.activeFilter === opt.value ? 'tab-item active' : 'tab-item'
            }));
        }

        const optionsList = this.isSales ? [
            { label: 'All My Returns', value: 'All' },
            { label: 'Pending Approval', value: 'Pending' },
            { label: 'Approved & Replacements', value: 'Approved' },
            { label: 'Rejected', value: 'Rejected' }
        ] : [
            { label: 'All Returns', value: 'All' },
            { label: 'Pending Review', value: 'Pending' },
            { label: 'Approved', value: 'Approved' },
            { label: 'Replacement Sent', value: 'Replacement Sent' },
            { label: 'Rejected', value: 'Rejected' }
        ];
        return optionsList.map(opt => ({
            ...opt,
            activeClass: this.activeFilter === opt.value ? 'tab-item active' : 'tab-item'
        }));
    }

    // Filtered data displayed in table
    get filteredRequests() {
        let data = this.returnRequests;

        // Apply filter tab
        if (this.activeFilter === 'Pending') {
            data = data.filter(req => req.Status__c === 'Submitted' || req.Status__c === 'Under Review');
        } else if (this.activeFilter === 'Under Review') {
            data = data.filter(req => req.Status__c === 'Under Review');
        } else if (this.activeFilter === 'Approved') {
            data = this.isSales
                ? data.filter(req => ['Approved', 'Replacement Sent', 'Refunded'].includes(req.Status__c))
                : data.filter(req => req.Status__c === 'Approved');
        } else if (this.activeFilter === 'Replacement Sent') {
            data = data.filter(req => req.Status__c === 'Replacement Sent');
        } else if (this.activeFilter === 'Rejected') {
            data = data.filter(req => req.Status__c === 'Rejected' || req.Status__c === 'Closed');
        } else if (this.activeFilter === 'Refunded') {
            data = data.filter(req => req.Resolution_Type__c === 'Refund' && req.Status__c !== 'Rejected');
        }

        // Apply search keyword
        if (this.searchKey) {
            const searchStr = this.searchKey.toLowerCase();
            data = data.filter(req => 
                (req.Name && req.Name.toLowerCase().includes(searchStr)) ||
                (req.Customer_Name__c && req.Customer_Name__c.toLowerCase().includes(searchStr)) ||
                (req.Product__r && req.Product__r.Product_Name__c && req.Product__r.Product_Name__c.toLowerCase().includes(searchStr)) ||
                (req.Reason__c && req.Reason__c.toLowerCase().includes(searchStr))
            );
        }

        // Return mapped data for UI compatibility (badge themes, disabled button states)
        return data.map(req => {
            let badgeClass = 'slds-badge ';
            if (req.Status__c === 'Submitted') badgeClass += 'slds-theme_warning';
            else if (req.Status__c === 'Under Review') badgeClass += 'slds-theme_info';
            else if (req.Status__c === 'Approved') badgeClass += 'slds-theme_success';
            else if (req.Status__c === 'Replacement Sent') badgeClass += 'slds-badge_inverse';
            else if (req.Status__c === 'Rejected') badgeClass += 'slds-theme_error';
            else if (req.Status__c === 'Closed') badgeClass += 'slds-theme_light';
            else badgeClass += 'slds-theme_light';

            const canApprove = (this.isManager && req.Status__c === 'Submitted') ||
                (this.isAdmin && req.Status__c === 'Under Review');
            const canReject = canApprove;
            const canShip = req.Status__c === 'Approved' && req.Resolution_Type__c === 'Replacement';

            return {
                ...req,
                badgeClass,
                canApprove,
                canReject,
                canShip,
                formattedRequestedDate: req.Requested_Date__c ? req.Requested_Date__c : 'N/A',
                formattedProcessedDate: req.Processed_Date__c ? req.Processed_Date__c : 'N/A',
                processedByName: req.Processed_By__r ? req.Processed_By__r.Name : 'N/A'
            };
        });
    }

    get processActionOptions() {
        if (this.isManager) {
            return [
                { label: 'Approve and Send to Admin', value: 'manager_approve' },
                { label: 'Reject Return', value: 'manager_reject' },
                { label: 'Send Back to Sales', value: 'manager_send_back' }
            ];
        }

        return [
            { label: 'Approve Repair', value: 'admin_repair' },
            { label: 'Approve Replacement', value: 'admin_replace' },
            { label: 'Approve Refund', value: 'admin_refund' },
            { label: 'Reject Return', value: 'admin_reject' },
            { label: 'Close Request', value: 'admin_close' }
        ];
    }

    // Search and filter tab select
    handleSearch(event) {
        this.searchKey = event.target.value;
    }

    handleFilterSelect(event) {
        this.activeFilter = event.currentTarget.dataset.value;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredReturnRequestsResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Create Request Modal Handlers
    openCreateModal() {
        this.isCreateModalOpen = true;
    }

    closeCreateModal() {
        this.isCreateModalOpen = false;
    }

    handleCreateSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Return Request created successfully',
                variant: 'success'
            })
        );
        this.closeCreateModal();
        this.handleRefresh();
    }

    // Process Return Modal Handlers
    openProcessModal(event) {
        this.selectedRequestId = event.currentTarget.dataset.id;
        this.selectedRequestName = event.currentTarget.dataset.name;
        this.processStatus = this.isManager ? 'manager_approve' : 'admin_repair';
        this.isProcessModalOpen = true;
    }

    closeProcessModal() {
        this.isProcessModalOpen = false;
    }

    handleStatusChange(event) {
        this.processStatus = event.detail.value;
    }

    submitProcessReturn() {
        let statusToSave = this.processStatus;
        let resolutionToSave = null;

        if (this.isManager) {
            if (this.processStatus === 'manager_approve') {
                statusToSave = 'Under Review';
            } else if (this.processStatus === 'manager_reject') {
                statusToSave = 'Rejected';
            } else if (this.processStatus === 'manager_send_back') {
                statusToSave = 'Submitted';
            }
        } else {
            if (this.processStatus === 'admin_repair') {
                statusToSave = 'Approved';
                resolutionToSave = 'Repair';
            } else if (this.processStatus === 'admin_replace') {
                statusToSave = 'Approved';
                resolutionToSave = 'Replacement';
            } else if (this.processStatus === 'admin_refund') {
                statusToSave = 'Refunded';
                resolutionToSave = 'Refund';
            } else if (this.processStatus === 'admin_reject') {
                statusToSave = 'Rejected';
            } else if (this.processStatus === 'admin_close') {
                statusToSave = 'Closed';
            }
        }

        this.isLoading = true;
        processReturnRequestExtended({
            requestId: this.selectedRequestId,
            status: statusToSave,
            resolutionType: resolutionToSave
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Return request processed successfully. Status: ${statusToSave}`,
                        variant: 'success'
                    })
                );
                this.closeProcessModal();
                return refreshApex(this.wiredReturnRequestsResult);
            })
            .catch(err => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error processing return',
                        message: err.body ? err.body.message : err.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Navigation helper
    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        const objectName = event.currentTarget.dataset.object;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectName,
                actionName: 'view'
            }
        });
    }

    @api
    refreshDashboard() {
        return refreshApex(this.wiredReturnRequestsResult);
    }
}