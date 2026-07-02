import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import CHARTJS from '@salesforce/resourceUrl/chartjs';
import getUserRole from '@salesforce/apex/InventoryController.getUserRole';
import getAdminDashboardSummary from '@salesforce/apex/InventoryDashboardController.getAdminDashboardSummary';
import getMonthlyPnLData from '@salesforce/apex/InventoryDashboardController.getMonthlyPnLData';
import getMonitorData from '@salesforce/apex/InventoryController.getMonitorData';
import getPurchaseOrders from '@salesforce/apex/InventoryController.getPurchaseOrders';
import getRecentSalesOrders from '@salesforce/apex/InventoryController.getRecentSalesOrders';
import getRecentTransactions from '@salesforce/apex/InventoryController.getRecentTransactions';
import getReturnRequests from '@salesforce/apex/InventoryController.getReturnRequests';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';

export default class InventoryCommandCenter extends NavigationMixin(LightningElement) {
  defaultSummaryData = {
    totalProducts: 0,
    availableInventory: 0,
    lowStock: 0,
    pendingPurchaseOrders: 0,
    pendingSalesOrders: 0,
    pendingReturns: 0,
    underReviewReturns: 0,
    replacementSentReturns: 0,
    rejectedReturns: 0,
    refundedReturns: 0,
    outOfStock: 0,
    revenue: 0,
    procurementCost: 0,
    profit: 0,
    profitMargin: 0
  };

  @track userRole = 'Sales';
  @track summaryData = { ...this.defaultSummaryData };
  @track isNotificationModalOpen = false;
  @track selectedProductId = '';
  @track selectedAdminProductId = '';
  @track activeAdminTab = 'dashboard';
  @track activeManagerTab = 'dashboard';
  @track activeSalesTab = 'dashboard';
  @track monthlyPnLData = [];

  @track monitorData = [];
  @track purchaseOrders = [];
  @track salesOrders = [];
  @track transactions = [];
  @track returnRequests = [];
  @track dismissedIds = [];

  // Quick action modal tracked states
  @track isSalesOrderModalOpen = false;
  @track isSalesOrderItemModalOpen = false;
  @track isReturnRequestModalOpen = false;

  chartjsLoaded = false;
  pendingChartInitialization = false;
  monthlyRevenueChart;
  monthlyCostChart;
  profitLossChart;

  // Wired results storage for refreshApex
  wiredSummaryResult;
  wiredMonthlyPnLResult;
  wiredMonitorResult;
  wiredPOsResult;
  wiredSOsResult;
  wiredTxnsResult;
  wiredReturnRequestsResult;
  monitorLoaded = false;
  purchaseOrdersLoaded = false;
  transactionsLoaded = false;

  @wire(getAdminDashboardSummary)
  wiredSummary(result) {
    this.wiredSummaryResult = result;
    const { data, error } = result;
    if (data) {
      this.summaryData = { ...this.defaultSummaryData, ...data };
      this.initializeCharts();
    } else if (error) {
      this.summaryData = { ...this.defaultSummaryData };
      // Keep the admin page alive even if the wire fails.
      console.error('Error loading admin dashboard summary', error);
    }
  }

  @wire(getMonthlyPnLData)
  wiredMonthlyPnL(result) {
    this.wiredMonthlyPnLResult = result;
    const { data } = result;
    if (data) {
      this.monthlyPnLData = data;
      this.initializeCharts();
    }
  }

  @wire(getMonitorData)
  wiredMonitor(result) {
    this.wiredMonitorResult = result;
    const { data, error } = result;
    if (data || error) this.monitorLoaded = true;
    if (data) this.monitorData = data;
  }

  @wire(getPurchaseOrders)
  wiredPOs(result) {
    this.wiredPOsResult = result;
    const { data, error } = result;
    if (data || error) this.purchaseOrdersLoaded = true;
    if (data) this.purchaseOrders = data;
  }

  @wire(getRecentSalesOrders)
  wiredSOs(result) {
    this.wiredSOsResult = result;
    const { data } = result;
    if (data) this.salesOrders = data;
  }

  @wire(getRecentTransactions)
  wiredTxns(result) {
    this.wiredTxnsResult = result;
    const { data, error } = result;
    if (data || error) this.transactionsLoaded = true;
    if (data) this.transactions = data;
  }

  @wire(getReturnRequests)
  wiredReturnRequests(result) {
    this.wiredReturnRequestsResult = result;
    const { data } = result;
    if (data) this.returnRequests = data;
  }

