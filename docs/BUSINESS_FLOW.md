# Business Workflows & Automations

This document describes the three main business cycles managed by the Inventory Management System and how they map to automated Salesforce flows and database mutations.

---

## 1. Procurement Cycle (Stock In)

When stock is low, the Inventory Manager initiates replenishment from a supplier.

```mermaid
sequenceDiagram
    autonumber
    actor Manager as Inventory Manager
    participant PO as Purchase Order
    participant Flow as Purchase_Order_Received Flow
    participant Prod as Product Stock
    participant Ledger as Inventory Transaction Ledger

    Manager->>PO: Set Status to 'Received'
    PO->>Flow: Triggers on update
    Flow->>Prod: Increments Current_Stock__c by PO Item Quantity
    Flow->>Ledger: Creates 'Stock In' transaction record
    Note over Prod,Ledger: Database updates committed atomically
```

---

## 2. Sales Cycle (Stock Out)

Sales Executives capture customer purchases. The system protects stock from starvation using real-time validation checks.

```mermaid
sequenceDiagram
    autonumber
    actor Sales as Sales Executive
    participant SO as Sales Order
    participant VR as Validation Rule VR_004
    participant Flow as Sales_Order_Confirmed Flow
    participant Prod as Product Stock
    participant Ledger as Inventory Transaction Ledger

    Sales->>SO: Sets status to 'Confirmed'
    alt Quantity > Current Stock
        SO->>VR: Blocks execution
        VR-->>Sales: Displays 'Insufficient Stock' error message
    else Quantity <= Current Stock
        SO->>Flow: Triggers on update
        Flow->>Prod: Decrements Current_Stock__c by SO Item Quantity
        Flow->>Ledger: Creates 'Stock Out' transaction record
    end
```

---

## 3. Return & RMA Lifecycle

Tracks returned goods through initial submission, inspection, and final resolution.

```mermaid
graph TD
    A[Sales Executive] -->|Creates Return Request| B(Status: Submitted)
    B -->|Triggers Notification Flow| C[Manager Task Created]
    
    D[Inventory Manager] -->|Inspects Items| E{Review Decision}
    E -->|Reject| F(Status: Rejected)
    E -->|Advance| G(Status: Under Review)
    
    G -->|Needs Final Decision| H[Admin Approval Center]
    H -->|Select Resolution| I{Resolution Type}
    
    I -->|Repair| J(Status: Approved)
    J -->|Flow| J1[Increments stock & logs 'Adjustment' transaction]
    
    I -->|Replacement| K(Status: Replacement Sent)
    K -->|Flow| K1[Decrements stock & logs 'Stock Out' transaction]
    
    I -->|Refund| L(Status: Refunded)
    L -->|Flow| L1[Logs refund status without stock mutation]
```
