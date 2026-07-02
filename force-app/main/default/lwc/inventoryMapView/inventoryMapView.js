import { LightningElement, wire, track } from 'lwc';
import getInventorySummary from '@salesforce/apex/InventoryDashboardController.getInventorySummary';

export default class InventoryMapView extends LightningElement {
    @track summary = {};
    error;

    @wire(getInventorySummary)
    wiredData(result) {
        if (result.data) {
            this.summary = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    get healthyStock() {
        const total = this.summary.totalProducts || 0;
        const low = this.summary.lowStock || 0;
        const out = this.summary.outOfStock || 0;
        const healthy = total - low - out;
        return healthy > 0 ? healthy : 0;
    }

    get lowStock() {
        return this.summary.lowStock || 0;
    }

    get outOfStock() {
        return this.summary.outOfStock || 0;
    }

    get pendingOrders() {
        const po = this.summary.pendingPurchaseOrders || 0;
        const so = this.summary.pendingSalesOrders || 0;
        return po + so;
    }
}
