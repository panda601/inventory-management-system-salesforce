import { LightningElement, wire, track } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import PRODUCT_SELECTED_CHANNEL from '@salesforce/messageChannel/ProductSelected__c';
import getProducts from '@salesforce/apex/ProductController.getProducts';

export default class ProductCatalog extends LightningElement {
    @track searchKey = '';
    @track categoryFilter = 'All';

    @wire(MessageContext)
    messageContext;

    @wire(getProducts, { searchKey: '$searchKey', categoryFilter: '$categoryFilter' })
    products;

    get categoryOptions() {
        return [
            { label: 'All Categories', value: 'All' },
            { label: 'Electronics', value: 'Electronics' },
            { label: 'Apparel', value: 'Apparel' },
            { label: 'Food', value: 'Food' },
            { label: 'Home', value: 'Home' },
            { label: 'Other', value: 'Other' }
        ];
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value;
    }

    handleCategoryChange(event) {
        this.categoryFilter = event.target.value;
    }

    handleProductSelect(event) {
        const productId = event.currentTarget.dataset.id;
        const payload = { productId: productId };
        publish(this.messageContext, PRODUCT_SELECTED_CHANNEL, payload);
        
        // Also fire standard custom event for nested configurations
        const selectEvent = new CustomEvent('productselect', {
            detail: productId
        });
        this.dispatchEvent(selectEvent);
    }
}
