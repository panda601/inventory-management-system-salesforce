import { LightningElement, wire, track, api } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import PRODUCT_SELECTED_CHANNEL from '@salesforce/messageChannel/ProductSelected__c';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class ProductCatalog extends NavigationMixin(LightningElement) {
    @api isSalesExecutive = false;
    @track searchKey = '';
    @track categoryFilter = 'All';
    @track sortBy = 'name-asc';
    wiredProductsResult;
    productSubscription;

    @wire(MessageContext)
    messageContext;

    @wire(getProducts, { searchKey: '$searchKey', categoryFilter: '$categoryFilter' })
    wiredProducts(result) {
        this.wiredProductsResult = result;
        this.products = result;
    }

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

    get sortOptions() {
        return [
            { label: 'Sort: Name (A-Z)', value: 'name-asc' },
            { label: 'Sort: Name (Z-A)', value: 'name-desc' },
            { label: 'Sort: Price (Low-High)', value: 'price-asc' },
            { label: 'Sort: Price (High-Low)', value: 'price-desc' },
            { label: 'Sort: Stock (Low-High)', value: 'stock-asc' },
            { label: 'Sort: Stock (High-Low)', value: 'stock-desc' }
        ];
    }

    fallbackImage = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 100 100"><rect width="100" height="100" fill="%23f8f9fa" stroke="%23dddbda" stroke-width="1"/><rect x="25" y="25" width="50" height="50" rx="4" fill="none" stroke="%23b0adab" stroke-width="2"/><circle cx="50" cy="45" r="10" fill="none" stroke="%23b0adab" stroke-width="2"/><path d="M30 65 L45 50 L55 60 L70 45 L70 65 Z" fill="%23cbd5e0"/><text x="50%" y="85%" dominant-baseline="middle" text-anchor="middle" font-family="sans-serif" font-size="8" fill="%23706e6b">No Image</text></svg>`;

    handleImageError(event) {
        event.target.src = this.fallbackImage;
    }

    get sortedProducts() {
        if (!this.products || !this.products.data) {
            return [];
        }

        let clonedProducts = this.products.data.map(prod => {
            const current = prod.Current_Stock__c || 0;
            const min = prod.Minimum_Stock__c || 0;
            let status = 'In Stock';
            let badgeClass = 'status-badge healthy';
            
            if (current === 0) {
                status = 'Out of Stock';
                badgeClass = 'status-badge out-of-stock';
            } else if (current <= min) {
                status = 'Low Stock';
                badgeClass = 'status-badge low-stock';
            }
            
            const productImageSrc = prod.Product_Image__c ? prod.Product_Image__c : this.fallbackImage;
            
            return {
                ...prod,
                status,
                badgeClass,
                productImageSrc
            };
        });

        if (this.isSalesExecutive) {
            const allowedNames = [
                'Dell Latitude 5440',
                'HP ProBook 450',
                'Lenovo ThinkPad E14',
                'Dell Monitor 24',
                'Dell Monitor 24"',
                'Logitech Keyboard',
                'Logitech Mouse'
            ];
            clonedProducts = clonedProducts.filter(prod => {
                const name = prod.Product_Name__c || '';
                return allowedNames.includes(name) || allowedNames.includes(name.trim());
            });
        }
        
        clonedProducts.sort((a, b) => {
            const nameA = a.Product_Name__c || '';
            const nameB = b.Product_Name__c || '';
            
            switch (this.sortBy) {
                case 'name-asc':
                    return nameA.localeCompare(nameB);
                case 'name-desc':
                    return nameB.localeCompare(nameA);
                case 'sku-asc':
                    return (a.SKU__c || '').localeCompare(b.SKU__c || '');
                case 'price-asc':
                    return (a.Price__c || 0) - (b.Price__c || 0);
                case 'price-desc':
                    return (b.Price__c || 0) - (a.Price__c || 0);
                case 'stock-asc':
                    return (a.Current_Stock__c || 0) - (b.Current_Stock__c || 0);
                case 'stock-desc':
                    return (b.Current_Stock__c || 0) - (a.Current_Stock__c || 0);
                default:
                    return nameA.localeCompare(nameB);
            }
        });
        
        return clonedProducts;
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value;
    }

    handleCategoryChange(event) {
        this.categoryFilter = event.target.value;
    }

    handleSortChange(event) {
        this.sortBy = event.target.value;
    }

    handleProductClick(event) {
        const productId = event.currentTarget.dataset.id;
        
        const payload = { productId: productId };
        publish(this.messageContext, PRODUCT_SELECTED_CHANNEL, payload);
        
        const selectEvent = new CustomEvent('productselect', {
            detail: productId
        });
        this.dispatchEvent(selectEvent);
    }

    handleProductNameClick(event) {
        event.preventDefault();
        event.stopPropagation();

        const productId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product__c',
                actionName: 'view'
            }
        });
    }

    connectedCallback() {
        this.subscribeToProductChanges();
    }

    disconnectedCallback() {
        if (this.productSubscription) {
            unsubscribe(this.productSubscription);
            this.productSubscription = null;
        }
    }

    subscribeToProductChanges() {
        subscribe('/data/Product__ChangeEvent', -1, () => {
            this.refreshCatalog();
        }).then(response => {
            this.productSubscription = response;
        });

        onError(error => {
            // Keep the catalog usable if CDC is unavailable.
            // eslint-disable-next-line no-console
            console.error('Product catalog CDC error', error);
        });
    }

    @api
    refreshCatalog() {
        return refreshApex(this.wiredProductsResult);
    }
}