import { LightningElement, wire, track, api } from 'lwc';
import getReturnRequests from '@salesforce/apex/InventoryController.getReturnRequests';
import getUserRole from '@salesforce/apex/InventoryController.getUserRole';
import processReturnRequestExtended from '@salesforce/apex/InventoryController.processReturnRequestExtended';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ApprovalCenter extends LightningElement {
    @track returnRequests = [];
    @track userRole = '';
    @track isLoading = true;
    error;

    // Modal tracking
    @track isModalOpen = false;
    @track selectedRequestId = '';
    @track selectedRequestName = '';
    @track actionType = ''; // 'Approve' or 'Reject'
    @track resolutionType = '';
    @track comments = '';

    wiredRequestsResult;

    @wire(getUserRole)
    wiredRole({ error, data }) {
        if (data) {
            this.userRole = data;
        } else if (error) {
            this.userRole = 'Sales';
        }
    }

    @wire(getReturnRequests)
    wiredRequests(result) {
        this.wiredRequestsResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.returnRequests = data.map(req => {
                let badgeClass = 'status-badge';
                if (req.Status__c === 'Submitted') badgeClass += ' draft';
                else if (req.Status__c === 'Under Review') badgeClass += ' approved';
                else if (req.Status__c === 'Approved') badgeClass += ' received';
                else if (req.Status__c === 'Rejected') badgeClass += ' cancelled';

                let formattedRequestedDate = '';
                if (req.Requested_Date__c) {
                    try {
                        formattedRequestedDate = new Date(req.Requested_Date__c).toLocaleDateString();
                    } catch (e) {
                        formattedRequestedDate = req.Requested_Date__c;
                    }
                }

                return {
                    ...req,
                    badgeClass,
                    formattedRequestedDate
                };
            });
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.returnRequests = [];
            this.isLoading = false;
        }
    }

    get isAdminRole() {
        return this.userRole === 'Admin';
    }

    get isManagerRole() {
        return this.userRole === 'Manager';
    }

    get pendingApprovals() {
        if (this.isAdminRole) {
            // Admins approve Return Requests in 'Under Review' status
            return this.returnRequests.filter(req => req.Status__c === 'Under Review');
        } else if (this.isManagerRole) {
            // Managers approve Return Requests in 'Submitted' status (which moves them to 'Under Review')
            return this.returnRequests.filter(req => req.Status__c === 'Submitted');
        }
        return [];
    }

    get hasPendingApprovals() {
        return this.pendingApprovals && this.pendingApprovals.length > 0;
    }

    @api
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredRequestsResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleActionClick(event) {
        this.selectedRequestId = event.currentTarget.dataset.id;
        this.selectedRequestName = event.currentTarget.dataset.name;
        this.actionType = event.currentTarget.dataset.action;
        this.resolutionType = '';
        this.comments = '';
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedRequestId = '';
        this.selectedRequestName = '';
        this.actionType = '';
        this.resolutionType = '';
        this.comments = '';
    }

    handleResolutionChange(event) {
        this.resolutionType = event.target.value;
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    get modalTitle() {
        return `${this.actionType} Return Request ${this.selectedRequestName}`;
    }

    get isApproveAction() {
        return this.actionType === 'Approve';
    }

    get actionButtonLabel() {
        return this.isApproveAction ? 'Confirm Approval' : 'Confirm Rejection';
    }

    get actionButtonVariant() {
        return this.isApproveAction ? 'success' : 'destructive';
    }

    submitAction() {
        if (this.isApproveAction && this.isAdminRole && !this.resolutionType) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Resolution Required',
                    message: 'Please select a resolution type.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isLoading = true;
        
        let targetStatus = '';
        if (this.actionType === 'Approve') {
            targetStatus = this.isAdminRole ? 'Approved' : 'Under Review';
        } else {
            targetStatus = 'Rejected';
        }

        // Standard processReturnRequestExtended Apex Call
        processReturnRequestExtended({
            requestId: this.selectedRequestId,
            status: targetStatus,
            resolutionType: this.resolutionType
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Return Request ${this.selectedRequestName} has been ${this.actionType.toLowerCase()}d successfully.`,
                    variant: 'success'
                })
            );
            this.closeModal();
            this.handleRefresh();
            // Notify parent components to refresh their data
            this.dispatchEvent(new CustomEvent('refreshdata', { bubbles: true, composed: true }));
        })
        .catch(err => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error processing approval: ' + (err.body ? err.body.message : err.message),
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
}
