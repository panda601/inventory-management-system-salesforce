# Manual Test Plan

This document outlines the visual layout, responsiveness, and functional scenarios to manually verify in the Inventory Management System.

---

## Section 1: Dashboard Sticky Layout (Recent Fix)

These tests verify that the custom header and tab layout remain sticky and do not overlap with standard Salesforce navigation.

### TC-101: Desktop Sticky Behavior
* **Persona**: Admin / Manager / Sales Executive
* **Viewport**: Desktop (1200px and above)
* **Steps**:
  1. Open the **Inventory Command Center** tab.
  2. Vertically scroll down a long dashboard layout (e.g. Profit & Loss or Metric lists).
* **Expected Result**:
  * The Salesforce standard header and app navigation remain normal.
  * The custom utility bar (bell icon and quick actions menu) sticks immediately below the Salesforce navigation.
  * The tab headers (e.g., Dashboard, Products, returns) stick immediately below the utility bar.
  * No content overlaps or slides underneath the utility bar; it scrolls behind the tab headers cleanly.

### TC-102: Mobile Sticky Layout & Responsiveness
* **Persona**: Admin
* **Viewport**: Mobile (768px and below)
* **Steps**:
  1. Shrink viewport to mobile width.
  2. Verify utility bar labels are collapsed.
  3. Scroll down.
* **Expected Result**:
  * Text labels ("Notifications", "Quick Actions") disappear, and only the icons remain visible.
  * The collapsed header sticks correctly at `top: 50px;` and tabs stick at `top: 100px;`.
  * Buttons and dropdown triggers remain fully clickable.

---

## Section 2: Functional Workflows

### TC-201: Stock Starvation Validation (VR_004)
* **Persona**: Sales Executive
* **Steps**:
  1. Identify a product with 5 units remaining in stock.
  2. Create a Sales Order. Add a Sales Order Item for 6 units of the product.
  3. Save the Sales Order Item, then attempt to set the Sales Order status to `Confirmed`.
* **Expected Result**:
  * The system displays validation rule error `VR_004`: "Insufficient stock to confirm this order."
  * Order status remains unconverted, preventing stock levels from falling below zero.

### TC-202: End-to-End RMA Approvals
* **Step 1 (Sales Executive)**:
  * Log return request (RMA) for a sales order item. Reason: "Damaged". Resolution: "Replacement". Save.
  * *Expected*: Status defaults to `Submitted`. Request remains visible on Sales dashboard.
* **Step 2 (Inventory Manager)**:
  * Open the Return Request. Click `Process` and set status to `Under Review`.
  * *Expected*: Status updates, manager notification logs, record is forwarded to Admin.
* **Step 3 (Admin)**:
  * Navigate to **Approval Center** LWC. Open the RMA. Select `Approve Replacement`.
  * *Expected*: Status becomes `Replacement Sent`. A 'Stock Out' Inventory Transaction is generated automatically. Product stock level is reduced by return quantity.
