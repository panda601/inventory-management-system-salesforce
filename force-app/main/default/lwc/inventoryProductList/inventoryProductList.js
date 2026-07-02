import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import { refreshApex } from '@salesforce/apex';

export default class InventoryProductList extends NavigationMixin(LightningElement) {
    @track products = [];
    @track isLoading = true;
    error;
    wiredProductsResult;

    @wire(getProducts, { searchKey: '', categoryFilter: 'All' })
    wiredProducts(result) {
        this.wiredProductsResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.products = data.map(prod => {
                let badgeClass = 'status-badge';
                if (prod.Status__c === 'Active') {
                    badgeClass += ' healthy';
                } else {
                    badgeClass += ' low-stock';
                }
                return {
                    ...prod,
                    badgeClass
                };
            });
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.products = [];
            this.isLoading = false;
        }
    }

    get hasProducts() {
        return this.products && this.products.length > 0;
    }

    @api
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredProductsResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleViewDetails(event) {
        event.preventDefault();
        const prodId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: prodId,
                objectApiName: 'Product__c',
                actionName: 'view'
            }
        });
    }

    handleCreateProduct() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Product__c',
                actionName: 'new'
            }
        });
    }
}
