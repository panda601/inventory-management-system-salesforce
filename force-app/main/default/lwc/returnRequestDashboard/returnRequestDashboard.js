import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getReturnRequests from '@salesforce/apex/InventoryController.getReturnRequests';
import processReturnRequest from '@salesforce/apex/InventoryController.processReturnRequest';
import getUserRole from '@salesforce/apex/InventoryController.getUserRole';

export default class ReturnRequestDashboard extends NavigationMixin(LightningElement) {
    @api userRole = 'Sales'; // Passed from parent or loaded locally
    @track returnRequests = [];
    @track searchKey = '';
    @track activeFilter = 'All';
    @track isLoading = false;
    @track error;

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
            getUserRole()
                .then(result => {
                    this.userRole = result;
                })
                .catch(err => {
                    this.error = err;
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

    // Metric getters
    get totalCount() {
        return this.returnRequests.length;
    }

    get submittedCount() {
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
        return this.returnRequests.filter(req => req.Status__c === 'Rejected').length;
    }

    // Filter tabs available based on role
    get filterOptions() {
        const optionsList = this.isSales ? [
            { label: 'All My Returns', value: 'All' },
            { label: 'Pending Approval', value: 'Pending' },
            { label: 'Approved & Replacements', value: 'Approved' },
            { label: 'Rejected', value: 'Rejected' }
        ] : [
            { label: 'All Returns', value: 'All' },
            { label: 'Pending Review', value: 'Pending' },
            { label: 'Approved (Replacement Pending)', value: 'Approved' },
            { label: 'Replacement Sent', value: 'Replacement Sent' },
            { label: 'Rejected', value: 'Rejected' }
        ];
        return optionsList.map(opt => ({
            ...opt,
            activeClass: this.activeFilter === opt.value ? 'tab-item active' : 'tab-item'
        }));
    }

    // Filtered data displayed in the table
    get filteredRequests() {
        let data = this.returnRequests;

        // Apply filter tab
        if (this.activeFilter === 'Pending') {
            data = data.filter(req => req.Status__c === 'Submitted' || req.Status__c === 'Under Review');
        } else if (this.activeFilter === 'Approved') {
            data = data.filter(req => req.Status__c === 'Approved');
        } else if (this.activeFilter === 'Replacement Sent') {
            data = data.filter(req => req.Status__c === 'Replacement Sent');
        } else if (this.activeFilter === 'Rejected') {
            data = data.filter(req => req.Status__c === 'Rejected');
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
            else badgeClass += 'slds-theme_light';

            const canApprove = req.Status__c === 'Submitted' || req.Status__c === 'Under Review';
            const canReject = req.Status__c === 'Submitted' || req.Status__c === 'Under Review';
            const canShip = req.Status__c === 'Approved';

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

    // Process Return Actions
    handleApprove(event) {
        const requestId = event.currentTarget.dataset.id;
        this.updateStatus(requestId, 'Approved');
    }

    handleReject(event) {
        const requestId = event.currentTarget.dataset.id;
        this.updateStatus(requestId, 'Rejected');
    }

    handleShipReplacement(event) {
        const requestId = event.currentTarget.dataset.id;
        this.updateStatus(requestId, 'Replacement Sent');
    }

    updateStatus(requestId, status) {
        this.isLoading = true;
        processReturnRequest({ requestId, status })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Return request status updated to ${status}`,
                        variant: 'success'
                    })
                );
                return refreshApex(this.wiredReturnRequestsResult);
            })
            .catch(err => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating return request',
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
}
