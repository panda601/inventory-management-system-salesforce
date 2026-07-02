import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMonitorData from '@salesforce/apex/InventoryController.getMonitorData';
import getPurchaseOrders from '@salesforce/apex/InventoryController.getPurchaseOrders';
import getRecentSalesOrders from '@salesforce/apex/InventoryController.getRecentSalesOrders';
import getReturnRequests from '@salesforce/apex/InventoryController.getReturnRequests';
import { refreshApex } from '@salesforce/apex';

export default class SmartNotificationCenter extends NavigationMixin(LightningElement) {
    @track monitorData = [];
    @track purchaseOrders = [];
    @track salesOrders = [];
    @track returnRequests = [];
    @track activeFilter = 'All';
    @track readNotificationIds = [];
    @track isLoading = false;
    error;

    wiredMonitorResult;
    wiredPOsResult;
    wiredSOsResult;
    wiredReturnsResult;

    @wire(getMonitorData)
    wiredMonitor(result) {
        this.wiredMonitorResult = result;
        if (result.data) {
            this.monitorData = result.data;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getPurchaseOrders)
    wiredPOs(result) {
        this.wiredPOsResult = result;
        if (result.data) {
            this.purchaseOrders = result.data;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getRecentSalesOrders)
    wiredSOs(result) {
        this.wiredSOsResult = result;
        if (result.data) {
            this.salesOrders = result.data;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getReturnRequests)
    wiredReturnRequests(result) {
        this.wiredReturnsResult = result;
        if (result.data) {
            this.returnRequests = result.data;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    // Low Stock Alerts (Stock between 1 and Minimum stock limit)
    get lowStockAlerts() {
        return this.monitorData
            .filter(p => p.Current_Stock__c > 0 && p.Current_Stock__c <= p.Minimum_Stock__c)
            .map(p => ({
                id: 'low-' + p.Id,
                recordId: p.Id,
                title: `${p.Product_Name__c} is running low on stock`,
                sku: p.SKU__c,
                stock: p.Current_Stock__c,
                minStock: p.Minimum_Stock__c,
                category: 'Stock',
                badgeClass: 'badge-warning',
                isUnread: !this.readNotificationIds.includes('low-' + p.Id),
                rowClass: this.readNotificationIds.includes('low-' + p.Id) ? 'notification-item-row read' : 'notification-item-row unread',
                iconName: 'utility:warning',
                iconVariant: 'warning',
                objectApiName: 'Product__c'
            }));
    }

    // Out of Stock Products (Stock is exactly 0)
    get outOfStockProducts() {
        return this.monitorData
            .filter(p => p.Current_Stock__c === 0)
            .map(p => ({
                id: 'out-' + p.Id,
                recordId: p.Id,
                title: `${p.Product_Name__c} is completely out of stock`,
                sku: p.SKU__c,
                category: 'Stock',
                badgeClass: 'badge-error',
                isUnread: !this.readNotificationIds.includes('out-' + p.Id),
                rowClass: this.readNotificationIds.includes('out-' + p.Id) ? 'notification-item-row read' : 'notification-item-row unread',
                iconName: 'utility:ban',
                iconVariant: 'error',
                objectApiName: 'Product__c'
            }));
    }

    // Pending Purchase Orders (Draft or Approved)
    get pendingPOs() {
        return this.purchaseOrders
            .filter(po => po.Status__c === 'Draft' || po.Status__c === 'Approved')
            .map(po => ({
                id: 'po-' + po.Id,
                recordId: po.Id,
                title: `Purchase Order ${po.Name} is pending (${po.Status__c})`,
                category: 'Orders',
                badgeClass: 'badge-info',
                isUnread: !this.readNotificationIds.includes('po-' + po.Id),
                rowClass: this.readNotificationIds.includes('po-' + po.Id) ? 'notification-item-row read' : 'notification-item-row unread',
                iconName: 'utility:description',
                iconVariant: 'info',
                objectApiName: 'Purchase_Order__c'
            }));
    }

    // Pending Sales Orders (Draft or Confirmed)
    get pendingSOs() {
        return this.salesOrders
            .filter(so => so.Status__c === 'Draft' || so.Status__c === 'Confirmed')
            .map(so => ({
                id: 'so-' + so.Id,
                recordId: so.Id,
                title: `Sales Order ${so.Name} is pending (${so.Status__c})`,
                category: 'Orders',
                badgeClass: 'badge-info',
                isUnread: !this.readNotificationIds.includes('so-' + so.Id),
                rowClass: this.readNotificationIds.includes('so-' + so.Id) ? 'notification-item-row read' : 'notification-item-row unread',
                iconName: 'utility:description',
                iconVariant: 'info',
                objectApiName: 'Sales_Order__c'
            }));
    }

    get returnRequestAlerts() {
        if (!this.returnRequests) return [];
        return this.returnRequests
            .filter(req => req.Status__c === 'Submitted' || req.Status__c === 'Approved' || req.Status__c === 'Rejected' || req.Status__c === 'Closed')
            .map(req => {
                let title = '';
                if (req.Status__c === 'Submitted') {
                    title = `New Return Request submitted: ${req.Name}`;
                } else if (req.Status__c === 'Approved') {
                    title = `Return Request approved: ${req.Name}`;
                } else {
                    title = `Return Request status updated: ${req.Name} (${req.Status__c})`;
                }
                return {
                    id: 'ret-' + req.Id,
                    recordId: req.Id,
                    title: title,
                    category: 'Returns',
                    badgeClass: 'badge-success',
                    isUnread: !this.readNotificationIds.includes('ret-' + req.Id),
                    rowClass: this.readNotificationIds.includes('ret-' + req.Id) ? 'notification-item-row read' : 'notification-item-row unread',
                    iconName: 'utility:feed',
                    iconVariant: 'success',
                    objectApiName: 'Return_Request__c'
                };
            });
    }

    get allNotifications() {
        return [
            ...this.lowStockAlerts,
            ...this.outOfStockProducts,
            ...this.pendingPOs,
            ...this.pendingSOs,
            ...this.returnRequestAlerts
        ];
    }

    get filteredNotifications() {
        if (this.activeFilter === 'All') {
            return this.allNotifications;
        }
        if (this.activeFilter === 'Unread') {
            return this.allNotifications.filter(n => n.isUnread);
        }
        return this.allNotifications.filter(n => n.category === this.activeFilter);
    }

    get hasNotifications() {
        return this.filteredNotifications && this.filteredNotifications.length > 0;
    }

    get unreadCount() {
        return this.allNotifications.filter(n => n.isUnread).length;
    }

    get allBtnClass() { return this.getBtnClass('All'); }
    get unreadBtnClass() { return this.getBtnClass('Unread'); }
    get stockBtnClass() { return this.getBtnClass('Stock'); }
    get ordersBtnClass() { return this.getBtnClass('Orders'); }
    get returnsBtnClass() { return this.getBtnClass('Returns'); }

    getBtnClass(filter) {
        return this.activeFilter === filter 
            ? 'slds-button slds-button_brand rounded-btn filter-btn' 
            : 'slds-button slds-button_neutral rounded-btn filter-btn';
    }

    handleFilterSelect(event) {
        this.activeFilter = event.currentTarget.dataset.filter;
    }

    handleMarkAsRead(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        if (!this.readNotificationIds.includes(id)) {
            this.readNotificationIds = [...this.readNotificationIds, id];
        }
    }

    handleMarkAllAsRead() {
        const unreadIds = this.allNotifications.filter(n => n.isUnread).map(n => n.id);
        this.readNotificationIds = [...this.readNotificationIds, ...unreadIds];
    }

    handleNotificationClick(event) {
        const id = event.currentTarget.dataset.id;
        const recordId = event.currentTarget.dataset.recordid;
        const objectApiName = event.currentTarget.dataset.object;
        
        // Mark as read automatically when clicked
        if (!this.readNotificationIds.includes(id)) {
            this.readNotificationIds = [...this.readNotificationIds, id];
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            }
        });
    }

    @api
    handleRefresh() {
        this.isLoading = true;
        const promises = [];
        if (this.wiredMonitorResult) promises.push(refreshApex(this.wiredMonitorResult));
        if (this.wiredPOsResult) promises.push(refreshApex(this.wiredPOsResult));
        if (this.wiredSOsResult) promises.push(refreshApex(this.wiredSOsResult));
        if (this.wiredReturnsResult) promises.push(refreshApex(this.wiredReturnsResult));

        return Promise.all(promises)
            .finally(() => {
                this.isLoading = false;
            });
    }

    navigateToTransactions() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Inventory_Transaction__c',
                actionName: 'list'
            }
        });
    }
}