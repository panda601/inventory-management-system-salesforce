import { LightningElement, wire, track, api } from 'lwc';
import getRecentTransactions from '@salesforce/apex/InventoryController.getRecentTransactions';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class RecentTransactions extends NavigationMixin(LightningElement) {
    @api limit = 5;
    @api showViewAllButton = false;
    
    wiredTxnResult;
    transactions;
    error;
    @track isLoading = false;
    @track typeFilter = 'All';

    @wire(getRecentTransactions)
    wiredData(result) {
        this.wiredTxnResult = result;
        if (result.data) {
            this.transactions = result.data.map(txn => {
                let badgeClass = 'txn-badge';
                let iconName = 'utility:setup';
                let iconClass = 'adjustment-icon';
                
                if (txn.Transaction_Type__c === 'Stock In') {
                    badgeClass += ' stock-in';
                    iconName = 'utility:download';
                    iconClass = 'stock-in-icon';
                } else if (txn.Transaction_Type__c === 'Stock Out') {
                    badgeClass += ' stock-out';
                    iconName = 'utility:upload';
                    iconClass = 'stock-out-icon';
                } else {
                    badgeClass += ' adjustment';
                }
                return {
                    ...txn,
                    badgeClass,
                    iconName,
                    iconClass
                };
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.transactions = undefined;
        }
    }

    get filteredTransactions() {
        if (!this.transactions) return [];
        let txns = this.transactions;
        if (this.typeFilter !== 'All') {
            txns = txns.filter(t => t.Transaction_Type__c === this.typeFilter);
        }
        return txns.slice(0, this.limit);
    }

    handleViewDetails(event) {
        const txnId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: txnId,
                objectApiName: 'Inventory_Transaction__c',
                actionName: 'view'
            }
        });
    }

    get stockInBtnClass() {
        return this.typeFilter === 'Stock In' ? 'slds-button slds-button_brand rounded-btn active-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    get stockOutBtnClass() {
        return this.typeFilter === 'Stock Out' ? 'slds-button slds-button_brand rounded-btn active-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    get adjustmentsBtnClass() {
        return this.typeFilter === 'Adjustment' ? 'slds-button slds-button_brand rounded-btn active-btn' : 'slds-button slds-button_neutral rounded-btn';
    }

    handleFilterStockIn() {
        this.typeFilter = this.typeFilter === 'Stock In' ? 'All' : 'Stock In';
    }

    handleFilterStockOut() {
        this.typeFilter = this.typeFilter === 'Stock Out' ? 'All' : 'Stock Out';
    }

    handleFilterAdjustments() {
        this.typeFilter = this.typeFilter === 'Adjustment' ? 'All' : 'Adjustment';
    }

    navigateToViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Inventory_Transaction__c',
                actionName: 'list'
            }
        });
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredTxnResult)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Transactions refreshed successfully.',
                        variant: 'success'
                    })
                );
            })
            .catch(err => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error refreshing transactions: ' + (err.body ? err.body.message : err.message),
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
