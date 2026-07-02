import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSalesSummary from '@salesforce/apex/InventoryDashboardController.getSalesSummary';
import getMonitorData from '@salesforce/apex/InventoryController.getMonitorData';
import { refreshApex } from '@salesforce/apex';

export default class ProductPerformanceLeaderboard extends NavigationMixin(LightningElement) {
    @track salesSummary = {};
    @track products = [];
    @track activeFilter = 'top-selling';
    error;

    wiredSalesResult;
    wiredProductsResult;

    @wire(getSalesSummary)
    wiredSales(result) {
        this.wiredSalesResult = result;
        if (result.data) {
            this.salesSummary = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getMonitorData)
    wiredProducts(result) {
        this.wiredProductsResult = result;
        if (result.data) {
            this.products = result.data;
        }
    }

    fallbackImage = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 100 100"><rect width="100%" height="100%" fill="%23f8f9fa" stroke="%23dddbda" stroke-width="1"/><rect x="25" y="25" width="50" height="50" rx="4" fill="none" stroke="%23b0adab" stroke-width="2"/><circle cx="50" cy="45" r="10" fill="none" stroke="%23b0adab" stroke-width="2"/><path d="M30 65 L45 50 L55 60 L70 45 L70 65 Z" fill="%23cbd5e0"/></svg>`;

    handleImageError(event) {
        event.target.src = this.fallbackImage;
    }

    get productSales() {
        return this.salesSummary.productSales || [];
    }

    get productSalesWithImages() {
        return this.productSales.map(item => ({
            ...item,
            productImageSrc: item.productImage || this.fallbackImage
        }));
    }

    get topSelling() {
        const list = [...this.productSalesWithImages];
        list.sort((a, b) => b.quantitySold - a.quantitySold);
        return list.slice(0, 5);
    }

    get topRevenue() {
        const list = [...this.productSalesWithImages];
        list.sort((a, b) => b.totalSales - a.totalSales);
        return list.slice(0, 5);
    }

    get leastSelling() {
        const soldMap = {};
        this.productSales.forEach(s => {
            soldMap[s.productName] = s.quantitySold;
        });

        const list = this.products.map(p => {
            const name = p.Product_Name__c || p.Name;
            return {
                productName: name,
                quantitySold: soldMap[name] || 0,
                productImageSrc: p.Product_Image__c || this.fallbackImage
            };
        });

        list.sort((a, b) => a.quantitySold - b.quantitySold);
        return list.slice(0, 5);
    }

    get hasData() {
        return this.productSales.length > 0;
    }

    // Tab active states
    get isTopSelling() {
        return this.activeFilter === 'top-selling';
    }

    get isTopRevenue() {
        return this.activeFilter === 'top-revenue';
    }

    get isLeastSelling() {
        return this.activeFilter === 'least-selling';
    }

    // Dynamic button class assignments
    get topSellingBtnClass() {
        return this.activeFilter === 'top-selling' ? 'slds-button slds-button_brand rounded-btn active-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    get topRevenueBtnClass() {
        return this.activeFilter === 'top-revenue' ? 'slds-button slds-button_brand rounded-btn active-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    get leastSellingBtnClass() {
        return this.activeFilter === 'least-selling' ? 'slds-button slds-button_brand rounded-btn active-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    // Actions
    handleFilterSelect(event) {
        this.activeFilter = event.currentTarget.dataset.filter;
    }

    @api
    handleRefresh() {
        return Promise.all([
            refreshApex(this.wiredSalesResult),
            refreshApex(this.wiredProductsResult)
        ]);
    }

    navigateToProducts() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Product__c',
                actionName: 'home'
            }
        });
    }
}