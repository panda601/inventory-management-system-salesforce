import { LightningElement, wire, track, api } from 'lwc';
import getSalesRevenueData from '@salesforce/apex/InventoryDashboardController.getSalesRevenueData';
import getSalesOrders from '@salesforce/apex/InventoryController.getSalesOrders';
import getSalesSummary from '@salesforce/apex/InventoryDashboardController.getSalesSummary';
import getReturnRequests from '@salesforce/apex/InventoryController.getReturnRequests';
import getRecentSalesOrders from '@salesforce/apex/InventoryController.getRecentSalesOrders';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import CHARTJS from '@salesforce/resourceUrl/chartjs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class SalesDashboard extends NavigationMixin(LightningElement) {
    @track isLoading = false;
    @track error;

    // Wired raw results
    wiredRevenueResult;
    wiredOrdersResult;
    wiredSalesSummaryResult;
    wiredReturnsResult;
    wiredRecentOrdersResult;

    // Chart.js state
    chartjsLoaded = false;

    // Chart instances
    revenueChartInstance;
    statusChartInstance;
    topProductsChartInstance;
    returnsChartInstance;

    // Lists
    revenueData = [];
    salesOrders = [];
    productSales = [];
    returnRequests = [];
    recentOrdersList = [];

    @wire(getSalesRevenueData)
    wiredRevenue(result) {
        this.wiredRevenueResult = result;
        if (result.data) {
            this.revenueData = result.data;
            this.checkDataAndInitialize();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getSalesOrders)
    wiredOrders(result) {
        this.wiredOrdersResult = result;
        if (result.data) {
            this.salesOrders = result.data;
            this.checkDataAndInitialize();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getSalesSummary)
    wiredSalesSummary(result) {
        this.wiredSalesSummaryResult = result;
        if (result.data) {
            this.productSales = result.data.productSales || [];
            this.checkDataAndInitialize();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getReturnRequests)
    wiredReturns(result) {
        this.wiredReturnsResult = result;
        if (result.data) {
            this.returnRequests = result.data;
            this.checkDataAndInitialize();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getRecentSalesOrders)
    wiredRecentOrders(result) {
        this.wiredRecentOrdersResult = result;
        if (result.data) {
            this.recentOrdersList = result.data;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    get recentOrders() {
        return this.recentOrdersList.map(ord => {
            const status = (ord.Status__c || '').toLowerCase();
            let badgeClass = 'status-badge ';
            if (status === 'draft') badgeClass += 'draft';
            else if (status === 'confirmed') badgeClass += 'confirmed';
            else if (status === 'delivered') badgeClass += 'delivered';
            else if (status === 'cancelled') badgeClass += 'cancelled';
            else badgeClass += 'draft';

            let formattedDate = '';
            if (ord.Order_Date__c) {
                try {
                    const dt = new Date(ord.Order_Date__c);
                    formattedDate = dt.toLocaleDateString();
                } catch (e) {
                    formattedDate = ord.Order_Date__c;
                }
            }

            return {
                ...ord,
                badgeClass,
                formattedDate
            };
        });
    }

    get hasRecentOrders() {
        return this.recentOrders.length > 0;
    }

    renderedCallback() {
        if (this.chartjsLoaded) {
            this.checkDataAndInitialize();
            return;
        }
        loadScript(this, CHARTJS)
            .then(() => {
                this.chartjsLoaded = true;
                this.checkDataAndInitialize();
            })
            .catch(err => {
                console.error('Error loading Chart.js inside salesDashboard', err);
            });
    }

    checkDataAndInitialize() {
        if (!this.chartjsLoaded) return;
        this.initializeCharts();
    }

    initializeCharts() {
        this.buildRevenueTrendChart();
        this.buildSalesOrderStatusChart();
        this.buildTopProductsRevenueChart();
        this.buildReturnsStatusChart();
    }

    buildRevenueTrendChart() {
        const canvas = this.template.querySelector('canvas.revenue-trend-chart');
        if (!canvas) return;

        if (this.revenueChartInstance) {
            this.revenueChartInstance.destroy();
        }

        const labels = this.revenueData.map(item => {
            try {
                const parts = item.date.split('-');
                if (parts.length === 3) {
                    return `${parts[1]}/${parts[2]}`; // MM/DD format
                }
            } catch (e) {}
            return item.date;
        });
        const data = this.revenueData.map(item => parseFloat(item.revenue) || 0);

        const ctx = canvas.getContext('2d');
        this.revenueChartInstance = new window.Chart(ctx, {
            type: 'line',
            data: {
                labels: labels.length ? labels : ['No Data'],
                datasets: [{
                    label: 'Revenue ($)',
                    data: data.length ? data : [0],
                    borderColor: '#10b981',
                    backgroundColor: 'rgba(16, 185, 129, 0.05)',
                    borderWidth: 2,
                    pointRadius: 2,
                    tension: 0.35,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                legend: {
                    display: false
                },
                scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero: true,
                            fontColor: '#64748b',
                            fontSize: 10,
                            callback: function (value) {
                                return '$' + value;
                            }
                        },
                        gridLines: {
                            color: '#f1f5f9'
                        }
                    }],
                    xAxes: [{
                        ticks: {
                            fontColor: '#64748b',
                            fontSize: 9,
                            maxRotation: 45,
                            minRotation: 0
                        },
                        gridLines: {
                            display: false
                        }
                    }]
                }
            }
        });
    }

    buildSalesOrderStatusChart() {
        const canvas = this.template.querySelector('canvas.so-status-chart');
        if (!canvas) return;

        if (this.statusChartInstance) {
            this.statusChartInstance.destroy();
        }

        const statusCounts = {};
        this.salesOrders.forEach(so => {
            const status = so.Status__c || 'Draft';
            statusCounts[status] = (statusCounts[status] || 0) + 1;
        });

        const labels = Object.keys(statusCounts);
        const data = Object.values(statusCounts);

        const ctx = canvas.getContext('2d');
        this.statusChartInstance = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels.length ? labels : ['No Data'],
                datasets: [{
                    data: data.length ? data : [0],
                    backgroundColor: '#8b5cf6',
                    borderColor: '#7c3aed',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                legend: {
                    display: false
                },
                scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero: true,
                            fontColor: '#64748b',
                            fontSize: 10,
                            precision: 0
                        },
                        gridLines: {
                            color: '#f1f5f9'
                        }
                    }],
                    xAxes: [{
                        ticks: {
                            fontColor: '#64748b',
                            fontSize: 10
                        },
                        gridLines: {
                            display: false
                        }
                    }]
                }
            }
        });
    }

    buildTopProductsRevenueChart() {
        const canvas = this.template.querySelector('canvas.top-products-revenue-chart');
        if (!canvas) return;

        if (this.topProductsChartInstance) {
            this.topProductsChartInstance.destroy();
        }

        const top5 = this.productSales.slice(0, 5);
        const labels = top5.map(p => p.productName);
        const data = top5.map(p => parseFloat(p.totalSales) || 0);

        const ctx = canvas.getContext('2d');
        this.topProductsChartInstance = new window.Chart(ctx, {
            type: 'horizontalBar',
            data: {
                labels: labels.length ? labels : ['No Data'],
                datasets: [{
                    data: data.length ? data : [0],
                    backgroundColor: '#06b6d4',
                    borderColor: '#0891b2',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                legend: {
                    display: false
                },
                scales: {
                    xAxes: [{
                        ticks: {
                            beginAtZero: true,
                            fontColor: '#64748b',
                            fontSize: 10,
                            callback: function (value) {
                                return '$' + value;
                            }
                        },
                        gridLines: {
                            color: '#f1f5f9'
                        }
                    }],
                    yAxes: [{
                        ticks: {
                            fontColor: '#64748b',
                            fontSize: 9
                        },
                        gridLines: {
                            display: false
                        }
                    }]
                }
            }
        });
    }

    buildReturnsStatusChart() {
        const canvas = this.template.querySelector('canvas.returns-status-chart');
        if (!canvas) return;

        if (this.returnsChartInstance) {
            this.returnsChartInstance.destroy();
        }

        const statusCounts = {};
        this.returnRequests.forEach(req => {
            const status = req.Status__c || 'Submitted';
            statusCounts[status] = (statusCounts[status] || 0) + 1;
        });

        const labels = Object.keys(statusCounts);
        const data = Object.values(statusCounts);

        const ctx = canvas.getContext('2d');
        this.returnsChartInstance = new window.Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels.length ? labels : ['No Data'],
                datasets: [{
                    data: data.length ? data : [0],
                    backgroundColor: ['#f59e0b', '#3b82f6', '#10b981', '#ef4444', '#6b7280'],
                    borderColor: '#ffffff',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                legend: {
                    position: 'bottom',
                    labels: {
                        boxWidth: 12,
                        fontColor: '#475569',
                        fontSize: 10
                    }
                },
                cutoutPercentage: 65
            }
        });
    }

    handleNavigateToRecord(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        const objectName = event.currentTarget.dataset.object;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectName,
                actionName: 'view'
            }
        });
    }

    @api
    refreshDashboard() {
        this.isLoading = true;
        const promises = [];
        if (this.wiredRevenueResult) promises.push(refreshApex(this.wiredRevenueResult));
        if (this.wiredOrdersResult) promises.push(refreshApex(this.wiredOrdersResult));
        if (this.wiredSalesSummaryResult) promises.push(refreshApex(this.wiredSalesSummaryResult));
        if (this.wiredReturnsResult) promises.push(refreshApex(this.wiredReturnsResult));
        if (this.wiredRecentOrdersResult) promises.push(refreshApex(this.wiredRecentOrdersResult));

        return Promise.all(promises)
            .finally(() => {
                this.isLoading = false;
                this.initializeCharts();
            });
    }
}