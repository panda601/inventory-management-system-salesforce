import { LightningElement, wire, track, api } from 'lwc';
import getMonitorData from '@salesforce/apex/InventoryController.getMonitorData';
import getReorderPrefillInfo from '@salesforce/apex/InventoryController.getReorderPrefillInfo';
import createPurchaseOrderWithItem from '@salesforce/apex/InventoryController.createPurchaseOrderWithItem';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class InventoryMonitor extends NavigationMixin(LightningElement) {
    @api showOnlyAlerts = false;
    
    wiredMonitorResult;
    @track monitorData = [];
    @track isLoading = false;
    @track error;

    // Prefills & Modal tracking
    @track isPOModalOpen = false;
    @track prefillProductId = '';
    @track prefillProductName = '';
    @track prefillQuantity = 0;
    @track prefillSupplierId = '';
    @track prefillUnitPrice = 0.0;

    // CDC Subscription references
    subProduct;
    subPO;

    @wire(getMonitorData)
    wiredData(result) {
        this.wiredMonitorResult = result;
        if (result.data) {
            this.monitorData = result.data.map(prod => {
                const current = prod.Current_Stock__c || 0;
                const min = prod.Minimum_Stock__c || 10;
                
                let status = 'Healthy';
                let badgeClass = 'status-badge healthy';
                let recommendation = 0;
                let progressBarVariant = 'success';
                
                const maxStock = min * 2.5;
                let healthPct = Math.round((current / maxStock) * 100);
                if (healthPct > 100) healthPct = 100;

                if (current === 0) {
                    status = 'Out Of Stock';
                    badgeClass = 'status-badge out-of-stock';
                    recommendation = maxStock;
                    progressBarVariant = 'expired';
                } else if (current <= min) {
                    status = 'Low Stock';
                    badgeClass = 'status-badge low-stock';
                    recommendation = maxStock - current;
                    progressBarVariant = 'warning';
                }

                return {
                    ...prod,
                    status,
                    badgeClass,
                    recommendation,
                    healthPct,
                    progressBarVariant
                };
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.monitorData = [];
        }
    }

    get lowStockAlerts() {
        return this.monitorData.filter(item => item.status !== 'Healthy');
    }

    get hasAlerts() {
        return this.lowStockAlerts.length > 0;
    }

    connectedCallback() {
        this.subscribeToCDC();
    }

    disconnectedCallback() {
        if (this.subProduct) unsubscribe(this.subProduct);
        if (this.subPO) unsubscribe(this.subPO);
    }

    subscribeToCDC() {
        const self = this;
        const callback = function(response) {
            console.log('InventoryMonitor CDC received: ', JSON.stringify(response));
            self.refreshAll();
        };

        subscribe('/data/Product__ChangeEvent', -1, callback).then(response => {
            self.subProduct = response;
        });

        subscribe('/data/Purchase_Order__ChangeEvent', -1, callback).then(response => {
            self.subPO = response;
        });

        onError(err => {
            console.error('InventoryMonitor empApi error: ', JSON.stringify(err));
        });
    }

    @api
    refreshAll() {
        this.isLoading = true;
        return refreshApex(this.wiredMonitorResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Modal Prefills Handlers
    handleOpenReorderModal(event) {
        const productId = event.currentTarget.dataset.id;
        const productName = event.currentTarget.dataset.name;
        const qty = parseFloat(event.currentTarget.dataset.qty) || 0;

        this.isLoading = true;
        this.prefillProductId = productId;
        this.prefillProductName = productName;
        this.prefillQuantity = qty;

        getReorderPrefillInfo({ productId: productId })
            .then(info => {
                if (info) {
                    this.prefillSupplierId = info.supplierId;
                    this.prefillUnitPrice = info.unitPrice;
                }
                this.isPOModalOpen = true;
            })
            .catch(err => {
                console.error('Error prefilling PO fields: ', err);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error prefilling PO: ' + (err.body ? err.body.message : err.message),
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    closePOModal() {
        this.isPOModalOpen = false;
        this.prefillProductId = '';
        this.prefillProductName = '';
        this.prefillQuantity = 0;
        this.prefillSupplierId = '';
        this.prefillUnitPrice = 0.0;
    }

    handleSupplierChange(event) {
        this.prefillSupplierId = event.target.value;
    }

    handleQuantityChange(event) {
        this.prefillQuantity = parseFloat(event.target.value) || 0;
    }

    handlePriceChange(event) {
        this.prefillUnitPrice = parseFloat(event.target.value) || 0.0;
    }

    submitCustomPO() {
        if (!this.prefillSupplierId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Supplier Required',
                    message: 'Please select a supplier.',
                    variant: 'warning'
                })
            );
            return;
        }
        if (this.prefillQuantity <= 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid Quantity',
                    message: 'Suggested Quantity must be positive.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isLoading = true;
        createPurchaseOrderWithItem({
            supplierId: this.prefillSupplierId,
            productId: this.prefillProductId,
            quantity: this.prefillQuantity,
            unitPrice: this.prefillUnitPrice
        })
        .then(poId => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Purchase Order created successfully.',
                    variant: 'success'
                })
            );
            this.closePOModal();
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: poId,
                    objectApiName: 'Purchase_Order__c',
                    actionName: 'view'
                }
            });
            // Bubble refresh event up
            this.dispatchEvent(new CustomEvent('refreshdata', { bubbles: true, composed: true }));
        })
        .catch(err => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error creating Purchase Order: ' + (err.body ? err.body.message : err.message),
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleCreatePO() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Purchase_Order__c',
                actionName: 'new'
            }
        });
    }
}
