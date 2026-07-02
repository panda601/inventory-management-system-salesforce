import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSupplierDetail from '@salesforce/apex/InventoryController.getSupplierDetail';

export default class SupplierDetail extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    @track isLoading = true;
    @track supplierData = null;
    @track error = null;
    
    wiredSupplierResult;

    @wire(getSupplierDetail, { recordId: '$recordId' })
    wiredDetail(result) {
        this.wiredSupplierResult = result;
        this.isLoading = false; // Always stop the spinner when the wire method provisions a result
        
        if (result.data) {
            this.supplierData = result.data;
            this.error = null;
        } else if (result.error) {
            this.error = result.error;
            this.supplierData = null;
            this.showErrorToast(result.error);
        }
    }

    get hasData() {
        return !!(this.supplierData && this.supplierData.supplier);
    }

    get showEmptyState() {
        return !this.isLoading && !this.hasData;
    }

    get supplierName() {
        return this.supplierData?.supplier?.Supplier_Name__c || this.supplierData?.supplier?.Name || 'Supplier';
    }

    get supplierCode() {
        return this.supplierData?.supplier?.Name || '';
    }

    get status() {
        return this.supplierData?.supplier?.Status__c || 'Inactive';
    }

    get email() {
        return this.supplierData?.supplier?.Email__c;
    }

    get emailHref() {
        return this.email ? `mailto:${this.email}` : '';
    }

    get phone() {
        return this.supplierData?.supplier?.Phone__c || 'N/A';
    }

    get address() {
        return this.supplierData?.supplier?.Address__c || 'N/A';
    }

    get createdDate() {
        return this.supplierData?.supplier?.CreatedDate;
    }

    get statusBadgeClass() {
        return this.status === 'Active' ? 'status-badge healthy' : 'status-badge low-stock';
    }

    get purchaseOrders() {
        if (!this.supplierData || !this.supplierData.purchaseOrders) {
            return [];
        }
        return this.supplierData.purchaseOrders.map(po => {
            let badgeClass = 'status-badge ';
            if (po.Status__c === 'Draft') badgeClass += 'draft';
            else if (po.Status__c === 'Approved') badgeClass += 'approved';
            else if (po.Status__c === 'Received') badgeClass += 'received';
            else if (po.Status__c === 'Cancelled') badgeClass += 'cancelled';
            else badgeClass += 'neutral';

            return {
                ...po,
                badgeClass
            };
        });
    }

    get productsSupplied() {
        return this.supplierData?.productsSupplied || [];
    }

    get hasPurchaseOrders() {
        return this.purchaseOrders.length > 0;
    }

    get hasProductsSupplied() {
        return this.productsSupplied.length > 0;
    }

    handleRecordNavigate(event) {
        event.preventDefault();
        const recId = event.currentTarget.dataset.id;
        const objectType = event.currentTarget.dataset.object;
        
        if (!recId || !objectType) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                objectApiName: objectType,
                actionName: 'view'
            }
        });
    }

    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredSupplierResult)
            .catch(err => {
                this.showErrorToast(err);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showErrorToast(error) {
        let message = 'An unexpected error occurred while loading supplier details.';
        if (error && error.body && error.body.message) {
            message = error.body.message;
        } else if (error && error.message) {
            message = error.message;
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error Loading Supplier',
                message: message,
                variant: 'error'
            })
        );
    }
}
