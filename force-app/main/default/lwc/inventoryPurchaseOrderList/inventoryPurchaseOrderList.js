import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPurchaseOrders from '@salesforce/apex/InventoryController.getPurchaseOrders';
import { refreshApex } from '@salesforce/apex';

export default class InventoryPurchaseOrderList extends NavigationMixin(LightningElement) {
    @track purchaseOrders = [];
    @track activeStatus = 'All';
    @track isLoading = true;
    error;
    wiredPOsResult;

    @wire(getPurchaseOrders)
    wiredPOs(result) {
        this.wiredPOsResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.purchaseOrders = data.map(po => {
                let badgeClass = 'status-badge';
                if (po.Status__c === 'Draft') badgeClass += ' draft';
                else if (po.Status__c === 'Approved') badgeClass += ' approved';
                else if (po.Status__c === 'Received') badgeClass += ' received';
                else if (po.Status__c === 'Cancelled') badgeClass += ' cancelled';
                
                return {
                    ...po,
                    SupplierName: po.Supplier__r ? po.Supplier__r.Supplier_Name__c || po.Supplier__r.Name : 'N/A',
                    badgeClass
                };
            });
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.purchaseOrders = [];
            this.isLoading = false;
        }
    }

    get filteredPOs() {
        if (this.activeStatus === 'All') {
            return this.purchaseOrders;
        }
        return this.purchaseOrders.filter(po => po.Status__c === this.activeStatus);
    }

    get hasPOs() {
        return this.filteredPOs && this.filteredPOs.length > 0;
    }

    @api
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredPOsResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleFilterChange(event) {
        this.activeStatus = event.currentTarget.dataset.status;
    }

    handleCreatePO() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Purchase_Order__c',
                actionName: 'new'
            }
        });
    }

    handleViewDetails(event) {
        const poId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: poId,
                objectApiName: 'Purchase_Order__c',
                actionName: 'view'
            }
        });
    }

    handleViewAllPOs() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Purchase_Order__c',
                actionName: 'list'
            }
        });
    }

    getCardClass(status) {
        return this.activeStatus === status ? 'status-card active' : 'status-card';
    }

    get allCardClass() { return this.getCardClass('All'); }
    get draftCardClass() { return this.getCardClass('Draft'); }
    get orderedCardClass() { return this.getCardClass('Approved'); }
    get receivedCardClass() { return this.getCardClass('Received'); }
    get cancelledCardClass() { return this.getCardClass('Cancelled'); }

    get allCount() { return this.purchaseOrders.length; }
    get draftCount() { return this.purchaseOrders.filter(po => po.Status__c === 'Draft').length; }
    get orderedCount() { return this.purchaseOrders.filter(po => po.Status__c === 'Approved').length; }
    get receivedCount() { return this.purchaseOrders.filter(po => po.Status__c === 'Received').length; }
    get cancelledCount() { return this.purchaseOrders.filter(po => po.Status__c === 'Cancelled').length; }
}