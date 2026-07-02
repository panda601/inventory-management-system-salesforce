import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSalesOrders from '@salesforce/apex/InventoryController.getSalesOrders';
import { refreshApex } from '@salesforce/apex';

export default class InventorySalesOrderList extends NavigationMixin(LightningElement) {
    @track salesOrders = [];
    @track activeStatus = 'All';
    @track isLoading = true;
    error;
    wiredSOsResult;

    @wire(getSalesOrders)
    wiredSOs(result) {
        this.wiredSOsResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.salesOrders = data.map(so => {
                let badgeClass = 'status-badge';
                if (so.Status__c === 'Draft') badgeClass += ' draft';
                else if (so.Status__c === 'Confirmed' || so.Status__c === 'Approved') badgeClass += ' approved';
                else if (so.Status__c === 'Delivered' || so.Status__c === 'Shipped') badgeClass += ' received';
                else if (so.Status__c === 'Cancelled') badgeClass += ' cancelled';
                
                return {
                    ...so,
                    badgeClass
                };
            });
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.salesOrders = [];
            this.isLoading = false;
        }
    }

    get filteredSOs() {
        if (this.activeStatus === 'All') {
            return this.salesOrders;
        }
        return this.salesOrders.filter(so => {
            if (this.activeStatus === 'Confirmed') {
                return so.Status__c === 'Confirmed' || so.Status__c === 'Approved';
            }
            if (this.activeStatus === 'Delivered') {
                return so.Status__c === 'Delivered' || so.Status__c === 'Shipped';
            }
            return so.Status__c === this.activeStatus;
        });
    }

    get hasSOs() {
        return this.filteredSOs && this.filteredSOs.length > 0;
    }

    handleFilterChange(event) {
        this.activeStatus = event.currentTarget.dataset.status;
    }

    handleCreateSO() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Sales_Order__c',
                actionName: 'new'
            }
        });
    }

    handleViewAllSOs() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Sales_Order__c',
                actionName: 'list'
            }
        });
    }

    handleViewDetails(event) {
        const soId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: soId,
                objectApiName: 'Sales_Order__c',
                actionName: 'view'
            }
        });
    }

    getCardClass(status) {
        return this.activeStatus === status ? 'status-card active' : 'status-card';
    }

    get allCardClass() { return this.getCardClass('All'); }
    get draftCardClass() { return this.getCardClass('Draft'); }
    get approvedCardClass() { return this.getCardClass('Confirmed'); }
    get shippedCardClass() { return this.getCardClass('Delivered'); }
    get cancelledCardClass() { return this.getCardClass('Cancelled'); }

    get allCount() { return this.salesOrders.length; }
    get draftCount() { return this.salesOrders.filter(so => so.Status__c === 'Draft').length; }
    get approvedCount() { return this.salesOrders.filter(so => so.Status__c === 'Confirmed' || so.Status__c === 'Approved').length; }
    get shippedCount() { return this.salesOrders.filter(so => so.Status__c === 'Delivered' || so.Status__c === 'Shipped').length; }
    get cancelledCount() { return this.salesOrders.filter(so => so.Status__c === 'Cancelled').length; }

    @api
    refreshList() {
        return refreshApex(this.wiredSOsResult);
    }
}