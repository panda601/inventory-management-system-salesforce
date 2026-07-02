import { LightningElement, wire, track, api } from 'lwc';
import getPurchaseOrders from '@salesforce/apex/InventoryController.getPurchaseOrders';
import getRecentSalesOrders from '@salesforce/apex/InventoryController.getRecentSalesOrders';
import isInventoryManager from '@salesforce/apex/InventoryController.isInventoryManager';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class RecentOrdersWidget extends NavigationMixin(LightningElement) {
    @track purchaseOrders = [];
    @track salesOrders = [];
    isManager = false;
    error;

    @wire(isInventoryManager)
    wiredManager({ error, data }) {
        if (data !== undefined) {
            this.isManager = data;
        } else if (error) {
            this.isManager = false;
        }
    }

    wiredPOsResult;
    @wire(getPurchaseOrders)
    wiredPOs(result) {
        this.wiredPOsResult = result;
        if (result.data) {
            this.purchaseOrders = result.data.slice(0, 5);
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    wiredSalesOrdersResult;
    @wire(getRecentSalesOrders)
    wiredSalesOrders(result) {
        this.wiredSalesOrdersResult = result;
        if (result.data) {
            this.salesOrders = result.data.slice(0, 5).map(so => {
                return {
                    Id: so.Id,
                    Name: so.Name,
                    CustomerName: so.Customer_Name__c,
                    Date: so.Order_Date__c,
                    Amount: so.Total_Amount__c,
                    Status: so.Status__c
                };
            });
        } else if (result.error) {
            this.error = result.error;
        }
    }

    navigateToPO(event) {
        const recordId = event.currentTarget.dataset.id;
        this.navigateToRecord(recordId, 'Purchase_Order__c');
    }

    navigateToSO(event) {
        const recordId = event.currentTarget.dataset.id;
        this.navigateToRecord(recordId, 'Sales_Order__c');
    }

    navigateToRecord(recordId, objectName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectName,
                actionName: 'view'
            }
        });
    }

    get salesOrderColumnClass() {
        return this.isManager 
            ? 'slds-col slds-size_1-1 slds-medium-size_1-2 slds-m-bottom_small' 
            : 'slds-col slds-size_1-1 slds-m-bottom_small';
    }

    get hasPOs() {
        return this.purchaseOrders.length > 0;
    }

    get hasSOs() {
        return this.salesOrders.length > 0;
    }

    @api
    refreshWidget() {
        refreshApex(this.wiredPOsResult);
        refreshApex(this.wiredSalesOrdersResult);
    }
}