  // Dynamic Notifications Calculations
  get lowStockAlerts() {
    if (!this.isManagerOrAdmin) return [];
    return this.monitorData
      .filter(
        (p) => p.Current_Stock__c > 0 && p.Current_Stock__c <= p.Minimum_Stock__c && !this.dismissedIds.includes(p.Id)
      )
      .map((p) => ({
        id: p.Id,
        title: `${p.Product_Name__c} is running low on stock`,
        stock: p.Current_Stock__c,
        minStock: p.Minimum_Stock__c
      }));
  }

  get outOfStockProducts() {
    if (!this.isManagerOrAdmin) return [];
    return this.monitorData
      .filter((p) => p.Current_Stock__c === 0 && !this.dismissedIds.includes(p.Id))
      .map((p) => ({
        id: p.Id,
        title: `${p.Product_Name__c} is completely out of stock`
      }));
  }

  get pendingPOs() {
    if (!this.isManagerOrAdmin) return [];
    return this.purchaseOrders
      .filter((po) => (po.Status__c === 'Draft' || po.Status__c === 'Approved') && !this.dismissedIds.includes(po.Id))
      .map((po) => ({
        id: po.Id,
        title: `Purchase Order ${po.Name}`,
        status: po.Status__c,
        supplier: po.Supplier__r ? po.Supplier__r.Supplier_Name__c || po.Supplier__r.Name : 'N/A'
      }));
  }

  get pendingSOs() {
    if (!this.isManagerOrAdmin) return [];
    return this.salesOrders
      .filter((so) => (so.Status__c === 'Draft' || so.Status__c === 'Confirmed') && !this.dismissedIds.includes(so.Id))
      .map((so) => ({
        id: so.Id,
        title: `Sales Order ${so.Name}`,
        customer: so.Customer_Name__c
      }));
  }

  get recentActivities() {
    if (!this.isManagerOrAdmin) return [];
    return this.transactions
      .filter((t) => !this.dismissedIds.includes(t.Id))
      .map((t) => ({
        id: t.Id,
        title: `Transaction ${t.Name}: ${t.Transaction_Type__c} of ${t.Quantity__c} units for ${t.Product__r ? t.Product__r.Product_Name__c : 'Product'}`
      }));
  }

  get returnRequestAlerts() {
    if (!this.returnRequests || this.returnRequests.length === 0) {
      return [];
    }
    if (this.isManagerOnly) {
      return this.returnRequests
        .filter((req) => req.Status__c === 'Submitted' && !this.dismissedIds.includes(req.Id))
        .map((req) => ({
          id: req.Id,
          title: `New Return Request ${req.Name} is pending inventory manager review`
        }));
    }

    if (this.isAdmin) {
      return this.returnRequests
        .filter((req) => req.Status__c === 'Under Review' && !this.dismissedIds.includes(req.Id))
        .map((req) => {
          let title = `Return ${req.Name} is waiting for final approval`;
          if (req.Resolution_Type__c === 'Replacement') {
            title = `Replacement Request ${req.Name} is waiting for final approval`;
          } else if (req.Resolution_Type__c === 'Refund') {
            title = `Refund Request ${req.Name} is waiting for final approval`;
          }

          return {
            id: req.Id,
            title
          };
        });
    }

    if (this.isSalesExec) {
      return this.returnRequests
        .filter((req) => !this.dismissedIds.includes(req.Id))
        .filter((req) =>
          ['Submitted', 'Approved', 'Rejected', 'Replacement Sent', 'Refunded'].includes(req.Status__c)
        )
        .map((req) => {
          let title = `Return Submitted: Request ${req.Name} has been submitted`;
          if (req.Status__c === 'Approved') {
            title = `Return Approved: Request ${req.Name} has been approved`;
          } else if (req.Status__c === 'Rejected') {
            title = `Return Rejected: Request ${req.Name} has been rejected`;
          } else if (req.Status__c === 'Replacement Sent') {
            title = `Replacement Sent: Request ${req.Name} has been fulfilled`;
          } else if (req.Status__c === 'Refunded') {
            title = `Refund Completed: Request ${req.Name} has been refunded`;
          }

          return {
            id: req.Id,
            title
          };
        });
    }
    return [];
  }

