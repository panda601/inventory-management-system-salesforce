import { LightningElement, wire, track, api } from 'lwc';
import getInventorySummary from '@salesforce/apex/InventoryDashboardController.getInventorySummary';
import getPurchaseOrders from '@salesforce/apex/InventoryController.getPurchaseOrders';
import getInventoryTrendData from '@salesforce/apex/InventoryDashboardController.getInventoryTrendData';
import getSalesSummary from '@salesforce/apex/InventoryDashboardController.getSalesSummary';
import getInventoryHealthData from '@salesforce/apex/InventoryDashboardController.getInventoryHealthData';
import getForecastingData from '@salesforce/apex/InventoryDashboardController.getForecastingData';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import CHARTJS from '@salesforce/resourceUrl/chartjs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class InventoryDashboard extends NavigationMixin(LightningElement) {
    @track isLoading = false;
    @track error;

    // Wired raw results
    wiredSummaryResult;
    wiredPOsResult;
    wiredTrendResult;
    wiredSalesResult;
    wiredHealthResult;
    wiredForecastResult;

    // Loaded states
    chartjsLoaded = false;
    dataLoaded = false;

    // Chart instances
    healthChartInstance;
    poChartInstance;
    trendChartInstance;
    topProductsChartInstance;
    agingChartInstance;
    forecastChartInstance;

    // Summary data properties
    totalProducts = 0;
    lowStock = 0;
    outOfStock = 0;
    availableStock = 0;

    // Purchase orders and trend data lists
    purchaseOrders = [];
    trendData = [];
    topSellingProducts = [];
    healthData = {};
    forecastData = {};

    @wire(getInventorySummary)
    wiredSummary(result) {
        this.wiredSummaryResult = result;
        if (result.data) {
            const data = result.data;
            this.totalProducts = data.totalProducts || 0;
            this.lowStock = data.lowStock || 0;
            this.outOfStock = data.outOfStock || 0;
            this.availableStock = data.availableStock || 0;
            this.checkDataAndInitialize();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getPurchaseOrders)
    wiredPOs(result) {
        this.wiredPOsResult = result;
        if (result.data) {
            this.purchaseOrders = result.data;
            this.checkDataAndInitialize();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getInventoryTrendData)
    wiredTrend(result) {
        this.wiredTrendResult = result;
        if (result.data) {
            this.trendData = result.data;
            this.checkDataAndInitialize();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getSalesSummary)
    wiredSales(result) {
        this.wiredSalesResult = result;
        if (result.data) {
            this.topSellingProducts = result.data.productSales || [];
            this.checkDataAndInitialize();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getInventoryHealthData)
    wiredHealth(result) {
        this.wiredHealthResult = result;
        if (result.data) {
            this.healthData = result.data;
            this.checkDataAndInitialize();
        } else if (result.error) {
            console.error('Error loading inventory health data', result.error);
        }
    }

    @wire(getForecastingData)
    wiredForecast(result) {
        this.wiredForecastResult = result;
        if (result.data) {
            this.forecastData = result.data;
            this.checkDataAndInitialize();
        } else if (result.error) {
            console.error('Error loading forecasting data', result.error);
        }
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
                console.error('Error loading Chart.js inside inventoryDashboard', err);
            });
    }

    checkDataAndInitialize() {
        if (!this.chartjsLoaded) return;
        this.initializeCharts();
    }

    initializeCharts() {
        this.buildInventoryHealthChart();
        this.buildPurchaseOrderStatusChart();
        this.buildStockTrendChart();
        this.buildTopProductsChart();
        this.buildInventoryAgingChart();
        this.buildForecastChart();
    }

    buildInventoryHealthChart() {
        const canvas = this.template.querySelector('canvas.inventory-health-chart');
        if (!canvas) return;

        if (this.healthChartInstance) {
            this.healthChartInstance.destroy();
        }

        const healthy = Math.max(0, this.totalProducts - this.lowStock - this.outOfStock);
        const ctx = canvas.getContext('2d');

        this.healthChartInstance = new window.Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Healthy', 'Low Stock', 'Out of Stock'],
                datasets: [{
                    data: [healthy, this.lowStock, this.outOfStock],
                    backgroundColor: ['#10b981', '#fbbf24', '#ef4444'],
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

    buildPurchaseOrderStatusChart() {
        const canvas = this.template.querySelector('canvas.po-status-chart');
        if (!canvas) return;

        if (this.poChartInstance) {
            this.poChartInstance.destroy();
        }

        const statusCounts = {};
        this.purchaseOrders.forEach(po => {
            const status = po.Status__c || 'Draft';
            statusCounts[status] = (statusCounts[status] || 0) + 1;
        });

        const labels = Object.keys(statusCounts);
        const data = Object.values(statusCounts);

        const ctx = canvas.getContext('2d');
        this.poChartInstance = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels.length ? labels : ['No Data'],
                datasets: [{
                    label: 'Orders',
                    data: data.length ? data : [0],
                    backgroundColor: '#6366f1',
                    borderColor: '#4f46e5',
                    borderWidth: 1,
                    borderRadius: 4
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

    buildStockTrendChart() {
        const canvas = this.template.querySelector('canvas.stock-trend-chart');
        if (!canvas) return;

        if (this.trendChartInstance) {
            this.trendChartInstance.destroy();
        }

        const dateMap = {};
        this.trendData.forEach(item => {
            const dt = item.date;
            if (!dateMap[dt]) {
                dateMap[dt] = { inbound: 0, outbound: 0 };
            }
            if (item.type === 'Inbound') {
                dateMap[dt].inbound += parseFloat(item.quantity) || 0;
            } else if (item.type === 'Outbound') {
                dateMap[dt].outbound += parseFloat(item.quantity) || 0;
            }
        });

        const sortedDates = Object.keys(dateMap).sort();
        const inboundData = [];
        const outboundData = [];

        sortedDates.forEach(dt => {
            inboundData.push(dateMap[dt].inbound);
            outboundData.push(dateMap[dt].outbound);
        });

        // Format dates for display
        const displayLabels = sortedDates.map(dt => {
            try {
                const parts = dt.split('-');
                if (parts.length === 3) {
                    return `${parts[1]}/${parts[2]}`; // MM/DD format
                }
            } catch (e) {}
            return dt;
        });

        const ctx = canvas.getContext('2d');
        this.trendChartInstance = new window.Chart(ctx, {
            type: 'line',
            data: {
                labels: displayLabels.length ? displayLabels : ['No Data'],
                datasets: [
                    {
                        label: 'Inbound',
                        data: inboundData.length ? inboundData : [0],
                        borderColor: '#10b981',
                        backgroundColor: 'rgba(16, 185, 129, 0.05)',
                        borderWidth: 2,
                        pointRadius: 2,
                        tension: 0.35,
                        fill: true
                    },
                    {
                        label: 'Outbound',
                        data: outboundData.length ? outboundData : [0],
                        borderColor: '#ef4444',
                        backgroundColor: 'rgba(239, 68, 68, 0.05)',
                        borderWidth: 2,
                        pointRadius: 2,
                        tension: 0.35,
                        fill: true
                    }
                ]
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
                scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero: true,
                            fontColor: '#64748b',
                            fontSize: 10
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

    buildTopProductsChart() {
        const canvas = this.template.querySelector('canvas.top-selling-products-chart');
        if (!canvas) return;

        if (this.topProductsChartInstance) {
            this.topProductsChartInstance.destroy();
        }

        const top5 = this.topSellingProducts.slice(0, 5);
        const labels = top5.map(p => p.productName);
        const data = top5.map(p => p.quantitySold);

        const ctx = canvas.getContext('2d');
        this.topProductsChartInstance = new window.Chart(ctx, {
            type: 'horizontalBar',
            data: {
                labels: labels.length ? labels : ['No Data'],
                datasets: [{
                    data: data.length ? data : [0],
                    backgroundColor: '#3b82f6',
                    borderColor: '#2563eb',
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
                            precision: 0
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

    buildInventoryAgingChart() {
        const canvas = this.template.querySelector('canvas.inventory-aging-chart');
        if (!canvas) return;

        if (this.agingChartInstance) {
            this.agingChartInstance.destroy();
        }

        const agingData = this.healthData.agingBuckets || [0, 0, 0, 0];
        const ctx = canvas.getContext('2d');

        this.agingChartInstance = new window.Chart(ctx, {
            type: 'pie',
            data: {
                labels: ['0-30 Days', '30-60 Days', '60-90 Days', '90+ Days'],
                datasets: [{
                    data: agingData,
                    backgroundColor: ['#3b82f6', '#6366f1', '#a855f7', '#ec4899'],
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
                }
            }
        });
    }

    buildForecastChart() {
        const canvas = this.template.querySelector('canvas.stock-forecast-chart');
        if (!canvas) return;

        if (this.forecastChartInstance) {
            this.forecastChartInstance.destroy();
        }

        const months = this.forecastData.months || [];
        const demand = this.forecastData.demandForecast || [];
        const procurement = this.forecastData.procurementForecast || [];

        const ctx = canvas.getContext('2d');
        this.forecastChartInstance = new window.Chart(ctx, {
            type: 'line',
            data: {
                labels: months.length ? months : ['No Data'],
                datasets: [
                    {
                        label: 'Demand Forecast',
                        data: demand.length ? demand : [0],
                        borderColor: '#a855f7',
                        backgroundColor: 'rgba(168, 85, 247, 0.05)',
                        borderWidth: 2,
                        pointRadius: 2,
                        tension: 0.35,
                        fill: true
                    },
                    {
                        label: 'Procurement Need',
                        data: procurement.length ? procurement : [0],
                        borderColor: '#3b82f6',
                        backgroundColor: 'rgba(59, 130, 246, 0.05)',
                        borderWidth: 2,
                        pointRadius: 2,
                        tension: 0.35,
                        fill: true
                    }
                ]
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
                scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero: true,
                            fontColor: '#64748b',
                            fontSize: 10
                        },
                        gridLines: {
                            color: '#f1f5f9'
                        }
                    }],
                    xAxes: [{
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

    @api
    handleRefresh() {
        this.isLoading = true;
        const promises = [];
        if (this.wiredSummaryResult) promises.push(refreshApex(this.wiredSummaryResult));
        if (this.wiredPOsResult) promises.push(refreshApex(this.wiredPOsResult));
        if (this.wiredTrendResult) promises.push(refreshApex(this.wiredTrendResult));
        if (this.wiredSalesResult) promises.push(refreshApex(this.wiredSalesResult));
        if (this.wiredHealthResult) promises.push(refreshApex(this.wiredHealthResult));
        if (this.wiredForecastResult) promises.push(refreshApex(this.wiredForecastResult));

        return Promise.all(promises)
            .finally(() => {
                this.isLoading = false;
                this.initializeCharts();
            });
    }
}
