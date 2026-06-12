# Project Tracker - Inventory Management System

This document tracks progress on the implementation of the Inventory Management System.

---

## Project Setup & Documentation
- [x] Create Project Directory structure (`inventory_app/`)
- [x] Initialize `README.md`
- [x] Initialize `USER_STORY.md`
- [x] Initialize `APPLICATION_ARCHITECTURE.md`
- [x] Initialize `OBJECT_MODEL.md`
- [x] Initialize `SECURITY_MODEL.md`
- [x] Initialize `AUTOMATION.md`
- [x] Initialize `REPORTS_DASHBOARDS.md`
- [x] Initialize `PROJECT_TRACKER.md`

---

## Phase-by-Phase Checklist

### [x] Phase 1: Foundation
- [x] Create Lightning App: **Inventory Management System**
- [x] Configure custom tabs for Products, Suppliers, Purchase Orders, PO Items, Sales Orders, Inventory Transactions, Reports, and Dashboards.
- [x] Create Roles:
  - `Inventory Manager`
  - `Sales Executive`
- [x] Create Users:
  - **Inventory Manager**: `backuproy0911@gmail.com`
  - **Sales Executive**: `backuproy0911@gmail.com`
- [x] Create Permission Sets:
  - `Inventory Manager Access`
  - `Sales Executive Access`
- [x] Deploy Phase 1 metadata to Target Org
- [x] Perform validation tests on users, roles, permission sets, and application tab visibility.

### [x] Phase 2: Data Model
- [x] Create Custom Objects:
  - `Product__c`
  - `Supplier__c`
  - `Purchase_Order__c`
  - `Purchase_Order_Item__c`
  - `Sales_Order__c`
  - `Inventory_Transaction__c`
- [x] Configure Custom Fields and Relationships:
  - Master-Detail relationship on `Purchase_Order_Item__c` pointing to `Purchase_Order__c`
  - Master-Detail relationship on `Inventory_Transaction__c` pointing to `Product__c`
  - Lookup relationships on all other designated references.
- [x] Deploy Phase 2 metadata to Target Org
- [x] Perform validation tests on schema configuration.

### [x] Phase 3: Security & Access Control
- [x] Set OWD for custom objects:
  - `Product__c` to **Public Read-Only**
  - `Supplier__c`, `Purchase_Order__c`, `Sales_Order__c`, `Inventory_Transaction__c` to **Private**
- [x] Assign profiles, roles, and permission sets to users:
  - Associate `Inventory Manager` user with the role and permission set.
  - Associate `Sales Executive` user with the role and permission set.
- [x] Deploy security metadata to Target Org
- [x] Perform validation tests for OWD, field accessibility, and sharing rules.

### [x] Phase 4: Automation
- [x] Create Flows:
  - `Purchase_Order_Received`
  - `Sales_Order_Confirmed`
  - `Low_Stock_Alert`
- [x] Create Validation Rules:
  - `VR_002_Quantity_Positive` on `Purchase_Order_Item__c`, `Sales_Order_Item__c`, `Inventory_Transaction__c`
  - `VR_003_Price_Positive` on `Product__c`, `Purchase_Order_Item__c`, `Sales_Order_Item__c`
  - `VR_004_Stock_Check` on `Sales_Order_Item__c`
- [x] Configure rollup summary fields:
  - `Purchase_Order__c.Total_Amount__c` summing `Purchase_Order_Item__c.Line_Total__c`
  - `Sales_Order__c.Total_Amount__c` summing `Sales_Order_Item__c.Line_Total__c`
- [x] Deploy and Retest Phase 4 automation

### [x] Phase 5: Reports & Dashboards
- [x] Create folders `Inventory_Management_Reports` and `Inventory_Dashboards`
- [x] Create 5 custom reports:
  - `Product_Inventory_Report`
  - `Low_Stock_Report`
  - `Purchase_Order_Report`
  - `Inventory_Transaction_Report`
  - `Sales_Order_Report`
- [x] Create `Inventory_Manager_Dashboard` with 8 components (Metrics, Charts, Table)
- [x] Create `Inventory_Manager_Home_Page` Lightning Home Page displaying dashboard and order lists
- [x] Deploy and Retest Phase 5 Reports & Dashboards

### [x] Phase 6: LWC Development
- [x] Create Apex Controllers (`ProductController`, `InventoryController`, `DashboardController`) with User Mode security enforcement
- [x] Create Lightning Message Channel `ProductSelected`
- [x] Create 7 custom Lightning Web Components (`inventoryDashboard`, `productCatalog`, `productDetail`, `inventoryMonitor`, `purchaseOrderDashboard`, `salesDashboard`, `recentTransactions`)
- [x] Grant Apex controller access in permission sets
- [x] Integrate components into `Inventory_Manager_Home_Page`
- [x] Deploy and perform E2E testing

### [x] Phase 7: System Audit, Security Fixes & E2E Testing
- [x] Verify full CRUD/FLS and tab visibilities in `Admin_Access`, `Inventory_Manager_Access`, and `Sales_Executive_Access` permission sets
- [x] Grant Inventory Manager create permission on `Inventory_Transaction__c`
- [x] Verify complete separation of the Inventory application from the Student app
- [x] Seed exact count of test data (5 Products, 3 Suppliers, 2 POs, 2 SOs, 5 Transactions)
- [x] Deploy all changes and run E2E scenarios and Security unit tests successfully
