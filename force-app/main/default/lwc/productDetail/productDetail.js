import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, MessageContext, unsubscribe } from 'lightning/messageService';
import PRODUCT_SELECTED_CHANNEL from '@salesforce/messageChannel/ProductSelected__c';
import getProduct from '@salesforce/apex/ProductController.getProduct';
import getInventory from '@salesforce/apex/ProductController.getInventory';
import getSupplier from '@salesforce/apex/ProductController.getSupplier';
import getTransactions from '@salesforce/apex/ProductController.getTransactions';
import isInventoryManager from '@salesforce/apex/InventoryController.isInventoryManager';
import { refreshApex } from '@salesforce/apex';

export default class ProductDetail extends NavigationMixin(LightningElement) {
    @track productId = '';
    @track activeTab = 'overview';
    subscription = null;
    isManager = false;
    _recordId;

    @api 
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        // eslint-disable-next-line no-console
        console.log('ProductDetail recordId received:', value);
        if (value) {
            this.productId = value;
            this.activeTab = 'overview';
        }
    }

    @wire(isInventoryManager)
    wiredManager({ error, data }) {
        if (data !== undefined) {
            this.isManager = data;
        } else if (error) {
            this.isManager = false;
        }
    }

    @wire(MessageContext)
    messageContext;

    @wire(getProduct, { recordId: '$productId' })
    product;

    @wire(getInventory, { recordId: '$productId' })
    inventory;

    @wire(getSupplier, { recordId: '$productId' })
    supplier;

    @wire(getTransactions, { recordId: '$productId' })
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
        // Only update if not explicitly embedded on a standard record page
        if (!this._recordId) {
            // eslint-disable-next-line no-console
            console.log('ProductDetail LMS productId:', message.productId);
            this.productId = message.productId;
            this.activeTab = 'overview';
        }
    }

    handleTabSelect(event) {
        this.activeTab = event.target.value || event.detail.value || 'overview';
    }

    get hasProduct() {
        return !!this.productId;
    }

    get hasProductData() {
        return !!(this.product && this.product.data);
    }

    get productImageSrc() {
        const fallbackImage = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" viewBox="0 0 100 100"><rect width="100%" height="100%" fill="%23f8f9fa" stroke="%23dddbda" stroke-width="1"/><rect x="25" y="25" width="50" height="50" rx="4" fill="none" stroke="%23b0adab" stroke-width="2"/><circle cx="50" cy="45" r="10" fill="none" stroke="%23b0adab" stroke-width="2"/><path d="M30 65 L45 50 L55 60 L70 45 L70 65 Z" fill="%23cbd5e0"/><text x="50%" y="85%" dominant-baseline="middle" text-anchor="middle" font-family="sans-serif" font-size="8" fill="%23706e6b">No Image</text></svg>`;

        if (this.product && this.product.data && this.product.data.productImage) {
            return this.product.data.productImage;
        }
        return fallbackImage;
    }

    get showSpinner() {
        return this.hasProduct && this.product && !this.product.data && !this.product.error;
    }

    get isOverviewActive() {
        return this.activeTab === 'overview';
    }

    get isInventoryActive() {
        return this.activeTab === 'inventory';
    }

    get isSupplierActive() {
        return this.activeTab === 'supplier';
    }

    get isTransactionsActive() {
        return this.activeTab === 'transactions';
    }

    get isLowStock() {
        if (!this.inventory || !this.inventory.data) return false;
        const p = this.inventory.data;
        return p.Current_Stock__c <= p.Minimum_Stock__c && p.Current_Stock__c > 0;
    }

    get isOutOfStock() {
        if (!this.inventory || !this.inventory.data) return false;
        const p = this.inventory.data;
        return p.Current_Stock__c === 0;
    }

    get isHealthy() {
        if (!this.inventory || !this.inventory.data) return false;
        const p = this.inventory.data;
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

    get stockPercentage() {
        if (!this.inventory || !this.inventory.data) return 0;
        const current = this.inventory.data.Current_Stock__c || 0;
        const min = this.inventory.data.Minimum_Stock__c || 10;
        const base = min * 3;
        const pct = Math.round((current / base) * 100);
        return pct > 100 ? 100 : pct;
    }

    get showReorderRec() {
        return this.isLowStock || this.isOutOfStock;
    }

    get availableQuantity() {
        if (!this.inventory || !this.inventory.data) return 0;
        return this.inventory.data.Current_Stock__c || 0;
    }

    get costPrice() {
        if (!this.hasProductData) return null;
        return this.product.data.costPrice;
    }

    get recommendationQuantity() {
        if (!this.inventory || !this.inventory.data) return 0;
        const min = this.inventory.data.Minimum_Stock__c || 10;
        const current = this.inventory.data.Current_Stock__c || 0;
        return (min * 2) - current;
    }

    get supplierPerformanceScore() {
        if (!this.supplier || !this.supplier.data) return 'N/A';
        return '98% (Excellent)';
    }

    get supplierEmailHref() {
        if (!this.supplier || !this.supplier.data || !this.supplier.data.Email__c) {
            return null;
        }
        return `mailto:${this.supplier.data.Email__c}`;
    }

    get supplierName() {
        if (!this.supplier || !this.supplier.data) {
            return null;
        }
        return this.supplier.data.Supplier_Name__c || this.supplier.data.Name;
    }

    get hasSupplier() {
        return !!(this.supplier && this.supplier.data);
    }

    get supplierLoaded() {
        return !!(this.supplier && (this.supplier.data || this.supplier.error));
    }

    get hasTransactions() {
        return !!(this.transactions && this.transactions.data && this.transactions.data.length);
    }

    get transactionsLoaded() {
        return !!(this.transactions && (this.transactions.data || this.transactions.error));
    }

    get inventoryLoaded() {
        return !!(this.inventory && (this.inventory.data || this.inventory.error));
    }

    get hasInventory() {
        return !!(this.inventory && this.inventory.data);
    }

    get productErrorMessage() {
        return this.product?.error?.body?.message || 'Unable to load product details.';
    }

    get inventoryErrorMessage() {
        return this.inventory?.error?.body?.message || 'Unable to load inventory details.';
    }

    get supplierErrorMessage() {
        return this.supplier?.error?.body?.message || 'Unable to load supplier details.';
    }

    get transactionsErrorMessage() {
        return this.transactions?.error?.body?.message || 'Unable to load transactions.';
    }

    handleProductNameClick(event) {
        event.preventDefault();

        if (!this.productId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.productId,
                objectApiName: 'Product__c',
                actionName: 'view'
            }
        });
    }

    @api
    refreshDetail() {
        refreshApex(this.product);
        refreshApex(this.inventory);
        refreshApex(this.supplier);
        refreshApex(this.transactions);
    }
}
