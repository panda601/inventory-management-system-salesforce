import { LightningElement, wire } from 'lwc';
import getInventorySummary from '@salesforce/apex/DashboardController.getInventorySummary';
import { refreshApex } from '@salesforce/apex';

export default class InventoryDashboard extends LightningElement {
    summaryData;
    error;
    wiredSummaryResult;

    @wire(getInventorySummary)
    wiredSummary(result) {
        this.wiredSummaryResult = result;
        if (result.data) {
            this.summaryData = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.summaryData = undefined;
        }
    }

    get totalProducts() {
        return this.summaryData ? this.summaryData.totalProducts : 0;
    }

    get availableStock() {
        return this.summaryData ? this.summaryData.availableStock : 0;
    }

    get lowStock() {
        return this.summaryData ? this.summaryData.lowStock : 0;
    }

    get outOfStock() {
        return this.summaryData ? this.summaryData.outOfStock : 0;
    }

    get pendingPurchaseOrders() {
        return this.summaryData ? this.summaryData.pendingPurchaseOrders : 0;
    }

    get pendingSalesOrders() {
        return this.summaryData ? this.summaryData.pendingSalesOrders : 0;
    }

    get stockHealthPercent() {
        if (!this.summaryData || this.summaryData.totalProducts === 0) return 100;
        const healthyCount = this.summaryData.totalProducts - this.summaryData.lowStock - this.summaryData.outOfStock;
        return Math.round((healthyCount / this.summaryData.totalProducts) * 100);
    }

    get healthStrokeDashArray() {
        const radius = 40;
        const circumference = 2 * Math.PI * radius;
        const percent = this.stockHealthPercent;
        const offset = circumference - (percent / 100) * circumference;
        return `${circumference - offset} ${offset}`;
    }

    handleRefresh() {
        refreshApex(this.wiredSummaryResult);
    }
}
