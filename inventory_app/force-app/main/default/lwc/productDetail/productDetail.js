import { LightningElement, wire, track } from 'lwc';
import { subscribe, MessageContext, unsubscribe } from 'lightning/messageService';
import PRODUCT_SELECTED_CHANNEL from '@salesforce/messageChannel/ProductSelected__c';
import getProductDetail from '@salesforce/apex/ProductController.getProductDetail';
import getProductSupplier from '@salesforce/apex/ProductController.getProductSupplier';
import getProductTransactions from '@salesforce/apex/ProductController.getProductTransactions';

export default class ProductDetail extends LightningElement {
    @track productId = '';
    subscription = null;

    @wire(MessageContext)
    messageContext;

    @wire(getProductDetail, { productId: '$productId' })
    product;

    @wire(getProductSupplier, { productId: '$productId' })
    supplier;

    @wire(getProductTransactions, { productId: '$productId' })
    transactions;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                PRODUCT_SELECTED_CHANNEL,
                (message) => this.handleProductSelected(message)
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleProductSelected(message) {
        this.productId = message.productId;
    }

    get hasProduct() {
        return !!this.productId;
    }

    get isLowStock() {
        if (!this.product || !this.product.data) return false;
        const p = this.product.data;
        return p.Current_Stock__c <= p.Minimum_Stock__c && p.Current_Stock__c > 0;
    }

    get isOutOfStock() {
        if (!this.product || !this.product.data) return false;
        const p = this.product.data;
        return p.Current_Stock__c === 0;
    }

    get isHealthy() {
        if (!this.product || !this.product.data) return false;
        const p = this.product.data;
        return p.Current_Stock__c > p.Minimum_Stock__c;
    }

    get stockStatusLabel() {
        if (this.isOutOfStock) return 'Out of Stock';
        if (this.isLowStock) return 'Low Stock';
        return 'Healthy';
    }

    get stockStatusClass() {
        if (this.isOutOfStock) return 'status-badge out-of-stock';
        if (this.isLowStock) return 'status-badge low-stock';
        return 'status-badge healthy';
    }
}
