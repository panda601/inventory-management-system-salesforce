# System Architecture

This document describes the high-level architecture of the **Inventory Management System (IMS)**, explaining how custom components, low-code automations, and database layers integrate natively on the Salesforce platform.

## High-Level System Architecture

The system utilizes standard Salesforce Lightning Platform architectures. Lightning Web Components serve as the visual layout layer, executing Apex controller methods and binding custom Salesforce events to interact with custom objects. Automation flows react to database mutations to run background stock ledger updates.

```mermaid
graph TD
    subgraph UI Layer [Lightning Experience UI]
        A[inventoryCommandCenter LWC]
        A --> B[inventoryDashboard LWC]
        A --> C[returnManagementDashboard LWC]
        A --> D[productCatalog LWC]
        A --> E[productDetail LWC]
    end

    subgraph Controller Layer [Apex Services]
        F[InventoryController Apex]
        G[InventoryDashboardController Apex]
        H[ProductController Apex]
        F --> A
        G --> B
        F --> C
        H --> D
        H --> E
    end

    subgraph Database & Platform Event Layer [Salesforce Database]
        I[Custom Objects & Fields]
        J[Platform Events / CDC]
        I --> J
        J --> F
    end

    subgraph Declarative Logic [Flows & Validation Rules]
        K[Purchase_Order_Received Flow]
        L[Sales_Order_Confirmed Flow]
        M[Return Approval Flows]
        N[Stock Starvation VR_004]
        I --> K
        I --> L
        I --> M
        I --> N
    end
```

## Architectural Design Principles

1. **Native Integration**: By building directly on Salesforce, the system inherits built-in security, user administration, reporting engines, standard database persistence, and transaction management.
2. **Event-Driven Auto-Refresh**: Utilizing Change Data Capture (CDC) platform events (`/data/Product__ChangeEvent`, etc.), the LWC dashboard subscribes to real-time events, automatically refreshing data metrics across user tabs without forcing full page reloads.
3. **Decoupled Business Logic**: Custom triggers and record-triggered flows handle record updates (e.g., updating product stock levels when a purchase order is received) asynchronously or during database transactions, separating user interface updates from structural database changes.
4. **Optimized Apex Controller Layer**: Heavy aggregates and queries are isolated inside cacheable and secured Apex classes (`WITH USER_MODE`), ensuring high performance and strong protection against unauthorized access.
