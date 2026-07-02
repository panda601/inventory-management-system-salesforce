# User Personas

This document describes the three target personas designed for the Inventory Management System, matching the business operations and permission separations.

---

## 1. System Administrator (Admin)

### Profile Details
* **Username (Target Org)**: `723145roy.6036123142ec@agentforce.com`
* **Assigned Permission Set**: `Admin_Access`
* **Custom Permissions**: `Can_Process_Return`, `Can_Approve_Refund`, `View_Profit_Metrics`

### Operational Focus
Admins have full visibility across all aspects of the application. They monitor business profits, handle high-value refund approvals, and manage the system configuration. They verify deployment metrics, review background errors, and manage security rules.

---

## 2. Inventory Manager

### Profile Details
* **Example Username**: `backuproy0911.invmgr@inventory.app.com`
* **Assigned Permission Set**: `Inventory_Manager_Access`
* **Custom Permissions**: `Can_Process_Return`

### Operational Focus
Managers are responsible for the day-to-day warehouse operations. They deal directly with suppliers, process incoming procurement purchase orders, track stock movements, and perform the initial inspection on returned products. They do not have access to overall corporate profits, cost rates, or direct refund controls.

---

## 3. Sales Executive

### Profile Details
* **Example Username**: `backuproy0911.salesexec@inventory.app.com`
* **Assigned Permission Set**: `Sales_Executive_Access`
* **Custom Permissions**: None (Restricted)

### Operational Focus
Sales Executives focus on sales order entry, customer communication, and return placement. They use the product catalog to verify stock levels before committing to deals. They are blocked from viewing suppliers, product cost rates, general inventory transactions, and total corporate profits. They only see and manage records (sales orders and return requests) that they own.
