import { LightningElement, wire, track } from 'lwc';
import getMonitorData from '@salesforce/apex/InventoryController.getMonitorData';
import { refreshApex } from '@salesforce/apex';

export default class InventoryMonitor extends LightningElement {
    wiredMonitorResult;
    @track monitorData = [];
    error;

    @wire(getMonitorData)
    wiredData(result) {
        this.wiredMonitorResult = result;
        if (result.data) {
            this.monitorData = result.data.map(prod => {
                const current = prod.Current_Stock__c || 0;
                const min = prod.Minimum_Stock__c || 10;
                
                let status = 'Healthy';
                let badgeClass = 'status-badge healthy';
                let trafficLight = '🟢';
                let recommendation = 0;
                let showRec = false;

                if (current === 0) {
                    status = 'Out of Stock';
                    badgeClass = 'status-badge out-of-stock';
                    trafficLight = '🔴';
                    recommendation = min * 2;
                    showRec = true;
                } else if (current <= min) {
                    status = 'Low Stock';
                    badgeClass = 'status-badge low-stock';
                    trafficLight = '🟡';
                    recommendation = (min * 2) - current;
                    showRec = true;
                }

                return {
                    ...prod,
                    status,
                    badgeClass,
                    trafficLight,
                    recommendation,
                    showRec
                };
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.monitorData = [];
        }
    }

    handleRefresh() {
        refreshApex(this.wiredMonitorResult);
    }
}
