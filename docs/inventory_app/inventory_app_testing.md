# Manual Testing & User Acceptance Testing (UAT) Workflow - Inventory Management System

This document provides a comprehensive, step-by-step, persona-driven manual testing guide for the **Inventory Management System**. It outlines verification scenarios for custom objects, validation rules, record-triggered flows, sharing security, reports, dashboards, and the Lightning Home Page.

---

## 👥 Persona Matrix & Credentials

Before initiating manual testing, verify that the following test users exist in the target org `StudentAppOrg` and have the specified configurations:

| Role | Username | Assigned Permission Set | Expected Access Profile |
| :--- | :--- | :--- | :--- |
| **System Administrator** | `723145roy.6036123142ec@agentforce.com` | *All System Permissions* | Full read/write and setup capabilities. |
| **Inventory Manager** | `backuproy0911.salesexec@inventory.app.com` | `Inventory_Manager_Access` | Full warehouse access, supplier, and PO management. |
| **Sales Executive** | `backuproy0911.invmgr@inventory.app.com` | `Sales_Executive_Access` | Sales order creation and public product viewing. |

---

## 🚀 E2E Manual Test Cases

### Use Case A: Product Catalog Setup & Input Validations
* **Tester Persona**: **Inventory Manager**
* **Objective**: Verify that products can be created, price is validated, and SKU uniqueness is enforced.
* **Scenario 1 (Price Validation - VR-003)**:
  1. Log in as the **Inventory Manager**.
  2. Open the **App Launcher** (9-dot icon) and select the **Inventory Management System** app.
  3. Navigate to the **Products** tab and click **New**.
  4. Fill in the fields:
     * Product Name: `UAT Test Product 1`
     * SKU: `SKU-UAT-001`
     * Price: `-10.00` *(Negative price to trigger error)*
     * Current Stock: `10`
     * Minimum Stock: `5`
     * Status: `Active`
  5. Click **Save**.
  * **Expected Outcome**: The save is blocked with the error message: *"Price must be greater than zero."*
  6. Correct the Price to `100.00` and click **Save**.
  * **Expected Outcome**: The record saves successfully.

* **Scenario 2 (SKU Uniqueness - VR-001)**:
  1. Click **New** to create a second product.
  2. Fill in the fields:
     * Product Name: `UAT Test Product Duplicate`
     * SKU: `SKU-UAT-001` *(Duplicate SKU from Scenario 1)*
     * Price: `50.00`
     * Current Stock: `5`
     * Minimum Stock: `2`
     * Status: `Active`
  3. Click **Save**.
  * **Expected Outcome**: The save is blocked at the database level by the unique constraint on `SKU__c` with a duplicate value error.
  4. Change the SKU to `SKU-UAT-002` and click **Save**.
  * **Expected Outcome**: The record saves successfully.

---

### Use Case B: Purchase Order & Stock Ingestion (Flow 1)
* **Tester Persona**: **Inventory Manager**
* **Objective**: Verify that receiving a Purchase Order increments product stock and creates a Stock In transaction log.
* **Steps**:
  1. Navigate to the **Suppliers** tab and click **New**.
  2. Create a supplier:
     * Supplier Name: `UAT Supplier`
     * Status: `Active`
     * Email: `supplier@uat.com`
     * Phone: `1234567890`
     * Click **Save**.
  3. Navigate to the **Purchase Orders** tab and click **New**.
  4. Select `UAT Supplier` as the Supplier, and set **Status** to `Draft`. Click **Save**.
  5. Under the **Purchase Order Items** related list, click **New** to add a line item:
     * Product: `UAT Test Product 1` *(Current Stock: 10)*
     * Quantity: `50`
     * Unit Price: `80.00`
     * Click **Save**.
  6. Verify that `Purchase_Order__c.Total_Amount__c` automatically rolls up to `4,000.00` (50 * 80).
  7. Change the **Status** of the Purchase Order to `Received` and click **Save**.
  * **Expected Outcome**: 
    * The related Product `UAT Test Product 1`'s **Current Stock** updates from `10` to `60`.
    * A new record under the **Inventory Transactions** tab is created with:
      * Product: `UAT Test Product 1`
      * Quantity: `50`
      * Transaction Type: `Stock In`
      * Date: *Current Date & Time*

---