  get notificationCount() {
    if (this.isAdmin) {
      return (
        this.lowStockAlerts.length +
        this.outOfStockProducts.length +
        this.pendingPOs.length +
        this.pendingSOs.length +
        this.recentActivities.length +
        this.returnRequestAlerts.length
      );
    }

    if (this.isManagerOnly) {
      return (
        this.lowStockAlerts.length +
        this.outOfStockProducts.length +
        this.pendingPOs.length +
        this.recentActivities.length +
        this.returnRequestAlerts.length
      );
    }

    return this.returnRequestAlerts.length;
  }

  get hasNotifications() {
    return this.notificationCount > 0;
  }

  get managerWorkspaceReady() {
    return this.monitorLoaded && this.purchaseOrdersLoaded && this.transactionsLoaded;
  }

  get showReturnNotificationSection() {
    return true;
  }

  get showPendingSalesNotifications() {
    return this.isAdmin;
  }

  get managerNotificationCards() {
    return [
      {
        key: 'lowStock',
        label: 'Low Stock Alerts',
        value: this.lowStockAlerts.length,
        icon: 'utility:warning',
        toneClass: 'manager-alert-card manager-alert-card_warning'
      },
      {
        key: 'pendingPOs',
        label: 'Pending Purchase Orders',
        value: this.pendingPOs.length,
        icon: 'standard:drafts',
        toneClass: 'manager-alert-card manager-alert-card_info'
      },
      {
        key: 'outOfStock',
        label: 'Out Of Stock Products',
        value: this.outOfStockProducts.length,
        icon: 'utility:ban',
        toneClass: 'manager-alert-card manager-alert-card_error'
      },
      {
        key: 'recentActivities',
        label: 'Recent Activities',
        value: this.recentActivities.length,
        icon: 'utility:feed',
        toneClass: 'manager-alert-card manager-alert-card_neutral'
      }
    ];
  }

  connectedCallback() {
    getUserRole()
      .then((result) => {
        this.userRole = result;
      })
      .catch(() => {
        this.userRole = 'Sales';
      });
    this.subscribeToCDCEvents();
  }

  renderedCallback() {
    if (this.chartjsLoaded) {
      if (this.pendingChartInitialization || this.activeAdminTab === 'dashboard') {
        this.pendingChartInitialization = false;
        this.initializeCharts();
      }
      return;
    }
    loadScript(this, CHARTJS)
      .then(() => {
        this.chartjsLoaded = true;
        this.initializeCharts();
      })
      .catch((error) => {
        console.error('Error loading Chart.js', error);
      });
  }

  handleTabSelect(event) {
    const selectedTab = event.target.value;
    this.activeAdminTab = selectedTab;
    if (selectedTab === 'dashboard') {
      this.pendingChartInitialization = true;
      this.initializeCharts();
    }
  }

  handleManagerTabSelect(event) {
    this.activeManagerTab = event.target.value;
  }

  initializeCharts() {
    if (!this.chartjsLoaded || !this.isAdmin) {
      return;
    }

    const revenueCanvas = this.template.querySelector('canvas.monthly-revenue-chart');
    const costCanvas = this.template.querySelector('canvas.monthly-cost-chart');
    const profitCanvas = this.template.querySelector('canvas.profit-loss-chart');

    if (!revenueCanvas || !costCanvas || !profitCanvas) {
      return;
    }

    this.initMonthlyRevenueChart(revenueCanvas);
    this.initMonthlyCostChart(costCanvas);
    this.initProfitLossChart(profitCanvas);
  }

  get pnlLabels() {
    if (this.monthlyPnLData.length) {
      return this.monthlyPnLData.map((item) => item.label);
    }

    return ['Jan 2026', 'Feb 2026', 'Mar 2026', 'Apr 2026', 'May 2026', 'Jun 2026'];
  }

  get monthlyRevenueValues() {
    if (this.monthlyPnLData.length) {
      return this.monthlyPnLData.map((item) => item.revenue || 0);
    }

    return [12000, 14000, 12500, 16000, 18100, 17450];
  }

  get monthlyCostValues() {
    if (this.monthlyPnLData.length) {
      return this.monthlyPnLData.map((item) => item.procurementCost || 0);
    }

    return [8000, 9200, 8700, 10300, 11400, 10850];
  }

  get monthlyProfitValues() {
    if (this.monthlyPnLData.length) {
      return this.monthlyPnLData.map((item) => item.profit || 0);
    }

    return [4000, 4800, 3800, 5700, 6700, 6600];
  }

