import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSupplierPerformanceData from '@salesforce/apex/InventoryDashboardController.getSupplierPerformanceData';
import { refreshApex } from '@salesforce/apex';

export default class SupplierPerformance extends NavigationMixin(LightningElement) {
    @track supplierData = [];
    @track isLoading = false;
    wiredResult;

    @wire(getSupplierPerformanceData)
    wiredPerformance(result) {
        this.wiredResult = result;
        const { error, data } = result;
        if (data) {
            this.supplierData = data;
        } else if (error) {
            console.error('Error loading supplier performance', error);
        }
    }

    get suppliersPerformance() {
        if (!this.supplierData) return [];
        return this.supplierData.map(sup => {
            let ratingClass = 'rating-badge ';
            if (sup.rating >= 90) {
                ratingClass += 'rating-excellent';
            } else if (sup.rating >= 80) {
                ratingClass += 'rating-good';
            } else {
                ratingClass += 'rating-poor';
            }
            return {
                ...sup,
                ratingClass
            };
        });
    }

    get hasSuppliers() {
        return this.suppliersPerformance.length > 0;
    }

    navigateToSuppliers() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Supplier__c',
                actionName: 'list'
            }
        });
    }

    @api
    refreshDashboard() {
        this.isLoading = true;
        return refreshApex(this.wiredResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRefresh() {
        return this.refreshDashboard();
    }
}
