import { LightningElement, track } from 'lwc';

export default class ErrorBoundary extends LightningElement {
    @track hasError = false;
    @track errorMessage = 'An unexpected error occurred while loading this section.';

    errorCallback(error, stack) {
        this.hasError = true;
        this.errorMessage = error && error.message ? error.message : String(error);
        console.error('Error Boundary Caught Error:', error, stack);
    }

    handleRetry() {
        this.hasError = false;
        this.errorMessage = '';
        // Dispatch event so parent components can re-fetch or re-initialize if needed
        this.dispatchEvent(new CustomEvent('retry'));
    }
}
