# User Stories - Inventory Management System

This document is the absolute source of truth for the Inventory Management System. It defines the core requirements for managing products, suppliers, purchase orders, sales orders, inventory transactions, security access, and automations.

---

## 1. Product & Supplier Management

### US1.1: Product Catalog
* **As an** Inventory Manager,
* **I want to** maintain a central catalog of products (using `Product__c`),
* **So that** we can track SKUs, description, cost, selling price, and real-time inventory stock levels.
* **Acceptance Criteria**:
  * Product Name is required.
  * SKU must be a unique, required text field.
  * Product Status (Picklist: Active, Draft, Archived) is required.
  * Stock On Hand (Number, Default: 0) tracks current inventory levels.
  * Reorder Point (Number, Default: 10) tracks when to place a new order.
  * Cost Price (Currency) and Selling Price (Currency) must be positive values.

### US1.2: Supplier Directory
* **As an** Inventory Manager,
* **I want to** manage suppliers (using `Supplier__c`),
* **So that** I know which supplier provides which products and who to contact.
* **Acceptance Criteria**:
  * Supplier Name is required.
  * Supplier Status (Picklist: Active, Inactive) is required.
  * Contact Email and Phone must follow valid Salesforce patterns.

---

## 2. Procurement (Purchase Orders)

### US2.1: Purchase Order Creation
* **As an** Inventory Manager,
* **I want to** create Purchase Orders (using `Purchase_Order__c`) to procure products from suppliers,
* **So that** I can track incoming inventory and unit costs.
* **Acceptance Criteria**:
  * Each Purchase Order is associated with a single `Supplier__c`.
  * Status (Picklist: Draft, Ordered, Received, Cancelled) defaults to `Draft`.
  * Total Amount (Roll-up Summary of Purchase Order Items) must show the sum of all line item costs.

### US2.2: Purchase Order Items
* **As an** Inventory Manager,
* **I want to** add specific products and quantities to a Purchase Order (using `Purchase_Order_Item__c`),
* **So that** suppliers know exactly what we are ordering.
* **Acceptance Criteria**:
  * Master-Detail relationship to `Purchase_Order__c`.
  * Lookup relationship to `Product__c`.
  * Quantity Ordered (Number) must be greater than 0.
  * Unit Cost (Currency) defaults to the Product's Cost Price but can be overridden.
  * Line Total is a formula field: `Quantity_Ordered__c * Unit_Cost__c`.

---

## 3. Customer Sales (Sales Orders)

### US3.1: Sales Order Management
* **As a** Sales Executive,
* **I want to** record customer orders using Sales Orders (using `Sales_Order__c`),
* **So that** we can fulfill customer requests and track sales revenue.
* **Acceptance Criteria**:
  * Customer Name, Order Date, and Customer Email are required.
  * Lookup relationship to `Product__c`.
  * Quantity Ordered (Number) must be greater than 0.
  * Unit Price (Currency) defaults to the Product's Selling Price but can be overridden.
  * Total Price is a formula field: `Quantity_Ordered__c * Unit_Price__c`.
  * Status (Picklist: Draft, Approved, Shipped, Cancelled) defaults to `Draft`.

---

## 4. Inventory Tracking & Automations

### US4.1: Stock Level Sync on PO Receipt
* **As an** Inventory Manager,
* **I want the system to** automatically increase the Product's Stock On Hand when a Purchase Order status transitions to `Received`,
* **So that** our inventory levels are updated in real-time without manual count logging.
* **Acceptance Criteria**:
  * Transition of `Purchase_Order__c.Status__c` to `Received` triggers a flow.
  * The flow increases `Product__c.Stock_On_Hand__c` by the `Quantity_Ordered__c` for each related `Purchase_Order_Item__c`.
  * The flow creates an `Inventory_Transaction__c` record of type `Inflow` for each item.

### US4.2: Stock Level Sync on SO Shipment
* **As a** Sales Executive,
* **I want the system to** automatically decrease the Product's Stock On Hand when a Sales Order status transitions to `Shipped`,
* **So that** we do not sell out-of-stock products and maintain an accurate ledger.
* **Acceptance Criteria**:
  * Transition of `Sales_Order__c.Status__c` to `Shipped` triggers a flow.
  * The flow checks if enough stock is available. If yes, it decreases `Product__c.Stock_On_Hand__c` by `Quantity_Ordered__c` and creates an `Inventory_Transaction__c` of type `Outflow`.
  * If insufficient stock is available, the status transition is blocked, or an alert is logged.

### US4.3: Inventory Transaction Log
* **As an** Inventory Manager,
* **I want to** view a read-only historical ledger of stock movements (using `Inventory_Transaction__c`),
* **So that** I can audit stock changes (Inflow, Outflow, Adjustment).
* **Acceptance Criteria**:
  * Master-Detail relationship to `Product__c`.
  * Transaction Type (Picklist: Inflow, Outflow, Adjustment) is required.
  * Quantity (Number) must be positive.
  * Related Purchase Order or Sales Order lookups are optional (to link transaction origin).
  * Date/Time is set to System Date/Time.

---

## 5. Security & Sharing Rules

### US5.1: Private Access Controls (OWD)
* **As a** Security Administrator,
* **I want to** set Organization-Wide Defaults (OWD) to Private for custom objects,
* **So that** we prevent unauthorized data visibility between roles.
* **Acceptance Criteria**:
  * `Supplier__c`, `Purchase_Order__c`, and `Sales_Order__c` set to **Private**.
  * `Product__c` set to **Public Read-Only** (so Sales Executives can view catalog).
  * `Purchase_Order_Item__c` and `Inventory_Transaction__c` are **Controlled by Parent** (Master-Detail).

### US5.2: Role Hierarchy & Permissions
* **As an** administrator,
* **I want to** establish distinct permission sets and roles for `Inventory Manager` and `Sales Executive`,
* **So that** users have access aligned with their business functions.
* **Acceptance Criteria**:
  * **Inventory Manager Role/Permission Set**: Full CRUD on Products, Suppliers, Purchase Orders, PO Items, and Inventory Transactions. Read-only on Sales Orders.
  * **Sales Executive Role/Permission Set**: Read-only on Products and Suppliers. Full CRUD on Sales Orders. Read-only on Inventory Transactions. No access to Purchase Orders.
  * **Sharing Rules**:
    * Purchase Orders are shared with Inventory Managers.
    * Sales Orders are shared with Sales Executives.
