# Agent Architecture - Inventory Operations Agent

This document details the multi-agent system architecture designed for the Inventory Management System (IMS). The architecture follows a central Orchestrator (Hub) and specialized Topics (Spokes) pattern, implemented on the Salesforce Agentforce (Service Agent) platform.

## High-Level Architecture Diagram

```mermaid
graph TD
    User([User Chat/Messaging]) --> Hub[Inventory Operations Agent <br> Master Router]
    
    subgraph Spoke Topics
        Hub --> Spoke1[Inventory Agent]
        Hub --> Spoke2[Purchase Agent]
        Hub --> Spoke3[Sales Agent]
        Hub --> Spoke4[Supplier Agent]
        Hub --> Spoke5[Return & Replacement Agent]
        Hub --> Spoke6[Admin Agent]
        Hub --> Spoke7[Analytics Agent]
        Hub --> Spoke8[Notification Agent]
        Hub --> Spoke9[Product Image Agent]
    end

    subgraph Service Wrappers & Business Logic
        Spoke1 --> Apex1[IMS_GetProductDetail <br> IMS_GetInventoryHealth]
        Spoke2 --> Apex2[IMS_CreatePurchaseOrder]
        Spoke3 --> Apex3[IMS_CreateSalesOrder <br> IMS_GetProductDetail]
        Spoke4 --> Apex4[IMS_GetSupplierPerformance]
        Spoke5 --> Apex5[IMS_ProcessReturnRequest]
        Spoke6 --> Apex6[IMS_GetSystemHealth]
        Spoke7 --> Apex7[IMS_GetProductPerformance <br> IMS_GetSupplierPerformance]
        Spoke8 --> Apex8[IMS_GetLowStockAlerts]
        Spoke9 --> Apex9[IMS_DeleteProductImage]
    end

    subgraph Salesforce Data & Automation Layer
        Apex1 & Apex2 & Apex3 & Apex4 & Apex5 & Apex6 & Apex7 & Apex8 & Apex9 --> DB[(Salesforce CRM DB <br> Custom Objects & Fields)]
        DB --> Flow1[Stock-In Flow <br> Record-Triggered]
        DB --> Flow2[Stock-Out Flow <br> Record-Triggered]
    end
```

## Architecture Principles

### 1. Hub-and-Spoke Pattern
The **Inventory Operations Agent** acts as the central router (Hub) that receives the user's natural language input, determines the intent, and transitions (routes) the session to one of the 9 specialized topics (Spokes). This separates concerns, ensures high routing accuracy, and prevents prompt bloat.

### 2. Loose Coupling
The master router and the specialized spoke agents do not execute business logic directly. Instead, they interact with the database and business rules through clean Apex wrappers.

### 3. Salesforce Permission Security
All data queries and database transactions are processed through Apex classes running under the Einstein Agent User's security context. This access is governed strictly by the custom `InventoryOperationsAgent_Access` permission set.

### 4. Dynamic Execution
- **Routing**: The master agent uses natural language classification to transition between topics.
- **Action Invocations**: Within each topic, specialized reasoning instructions guide the model to collect necessary parameters (e.g., product IDs, customer names, quantities) and execute the corresponding invocable method.
