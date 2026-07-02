import { LightningElement, wire, track, api } from 'lwc';
import getPurchaseOrders from '@salesforce/apex/InventoryController.getPurchaseOrders';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class PurchaseOrderDashboard extends NavigationMixin(LightningElement) {
    wiredPOResult;
    @track purchaseOrders = [];
    error;
    @track isLoading = false;
    @track statusFilter = 'All';

    @wire(getPurchaseOrders)
    wiredData(result) {
        this.wiredPOResult = result;
        if (result.data) {
            this.purchaseOrders = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.purchaseOrders = [];
        }
    }

    get draftOrders() {
        return this.purchaseOrders.filter(po => po.Status__c === 'Draft');
    }

    get approvedOrders() {
        return this.purchaseOrders.filter(po => po.Status__c === 'Approved');
    }

    get receivedOrders() {
        return this.purchaseOrders.filter(po => po.Status__c === 'Received');
    }

    get cancelledOrders() {
        return this.purchaseOrders.filter(po => po.Status__c === 'Cancelled');
    }

    get draftCount() {
        return this.draftOrders.length;
    }

    get orderedCount() {
        return this.approvedOrders.length; // Approved represents ordered state
    }

    get receivedCount() {
        return this.receivedOrders.length;
    }

    get cancelledCount() {
        return this.cancelledOrders.length;
    }

    get recentPOs() {
        let list = [...this.purchaseOrders];
        
        if (this.statusFilter === 'Received') {
            list = list.filter(po => po.Status__c === 'Received');
        } else if (this.statusFilter === 'Pending') {
            list = list.filter(po => po.Status__c === 'Draft' || po.Status__c === 'Approved');
        }

        return list.slice(0, 5).map(po => {
            let badgeClass = 'status-badge';
            if (po.Status__c === 'Draft') badgeClass += ' draft';
            else if (po.Status__c === 'Approved') badgeClass += ' approved';
            else if (po.Status__c === 'Received') badgeClass += ' received';
            else if (po.Status__c === 'Cancelled') badgeClass += ' cancelled';
            return {
                ...po,
                badgeClass
            };
        });
    }

    get suppliersQuickView() {
        const seen = new Set();
        const list = [];
        this.purchaseOrders.forEach(po => {
            if (po.Supplier__r && !seen.has(po.Supplier__r.Id)) {
                seen.add(po.Supplier__r.Id);
                list.push({
                    id: po.Supplier__r.Id,
                    name: po.Supplier__r.Name,
                    email: po.Supplier__r.Email__c || 'N/A',
                    status: po.Supplier__r.Status__c || 'Active',
                    badgeClass: po.Supplier__r.Status__c === 'Active' ? 'status-badge healthy' : 'status-badge low-stock'
                });
            }
        });
        return list.slice(0, 4);
    }

    get hasOrders() {
        return this.recentPOs.length > 0;
    }

    // Filter button states
    get allBtnClass() {
        return this.statusFilter === 'All' ? 'slds-button slds-button_brand rounded-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    get receivedBtnClass() {
        return this.statusFilter === 'Received' ? 'slds-button slds-button_brand rounded-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    get pendingBtnClass() {
        return this.statusFilter === 'Pending' ? 'slds-button slds-button_brand rounded-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    // Actions
    handleFilterAll() {
        this.statusFilter = 'All';
    }

    handleFilterReceived() {
        this.statusFilter = 'Received';
    }

    handleFilterPending() {
        this.statusFilter = 'Pending';
    }

    navigateToCreatePO() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Purchase_Order__c',
                actionName: 'new'
            }
        });
    }

    navigateToViewAllPOs() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Purchase_Order__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    navigateToSupplierList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Supplier__c',
                actionName: 'list'
            }
        });
    }

    @api
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredPOResult)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Purchase Orders refreshed successfully.',
                        variant: 'success'
                    })
                );
            })
            .catch(err => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error refreshing Purchase Orders: ' + (err.body ? err.body.message : err.message),
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}