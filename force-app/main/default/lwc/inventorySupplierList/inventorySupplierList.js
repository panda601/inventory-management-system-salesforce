import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSuppliers from '@salesforce/apex/InventoryController.getSuppliers';
import { refreshApex } from '@salesforce/apex';

export default class InventorySupplierList extends NavigationMixin(LightningElement) {
    @track suppliers = [];
    @track isLoading = true;
    error;
    wiredSuppliersResult;

    @wire(getSuppliers)
    wiredSuppliers(result) {
        this.wiredSuppliersResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.suppliers = data.map(sup => {
                let badgeClass = 'status-badge';
                if (sup.Status__c === 'Active') badgeClass += ' healthy';
                else badgeClass += ' low-stock';
                return {
                    ...sup,
                    SupplierName: sup.Supplier_Name__c || sup.Name,
                    badgeClass
                };
            });
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.suppliers = [];
            this.isLoading = false;
        }
    }

    get hasSuppliers() {
        return this.suppliers && this.suppliers.length > 0;
    }

    @api
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredSuppliersResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleViewDetails(event) {
        const supplierId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: supplierId,
                objectApiName: 'Supplier__c',
                actionName: 'view'
            }
        });
    }

    handleCreateSupplier() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Supplier__c',
                actionName: 'new'
            }
        });
    }
}