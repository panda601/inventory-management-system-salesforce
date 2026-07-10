# Agent Design - Inventory Operations Agent

This document outlines the detailed configuration and design of the Inventory Operations Agent, including classification patterns, topic instructions, and action schema mappings.

## Topic Specifications

The agent is structured with 1 entry topic (Topic Selector) and 9 functional spoke topics.

### 1. Topic Selector (Entry)
* **Description**: Routes user requests to the appropriate specialized spoke topic.
* **Instructions**: Greet the user and route them based on their intent (e.g., stock level -> inventory, purchase orders -> purchase, returns -> return).
* **Actions**: Transition actions to all 9 spoke topics.

### 2. Inventory Agent
* **Description**: Manages product lookup, stock levels, and inventory transactions.
* **Actions**:
  * `get_product_detail`: Inputs: `productId` (lightning__recordIdType). Outputs: Product Details.
  * `get_inventory_health`: Inputs: none. Outputs: stock aggregations.
* **Instructions**: Help the user view product details or general health of the inventory stock.

### 3. Purchase Agent
* **Description**: Manages procurement and purchase orders.
* **Actions**:
  * `create_purchase_order`: Inputs: `supplierId`, `productId` (lightning__recordIdType), `quantity`, `unitPrice`. Outputs: Purchase Order Record ID.
* **Instructions**: Collect parameters and use `create_purchase_order` to create POs in draft status. Note that PO status updates to 'Received' trigger stock-in flow automations automatically.

### 4. Sales Agent
* **Description**: Manages customer orders and product availability.
* **Actions**:
  * `create_sales_order`: Inputs: `customerName`, `productId` (lightning__recordIdType), `quantity`, `unitPrice`. Outputs: Sales Order Record ID.
  * `get_product_availability`: Inputs: `productId` (lightning__recordIdType). Outputs: Stock availability metrics.
* **Instructions**: Assist with order creation and availability checks. Emphasize that VR_004 will validate and block confirmation if sales order quantity exceeds available stock.

### 5. Supplier Agent
* **Description**: Manages supplier information and performance.
* **Actions**:
  * `get_supplier_performance`: Inputs: none. Outputs: List of supplier metrics (complex type: `@apexClassType/c__IMS_GetSupplierPerformance$SupplierPerformanceView`).
* **Instructions**: Handle supplier ratings and lead time queries.

### 6. Return & Replacement Agent
* **Description**: Manages return requests (RMA), approvals, repairs, replacements, and refunds.
* **Actions**:
  * `process_return_request`: Inputs: `requestId` (lightning__recordIdType), `status`, `resolutionType`. Outputs: Success boolean.
* **Instructions**: Process RMA status changes, respecting the approval hierarchy.

### 7. Admin Agent
* **Description**: Handles system audits, object health, role checks, and permission analyses.
* **Actions**:
  * `get_system_health`: Inputs: none. Outputs: Object counts and status metrics.
* **Instructions**: Retrieve system-wide object metrics for auditing.

### 8. Analytics Agent
* **Description**: Analyzes revenue, cost, profit margins, and sales trends.
* **Actions**:
  * `get_product_performance`: Inputs: none. Outputs: List of product stats (complex type: `@apexClassType/c__IMS_GetProductPerformance$ProductPerformanceView`).
  * `get_supplier_performance`: Inputs: none. Outputs: List of supplier performance stats.
* **Instructions**: Query sales leaderboard and vendor performance metrics.

### 9. Notification Agent
* **Description**: Retrieves active warnings and reorder alerts.
* **Actions**:
  * `get_low_stock_alerts`: Inputs: none. Outputs: List of low stock alerts (complex type: `@apexClassType/c__IMS_GetLowStockAlerts$LowStockAlertView`).
* **Instructions**: Scan for products at or below their minimum stock levels.

### 10. Product Image Agent
* **Description**: Manages uploading, replacing, and deleting product images.
* **Actions**:
  * `delete_product_image`: Inputs: `productId` (lightning__recordIdType). Outputs: Success boolean.
* **Instructions**: Delete product image files in Salesforce.

---

## Action Data Type Mappings

To ensure validation and compilation under the Einstein platform, custom types are mapped as follows:
* **Record IDs (Id/Lookup)**: Type `object`, `complex_data_type_name: "lightning__recordIdType"`.
* **Integers**: Type `object`, `complex_data_type_name: "lightning__integerType"`.
* **Apex Class Collections**: Type `list[object]`, `complex_data_type_name: "@apexClassType/c__ClassName$InnerClassName"`.
