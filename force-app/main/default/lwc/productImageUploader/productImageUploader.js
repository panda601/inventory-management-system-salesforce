import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getProductDetail from '@salesforce/apex/ProductController.getProductDetail';
import isProductImageAdmin from '@salesforce/apex/ProductImageController.isProductImageAdmin';
import deleteProductImage from '@salesforce/apex/ProductImageController.deleteProductImage';
import deleteOldImages from '@salesforce/apex/ProductImageController.deleteOldImages';

export default class ProductImageUploader extends LightningElement {
    @api recordId;

    @track isLoading = false;
    @track isAdmin = false;
    @track productRecord = null;

    fallbackImage = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" viewBox="0 0 100 100"><rect width="100%" height="100%" fill="%23f8f9fa" stroke="%23dddbda" stroke-width="1"/><rect x="25" y="25" width="50" height="50" rx="4" fill="none" stroke="%23b0adab" stroke-width="2"/><circle cx="50" cy="45" r="10" fill="none" stroke="%23b0adab" stroke-width="2"/><path d="M30 65 L45 50 L55 60 L70 45 L70 65 Z" fill="%23cbd5e0"/><text x="50%" y="85%" dominant-baseline="middle" text-anchor="middle" font-family="sans-serif" font-size="8" fill="%23706e6b">No Product Image Available</text></svg>`;

    wiredProductResult;

    get acceptedFormats() {
        return ['.jpg', '.jpeg', '.png', '.webp'];
    }

    @wire(isProductImageAdmin)
    wiredAdmin(result) {
        if (result.data !== undefined) {
            this.isAdmin = result.data;
        }
    }

    @wire(getProductDetail, { productId: '$recordId' })
    wiredProduct(result) {
        this.wiredProductResult = result;
        if (result.data) {
            this.productRecord = result.data;
            this.error = null;
        } else if (result.error) {
            this.productRecord = null;
            this.showToast('Error', 'Error retrieving product info', 'error');
        }
    }

    get imageUrl() {
        if (this.productRecord && this.productRecord.Product_Image__c) {
            return this.productRecord.Product_Image__c;
        }
        return this.fallbackImage;
    }

    get hasImage() {
        return !!(this.productRecord && this.productRecord.Product_Image__c);
    }

    get uploadLabel() {
        return this.hasImage ? 'Replace Image' : 'Upload Image';
    }

    handleImageError(event) {
        event.target.src = this.fallbackImage;
    }

    async handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles && uploadedFiles.length > 0) {
            const newFile = uploadedFiles[0];
            this.isLoading = true;
            
            try {
                // If we already had an image, clean it up
                if (this.hasImage) {
                    await deleteOldImages({ 
                        productId: this.recordId, 
                        newContentDocumentId: newFile.documentId 
                    });
                }
                
                this.showToast('Success', 'Product image uploaded successfully.', 'success');
                
                // Refresh data
                await refreshApex(this.wiredProductResult);
                await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            } catch (err) {
                this.showToast('Error', err.body?.message || 'Error processing replaced image', 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    async handleDeleteImage() {
        this.isLoading = true;
        try {
            await deleteProductImage({ productId: this.recordId });
            this.showToast('Success', 'Product image deleted successfully.', 'success');
            
            // Refresh data
            await refreshApex(this.wiredProductResult);
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (err) {
            this.showToast('Error', err.body?.message || 'Error deleting product image', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}
