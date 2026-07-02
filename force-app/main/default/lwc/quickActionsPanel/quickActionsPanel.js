import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import isInventoryManager from '@salesforce/apex/InventoryController.isInventoryManager';

export default class QuickActionsPanel extends NavigationMixin(LightningElement) {
    isManager = false;

    connectedCallback() {
        isInventoryManager()
            .then(result => {
                this.isManager = result;
            })
            .catch(() => {
                this.isManager = false;
            });
    }

    createRecord(objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: objectApiName,
                actionName: 'new'
            }
        });
    }

    handleCreateProduct() {
        this.createRecord('Product__c');
    }

    handleCreateSupplier() {
        this.createRecord('Supplier__c');
    }

    handleCreatePO() {
        this.createRecord('Purchase_Order__c');
    }

    handleCreateSO() {
        this.createRecord('Sales_Order__c');
    }

    handleCreateTxn() {
        this.createRecord('Inventory_Transaction__c');
    }
}