  initMonthlyRevenueChart(canvas) {
    if (this.monthlyRevenueChart) {
      this.monthlyRevenueChart.destroy();
    }

    const ctx = canvas.getContext('2d');
    this.monthlyRevenueChart = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.pnlLabels,
        datasets: [
          {
            label: 'Revenue ($)',
            data: this.monthlyRevenueValues,
            backgroundColor: '#0f766e',
            borderColor: '#115e59',
            borderWidth: 1,
            borderRadius: 10
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        legend: {
          display: false
        },
        scales: {
          yAxes: [
            {
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
            }
          ],
          xAxes: [
            {
              ticks: {
                fontColor: '#64748b',
                fontSize: 10
              },
              gridLines: {
                display: false
              }
            }
          ]
        }
      }
    });
  }

  initMonthlyCostChart(canvas) {
    if (this.monthlyCostChart) {
      this.monthlyCostChart.destroy();
    }

    const ctx = canvas.getContext('2d');
    this.monthlyCostChart = new window.Chart(ctx, {
      type: 'line',
      data: {
        labels: this.pnlLabels,
        datasets: [
          {
            label: 'Procurement Cost ($)',
            data: this.monthlyCostValues,
            backgroundColor: 'rgba(180, 83, 9, 0.14)',
            borderColor: '#b45309',
            borderWidth: 3,
            fill: true,
            pointRadius: 3,
            tension: 0.35
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        legend: {
          display: false
        },
        scales: {
          yAxes: [
            {
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
            }
          ],
          xAxes: [
            {
              ticks: {
                fontColor: '#64748b',
                fontSize: 10
              },
              gridLines: {
                display: false
              }
            }
          ]
        }
      }
    });
  }

  initProfitLossChart(canvas) {
    if (this.profitLossChart) {
      this.profitLossChart.destroy();
    }

    const ctx = canvas.getContext('2d');
    this.profitLossChart = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.pnlLabels,
        datasets: [
          {
            label: 'Profit',
            data: this.monthlyProfitValues.map((value) => (value > 0 ? value : 0)),
            backgroundColor: '#15803d',
            borderRadius: 10
          },
          {
            label: 'Loss',
            data: this.monthlyProfitValues.map((value) => (value < 0 ? Math.abs(value) : 0)),
            backgroundColor: '#dc2626',
            borderRadius: 10
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        legend: {
          position: 'top',
          labels: {
            boxWidth: 12,
            fontColor: '#475569',
            fontSize: 10
          }
        },
        scales: {
          yAxes: [
            {
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
            }
          ],
          xAxes: [
            {
              ticks: {
                fontColor: '#64748b',
                fontSize: 10
              },
              gridLines: {
                display: false
              }
            }
          ]
        }
      }
    });
  }

  get isAdmin() {
    return this.userRole === 'Admin';
  }

  get isManagerOnly() {
    return this.userRole === 'Manager';
  }

  get isSalesExec() {
    return this.userRole === 'Sales';
  }

  get isManagerOrAdmin() {
    return this.userRole === 'Admin' || this.userRole === 'Manager';
  }

  // Modal control
  handleOpenNotificationModal() {
    this.isNotificationModalOpen = true;
  }

  handleCloseNotificationModal() {
    this.isNotificationModalOpen = false;
  }

  // Global Search placeholder (can be expanded later if desired)
  handleGlobalSearch() {
    // No-op for now
  }

  // Settings actions handler
  handleOpenSettings() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Settings',
        message: 'Settings configurations are managed in Setup.',
        variant: 'info'
      })
    );
  }

  // Quick action dropdown handler
  handleQuickActionSelect(event) {
    const action = event.detail.value;
    if (action === 'create_so_modal') {
      this.openCreateSalesOrderModal();
      return;
    }
    if (action === 'create_so_item_modal') {
      this.openCreateSalesOrderItemModal();
      return;
    }
    if (action === 'create_return_modal') {
      this.openCreateReturnRequestModal();
      return;
    }

    let objectApiName;
    if (action === 'create_product') objectApiName = 'Product__c';
    else if (action === 'create_supplier') objectApiName = 'Supplier__c';
    else if (action === 'create_po') objectApiName = 'Purchase_Order__c';
    else if (action === 'create_so') objectApiName = 'Sales_Order__c';

    if (objectApiName) {
      this[NavigationMixin.Navigate]({
        type: 'standard__objectPage',
        attributes: {
          objectApiName: objectApiName,
          actionName: 'new'
        }
      });
    }
  }

  // Modal record opening handler
  handleOpenRecord(event) {
    const recordId = event.currentTarget.dataset.id;
    const objectType = event.currentTarget.dataset.type;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: recordId,
        objectApiName: objectType,
        actionName: 'view'
      }
    });
    this.isNotificationModalOpen = false;
  }

  // Modal record dismissal handler
  handleDismissNotification(event) {
    const id = event.currentTarget.dataset.id;
    this.dismissedIds = [...this.dismissedIds, id];
  }

  // Sales Executive detail view navigation
  handleProductSelect(event) {
    this.selectedProductId = event.detail;
  }

  handleAdminProductSelect(event) {
    this.selectedAdminProductId = event.detail;
  }

  openAdminProductsTab() {
    this.activeAdminTab = 'products';
  }

  openAdminReturnsTab() {
    this.activeAdminTab = 'returns';
  }

  openAdminPurchaseOrdersTab() {
    this.activeAdminTab = 'purchase_orders';
  }

  handleBackToCatalog() {
    this.selectedProductId = '';
  }

  handleSalesTabSelect(event) {
    this.activeSalesTab = event.target.value;
    if (this.activeSalesTab !== 'catalog') {
      this.selectedProductId = '';
    }
  }

  handleOpenSalesCatalog(event) {
    const prodId = event.detail;
    this.activeSalesTab = 'catalog';
    if (prodId) {
      this.selectedProductId = prodId;
    }
  }

  handleNavigateToSalesReturnsTab() {
    this.activeSalesTab = 'returns';
  }

  handleNavigateToReturnsTab() {
    this.activeManagerTab = 'returns';
  }

  get pendingReturnRequests() {
    return this.returnRequests
      .filter((req) => req.Status__c === 'Submitted' || req.Status__c === 'Under Review')
      .map((req) => {
        let badgeClass = 'slds-badge ';
        if (req.Status__c === 'Submitted') badgeClass += 'slds-theme_warning';
        else if (req.Status__c === 'Under Review') badgeClass += 'slds-theme_info';
        else badgeClass += 'slds-theme_light';
        return {
          ...req,
          badgeClass
        };
      });
  }

  get pendingReturnCount() {
    return this.pendingReturnRequests.length;
  }

  get hasPendingReturns() {
    return this.pendingReturnRequests.length > 0;
  }

  // CDC Subscriptions
  subscriptionProduct;
  subscriptionReturnRequest;
  subscriptionInventoryTxn;
  subscriptionSalesOrder;
  subscriptionPurchaseOrder;

  subscribeToCDCEvents() {
    const self = this;
    const callback = function (response) {
      console.log('CDC Event received: ', JSON.stringify(response));
      self.refreshAllData();
    };

    subscribe('/data/Product__ChangeEvent', -1, callback).then((response) => {
      console.log('Subscribed to Product Change Events');
      self.subscriptionProduct = response;
    });

    subscribe('/data/Return_Request__ChangeEvent', -1, callback).then((response) => {
      console.log('Subscribed to Return_Request Change Events');
      self.subscriptionReturnRequest = response;
    });

    subscribe('/data/Inventory_Transaction__ChangeEvent', -1, callback).then((response) => {
      console.log('Subscribed to Inventory_Transaction Change Events');
      self.subscriptionInventoryTxn = response;
    });

    subscribe('/data/Sales_Order__ChangeEvent', -1, callback).then((response) => {
      console.log('Subscribed to Sales_Order Change Events');
      self.subscriptionSalesOrder = response;
    });

    subscribe('/data/Purchase_Order__ChangeEvent', -1, callback).then((response) => {
      console.log('Subscribed to Purchase_Order Change Events');
      self.subscriptionPurchaseOrder = response;
    });

    onError((error) => {
      console.error('empApi error: ', JSON.stringify(error));
    });
  }

  disconnectedCallback() {
    if (this.subscriptionProduct) unsubscribe(this.subscriptionProduct);
    if (this.subscriptionReturnRequest) unsubscribe(this.subscriptionReturnRequest);
    if (this.subscriptionInventoryTxn) unsubscribe(this.subscriptionInventoryTxn);
    if (this.subscriptionSalesOrder) unsubscribe(this.subscriptionSalesOrder);
    if (this.subscriptionPurchaseOrder) unsubscribe(this.subscriptionPurchaseOrder);
  }

  // Centralized data refresh
  refreshAllData() {
    const promises = [];
    if (this.wiredSummaryResult) promises.push(refreshApex(this.wiredSummaryResult));
    if (this.wiredMonitorResult) promises.push(refreshApex(this.wiredMonitorResult));
    if (this.wiredPOsResult) promises.push(refreshApex(this.wiredPOsResult));
    if (this.wiredSOsResult) promises.push(refreshApex(this.wiredSOsResult));
    if (this.wiredTxnsResult) promises.push(refreshApex(this.wiredTxnsResult));
    if (this.wiredReturnRequestsResult) promises.push(refreshApex(this.wiredReturnRequestsResult));
    if (this.wiredMonthlyPnLResult) promises.push(refreshApex(this.wiredMonthlyPnLResult));

    // Call child components refresh methods
    const salesOrderList = this.template.querySelector('c-inventory-sales-order-list');
    if (salesOrderList && typeof salesOrderList.refreshList === 'function') {
      salesOrderList.refreshList();
    }

    const productCatalog = this.template.querySelector('c-product-catalog');
    if (productCatalog && typeof productCatalog.refreshCatalog === 'function') {
      productCatalog.refreshCatalog();
    }

    const productDetail = this.template.querySelector('c-product-detail');
    if (productDetail && typeof productDetail.refreshDetail === 'function') {
      productDetail.refreshDetail();
    }

    const returnMgmt = this.template.querySelector('c-return-management-dashboard');
    if (returnMgmt && typeof returnMgmt.refreshDashboard === 'function') {
      returnMgmt.refreshDashboard();
    }

    const recentOrders = this.template.querySelector('c-recent-orders-widget');
    if (recentOrders && typeof recentOrders.refreshWidget === 'function') {
      recentOrders.refreshWidget();
    }

    const salesDashboard = this.template.querySelector('c-sales-dashboard');
    if (salesDashboard) {
      if (typeof salesDashboard.refreshDashboard === 'function') {
        salesDashboard.refreshDashboard();
      }
      if (typeof salesDashboard.refreshReturnRequests === 'function') {
        salesDashboard.refreshReturnRequests();
      }
    }

    const invDashboard = this.template.querySelector('c-inventory-dashboard');
    if (invDashboard && typeof invDashboard.handleRefresh === 'function') {
      invDashboard.handleRefresh();
    }

    const invMonitor = this.template.querySelector('c-inventory-monitor');
    if (invMonitor && typeof invMonitor.refreshAll === 'function') {
      invMonitor.refreshAll();
    }

    const poDashboard = this.template.querySelector('c-purchase-order-dashboard');
    if (poDashboard && typeof poDashboard.handleRefresh === 'function') {
      poDashboard.handleRefresh();
    }

    const topProducts = this.template.querySelector('c-top-selling-products');
    if (topProducts && typeof topProducts.refreshLeaderboard === 'function') {
      topProducts.refreshLeaderboard();
    }

    const approvalCenter = this.template.querySelector('c-approval-center');
    if (approvalCenter && typeof approvalCenter.handleRefresh === 'function') {
      approvalCenter.handleRefresh();
    }

    return Promise.all(promises);
  }

  // Modal Action Handlers
  openCreateSalesOrderModal() {
    this.isSalesOrderModalOpen = true;
  }

  closeSalesOrderModal() {
    this.isSalesOrderModalOpen = false;
  }

  handleSalesOrderCreateSuccess() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: 'Sales Order created successfully.',
        variant: 'success'
      })
    );
    this.closeSalesOrderModal();
    this.refreshAllData();
  }

  openCreateSalesOrderItemModal() {
    this.isSalesOrderItemModalOpen = true;
  }

  closeSalesOrderItemModal() {
    this.isSalesOrderItemModalOpen = false;
  }

  handleSalesOrderItemCreateSuccess() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: 'Sales Order Item created successfully.',
        variant: 'success'
      })
    );
    this.closeSalesOrderItemModal();
    this.refreshAllData();
  }

  openCreateReturnRequestModal() {
    this.isReturnRequestModalOpen = true;
  }

  closeReturnRequestModal() {
    this.isReturnRequestModalOpen = false;
  }

  handleReturnRequestCreateSuccess() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: 'Return Request created successfully and submitted for approval.',
        variant: 'success'
      })
    );
    this.closeReturnRequestModal();
    this.refreshAllData();
  }

  handleModalError(event) {
    const errMsg = event.detail.message || (event.detail.detail ? event.detail.detail : 'Unknown error occurred.');
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error Creating Record',
        message: errMsg,
        variant: 'error'
      })
    );
  }
}