import { LightningElement, wire, track } from 'lwc';
import getRecentTransactions from '@salesforce/apex/InventoryController.getRecentTransactions';
import getPurchaseOrders from '@salesforce/apex/InventoryController.getPurchaseOrders';
import getMonitorData from '@salesforce/apex/InventoryController.getMonitorData';

export default class InventoryActivityTimeline extends LightningElement {
    @track transactions = [];
    @track purchaseOrders = [];
    @track monitorData = [];
    
    @wire(getRecentTransactions)
    wiredTxns(result) {
        if (result.data) this.transactions = result.data;
    }
    
    @wire(getPurchaseOrders)
    wiredPOs(result) {
        if (result.data) this.purchaseOrders = result.data;
    }
    
    @wire(getMonitorData)
    wiredMonitor(result) {
        if (result.data) this.monitorData = result.data;
    }
    
    get timelineEvents() {
        const events = [];
        
        // 1. Transactions (Stock In, Stock Out, Adjustments)
        this.transactions.forEach(t => {
            const date = new Date(t.Transaction_Date__c);
            let title = '';
            let type = '';
            let iconName = 'utility:setup';
            let iconClass = 'timeline-badge adjustment';
            
            if (t.Transaction_Type__c === 'Stock In') {
                title = `Stock In: Received ${t.Quantity__c} units of ${t.Product__r.Product_Name__c}`;
                type = 'Stock In';
                iconName = 'utility:download';
                iconClass = 'timeline-badge stock-in';
            } else if (t.Transaction_Type__c === 'Stock Out') {
                title = `Stock Out: Dispatched ${t.Quantity__c} units of ${t.Product__r.Product_Name__c}`;
                type = 'Stock Out';
                iconName = 'utility:upload';
                iconClass = 'timeline-badge stock-out';
            } else {
                title = `Stock Adjustment: Adjusted ${t.Quantity__c} units of ${t.Product__r.Product_Name__c}`;
                type = 'Adjustment';
                iconName = 'utility:layers';
                iconClass = 'timeline-badge adjustment';
            }
            
            events.push({
                id: t.Id,
                title,
                type,
                date,
                formattedDate: date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
                iconName,
                iconClass,
                detail: `Code: ${t.Name}`
            });
        });
        
        // 2. Purchase Orders
        this.purchaseOrders.forEach(po => {
            const date = new Date(po.Order_Date__c);
            events.push({
                id: po.Id,
                title: `Purchase Order ${po.Name}: Status is ${po.Status__c} for ${po.Supplier__r.Name}`,
                type: 'Purchase Order',
                date,
                formattedDate: date.toLocaleDateString(),
                iconName: 'utility:cart',
                iconClass: 'timeline-badge po',
                detail: `Total Amount: $${po.Total_Amount__c}`
            });
        });
        
        // 3. Low Stock Alerts
        this.monitorData.forEach(p => {
            if (p.Current_Stock__c <= p.Minimum_Stock__c) {
                const date = new Date();
                events.push({
                    id: p.Id + '-alert',
                    title: `Low Stock Alert: ${p.Product_Name__c} is running low!`,
                    type: 'Low Stock',
                    date,
                    formattedDate: 'Active Alert',
                    iconName: 'utility:warning',
                    iconClass: 'timeline-badge low-stock-alert',
                    detail: `Current Stock: ${p.Current_Stock__c} units (Minimum required: ${p.Minimum_Stock__c})`
                });
            }
        });
        
        events.sort((a, b) => b.date - a.date);
        
        return events.slice(0, 10);
    }

    get hasEvents() {
        return this.timelineEvents.length > 0;
    }
}
