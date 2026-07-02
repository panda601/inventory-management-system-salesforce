# Known Limitations & Scaling Roadmap

This document outlines the current technical trade-offs, limits, and the future development roadmap for the Inventory Management System.

---

## Known Limitations

### 1. Trigger & Flow Concurrency on Replacement RMAs
* **Problem**: When a return request is approved with a resolution of `Replacement`, the database trigger increments product stock by 1 while the record-triggered flow immediately decrements it by 1. Because the flow query runs before the trigger's DML transaction commits in anonymous blocks, the flow can retrieve a stale stock level, leading to an incorrect net stock count.
* **Mitigation**: Currently handled by enforcing sequential validation checks. The long-term fix is to consolidate RMA stock mutations into a single domain trigger framework class.

### 2. Standard Tabset Customizations
* **Problem**: LWC shadow DOM constraints restrict direct styling of the child elements of base components (e.g. `.slds-tabs_default__nav` inside `lightning-tabset`).
* **Mitigation**: The current sticky implementation relies on synthetic shadow DOM compile rules to inject sticky tab headers. If Salesforce transitions to native shadow DOM, a custom LWC tabset component will be required to replace `lightning-tabset`.

### 3. Bulk Order Limits
* **Problem**: Flow-based stock updates process updates line-by-line. If a single Sales Order contains hundreds of line items, it may approach transaction limits.
* **Mitigation**: Batch-size limits are currently guarded by validation rules. For large-volume enterprises, logic should be refactored into a bulkified Apex trigger.

---

## Future Roadmap

1. **Integrated Barcode Scanning**:
   Use Salesforce Mobile SDK capabilities to enable warehouse operators to scan item barcodes directly from mobile browsers, automatically creating transactions.
2. **Multi-Warehouse Support**:
   Extend `Inventory_Transaction__c` and `Product__c` schemas to support tracking items across multiple geographical warehouse locations, introducing inventory transfer order objects.
3. **AI-Driven Reorder Suggestions**:
   Integrate Salesforce Einstein or Gemini APIs to analyze historical sales velocities and automatically suggest purchase order restock volumes based on seasonal demand trends.
