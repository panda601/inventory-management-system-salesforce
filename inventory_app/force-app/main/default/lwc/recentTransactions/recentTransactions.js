import { LightningElement, wire } from 'lwc';
import getRecentTransactions from '@salesforce/apex/InventoryController.getRecentTransactions';
import { refreshApex } from '@salesforce/apex';

export default class RecentTransactions extends LightningElement {
    wiredTxnResult;
    transactions;
    error;

    @wire(getRecentTransactions)
    wiredData(result) {
        this.wiredTxnResult = result;
        if (result.data) {
            this.transactions = result.data.map(txn => {
                let badgeClass = 'txn-badge';
                if (txn.Transaction_Type__c === 'Stock In') {
                    badgeClass += ' stock-in';
                } else if (txn.Transaction_Type__c === 'Stock Out') {
                    badgeClass += ' stock-out';
                } else {
                    badgeClass += ' adjustment';
                }
                return {
                    ...txn,
                    badgeClass
                };
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.transactions = undefined;
        }
    }

    handleRefresh() {
        refreshApex(this.wiredTxnResult);
    }
}
