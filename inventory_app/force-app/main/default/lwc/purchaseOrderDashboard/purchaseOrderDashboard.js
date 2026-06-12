import { LightningElement, wire, track } from 'lwc';
import getPurchaseOrders from '@salesforce/apex/InventoryController.getPurchaseOrders';
import { refreshApex } from '@salesforce/apex';

export default class PurchaseOrderDashboard extends LightningElement {
    wiredPOResult;
    @track activeTab = 'Draft';
    @track purchaseOrders = [];
    error;

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

    get tabOptions() {
        return [
            { label: 'Draft', value: 'Draft', count: this.draftOrders.length, class: this.activeTab === 'Draft' ? 'tab-btn active' : 'tab-btn' },
            { label: 'Approved', value: 'Approved', count: this.approvedOrders.length, class: this.activeTab === 'Approved' ? 'tab-btn active' : 'tab-btn' },
            { label: 'Received', value: 'Received', count: this.receivedOrders.length, class: this.activeTab === 'Received' ? 'tab-btn active' : 'tab-btn' }
        ];
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

    get currentOrders() {
        if (this.activeTab === 'Draft') return this.draftOrders;
        if (this.activeTab === 'Approved') return this.approvedOrders;
        return this.receivedOrders;
    }

    get hasOrders() {
        return this.currentOrders.length > 0;
    }

    handleTabClick(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    handleRefresh() {
        refreshApex(this.wiredPOResult);
    }
}
