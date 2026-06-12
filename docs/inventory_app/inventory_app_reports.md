# Reports & Dashboards - Inventory Management System

This document specifies the reports, dashboards, and Lightning pages configured for the Inventory Management System.

---

## 1. Folders

*   **Reports Folder**: `Inventory_Management_Reports` (Label: "Inventory Management Reports")
*   **Dashboards Folder**: `Inventory_Dashboards` (Label: "Inventory Dashboards")

---

## 2. Standard & Custom Reports

All reports are stored in the `Inventory_Management_Reports` folder.

### Report 1: Product Inventory Report (`Product_Inventory_Report`)
*   **Report Type**: Products (`Product__c`)
*   **Columns**:
    *   Product Description (`Product_Name__c`)
    *   SKU (`SKU__c`)
    *   Current Stock (`Current_Stock__c`)
    *   Minimum Stock (`Minimum_Stock__c`)
    *   Status (`Status__c`)
*   **Grouping**: Grouped by Status (`Status__c`) and Product Description (`Product_Name__c`)
*   **Aggregates**: SUM of Current Stock (`Current_Stock__c`)

### Report 2: Low Stock Report (`Low_Stock_Report`)
*   **Report Type**: Products (`Product__c`)
*   **Columns**:
    *   Product Description (`Product_Name__c`)
    *   Current Stock (`Current_Stock__c`)
    *   Minimum Stock (`Minimum_Stock__c`)
*   **Filter**: Current Stock < Minimum Stock (`Current_Stock__c` < `Minimum_Stock__c`)
*   **Grouping**: Grouped by Product Description (`Product_Name__c`)

### Report 3: Purchase Order Report (`Purchase_Order_Report`)
*   **Report Type**: Purchase Orders (`Purchase_Order__c`)
*   **Columns**:
    *   PO Number (`PO_Number__c`)
    *   Supplier (`Supplier__c`)
    *   Status (`Status__c`)
    *   Order Date (`Order_Date__c`)
    *   Total Amount (`Total_Amount__c`)
*   **Grouping**: Grouped by Status (`Status__c`)
*   **Aggregates**: SUM of Total Amount (`Total_Amount__c`)

### Report 4: Inventory Transaction Report (`Inventory_Transaction_Report`)
*   **Report Type**: Inventory Transactions (`Inventory_Transaction__c`)
*   **Columns**:
    *   Product (`Product__c`)
    *   Transaction Type (`Transaction_Type__c`)
    *   Quantity (`Quantity__c`)
    *   Date (`Transaction_Date__c`)
*   **Grouping**: Grouped by Transaction Type (`Transaction_Type__c`)
*   **Aggregates**: SUM of Quantity (`Quantity__c`)

### Report 5: Sales Order Report (`Sales_Order_Report`)
*   **Report Type**: Sales Orders (`Sales_Order__c`)
*   **Columns**:
    *   Order Number (`Order_Number__c`)
    *   Customer Name (`Customer_Name__c`)
    *   Status (`Status__c`)
    *   Total Amount (`Total_Amount__c`)
*   **Grouping**: Grouped by Status (`Status__c`)
*   **Aggregates**: SUM of Total Amount (`Total_Amount__c`)

---

## 3. Inventory Manager Dashboard

*   **Dashboard Name**: `Inventory_Manager_Dashboard` (Label: "Inventory Manager Dashboard")
*   **Folder**: `Inventory_Dashboards`
*   **Running User**: `backuproy0911.invmgr@inventory.app.com`
*   **Components**:
    1.  **Total Products** (Metric): Record count of `Product_Inventory_Report`.
    2.  **Available Inventory** (Metric): Sum of Current Stock (`Current_Stock__c`) from `Product_Inventory_Report`.
    3.  **Low Stock Products** (Metric): Record count of `Low_Stock_Report`.
    4.  **Inventory Transactions** (Vertical Bar Chart): Sum of Quantity by Transaction Type from `Inventory_Transaction_Report`.
    5.  **Purchase Orders By Status** (Donut Chart): Sum of Total Amount by Status from `Purchase_Order_Report`.
    6.  **Sales Orders By Status** (Donut Chart): Sum of Total Amount by Status from `Sales_Order_Report`.
    7.  **Top Products By Stock** (Horizontal Bar Chart): Sum of Current Stock grouped by Product Description from `Product_Inventory_Report` (sorted descending).
    8.  **Low Stock Products** (Table): Table listing Product Description, Current Stock, and Minimum Stock from `Low_Stock_Report`.

---

## 4. Lightning Home Page

*   **Name**: `Inventory_Manager_Home_Page` (Label: "Inventory Manager Home Page")
*   **Template**: Standard Home Desktop Template (`runtime_alm_devops:homeDesktopTemplate`)
*   **Regions & Embedded Components**:
    *   **Header**: Standard Embedded Dashboard component (`desktopDashboards:embeddedDashboard`) displaying the `Inventory_Manager_Dashboard`.
    *   **Main**:
        *   Standard Assistant component (`home:assistant`) for alerts.
        *   Standard Filter List Card (`flexipage:filterListCard`) for `Purchase_Order__c` (ListView: `Purchase_Order`).
        *   Standard Filter List Card (`flexipage:filterListCard`) for `Sales_Order__c` (ListView: `Sales_order_List`).
    *   **Sidebar**: Left empty.