### Use Case C: Sales Order Lifecycle & Stock Check (Flow 2 / VR-004)
* **Tester Persona**: **Sales Executive**
* **Objective**: Verify that sales orders enforce stock availability upon confirmation, decrement stock, and log Stock Out transactions.
* **Scenario 1 (Insufficient Stock - VR-004)**:
  1. Log in as the **Sales Executive**.
  2. Navigate to the **Sales Orders** tab and click **New**.
  3. Set Customer Name to `UAT Customer` and Status to `Draft`. Click **Save**.
  4. Under the **Sales Order Items** related list, click **New**:
     * Product: `UAT Test Product 2` *(Current Stock: 5)*
     * Quantity: `10` *(More than available stock)*
     * Unit Price: `150.00`
     * Click **Save**.
  5. Click **Edit** on the Sales Order and change the **Status** to `Confirmed`. Click **Save**.
  * **Expected Outcome**: The update is blocked with the error message: *"Insufficient Stock Available"* on the sales order item.

* **Scenario 2 (Successful Confirmation & Stock Reduction)**:
  1. Edit the Sales Order Item and change the **Quantity** to `3` *(Within current stock of 5)*. Click **Save**.
  2. Change the Sales Order **Status** to `Confirmed` and click **Save**.
  * **Expected Outcome**:
    * The Sales Order status changes to `Confirmed`.
    * The related Product `UAT Test Product 2`'s **Current Stock** updates from `5` to `2`.
    * A new record under the **Inventory Transactions** tab is created with:
      * Product: `UAT Test Product 2`
      * Quantity: `3`
      * Transaction Type: `Stock Out`
      * Date: *Current Date & Time*

---

### Use Case D: Low Stock Notification Alerts (Flow 3)
* **Tester Persona**: **System Administrator / Sales Executive**
* **Objective**: Verify that dropping below minimum stock creates a Task assigned to the Inventory Manager.
* **Steps**:
  1. Set up a product `UAT Test Product 2` with Minimum Stock = `3`.
  2. Trigger a stock reduction (e.g. by confirming the Sales Order in Use Case C, Scenario 2, which set stock to `2`).
  3. Log in as the **Inventory Manager** (`backuproy0911.salesexec@inventory.app.com`).
  4. Check the **Tasks** list on the Home Page or navigate to the Tasks tab.
  * **Expected Outcome**: A high-priority task exists with:
    * Subject: `Low Stock Alert: UAT Test Product 2`
    * Priority: `High`
    * Status: `Not Started`
    * Assigned To: `Inventory Manager` user

---

### Use Case E: Sharing & Visibility Validation (OWD)
* **Tester Persona**: **Sales Executive**
* **Objective**: Verify that the Sales Executive profile does not have visibility to private objects and has read-only access to products.
* **Steps**:
  1. Log in as the **Sales Executive**.
  2. From the App Launcher, try to find the **Suppliers**, **Purchase Orders**, or **Inventory Transactions** tabs.
  * **Expected Outcome**: These tabs are invisible.
  3. Navigate to a **Product** record.
  4. Attempt to edit the product name or stock level.
  * **Expected Outcome**: Editing is blocked/fields are read-only.
  5. Navigate to the **Sales Orders** tab. Create a Sales Order (Success).
  6. Log in as the **Inventory Manager**.
  7. Verify you can view the Sales Order created by the Sales Executive in step 5.
  * **Expected Outcome**: The Inventory Manager can view the Sales Order due to inheriting access through the role hierarchy.

---

### Use Case F: Reports, Dashboards & Home Page Layout
* **Tester Persona**: **Inventory Manager**
* **Objective**: Verify that the dashboard loads correct metrics and is embedded on the Home Page.
* **Steps**:
  1. Log in as the **Inventory Manager**.
  2. Click the **Home** tab of the **Inventory Management System** app.
  3. Inspect the regions:
     * **Header**: Verify the **Inventory Manager Dashboard** is rendered. Click **Refresh** to reload the 8 metrics/charts.
     * **Main (Left)**: Verify the **Assistant** component displays alerts.
     * **Main (Middle/Right)**: Verify that **Recent Purchase Orders** and **Recent Sales Orders** list cards load correctly.
  4. Go to the **Dashboards** tab, navigate to the `Inventory Dashboards` folder, and open `Inventory Manager Dashboard`.
  * **Expected Outcome**: The dashboard compiles, displays data from all 5 inventory reports, and correctly shows the running user is set to `backuproy0911.invmgr@inventory.app.com` (to see dashboard data).
