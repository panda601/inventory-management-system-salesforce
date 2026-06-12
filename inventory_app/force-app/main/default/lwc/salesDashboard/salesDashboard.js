import { LightningElement, wire } from 'lwc';
import getSalesSummary from '@salesforce/apex/DashboardController.getSalesSummary';
import { refreshApex } from '@salesforce/apex';

export default class SalesDashboard extends LightningElement {
    wiredSalesResult;
    salesData;
    error;

    @wire(getSalesSummary)
    wiredData(result) {
        this.wiredSalesResult = result;
        if (result.data) {
            this.salesData = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.salesData = undefined;
        }
    }

    get totalOrders() {
        return this.salesData ? this.salesData.totalOrders : 0;
    }

    get totalRevenue() {
        return this.salesData ? this.salesData.totalRevenue : 0;
    }

    get productSales() {
        return this.salesData ? this.salesData.productSales : [];
    }

    get hasProductSales() {
        return this.productSales.length > 0;
    }

    handleRefresh() {
        refreshApex(this.wiredSalesResult);
    }
}
