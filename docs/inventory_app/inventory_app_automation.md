# Automation Model - Inventory Management System

This document specifies the validation rules, unique constraints, and record-triggered Flows that automate the business processes of the Inventory Management System.

---

## 1. Unique Constraints & Validation Rules

### SKU Uniqueness (VR-001)
*   **Enforcement**: Handled at the database level. The `SKU__c` field on `Product__c` is configured as a required, unique, case-sensitive text field.
*   **Behavior**: Blocks any duplicate SKU entries across the Product object.

### Quantity Validation (VR-002)
*   **Rule Name**: `VR_002_Quantity_Positive`
*   **Target Objects**: `Inventory_Transaction__c`, `Purchase_Order_Item__c`, `Sales_Order_Item__c`
*   **Formula**: `Quantity__c <= 0`
*   **Error Message**: "Quantity must be greater than zero."
*   **Display Location**: Field-level (Quantity)

### Price Validation (VR-003)
*   **Rule Name**: `VR_003_Price_Positive`
*   **Target Objects**: `Product__c` (on `Price__c`), `Purchase_Order_Item__c` (on `Unit_Price__c`), `Sales_Order_Item__c` (on `Unit_Price__c`)
*   **Formula**: `Price__c <= 0` / `Unit_Price__c <= 0`
*   **Error Message**: "Price must be greater than zero."
*   **Display Location**: Field-level (Price/Unit Price)

### Cannot Confirm Sales Order (VR-004)
*   **Rule Name**: `VR_004_Stock_Check`
*   **Target Object**: `Sales_Order_Item__c`
*   **Formula**: `ISPICKVAL(Sales_Order__r.Status__c, "Confirmed") && (Product__r.Current_Stock__c < Quantity__c)`
*   **Error Message**: "Insufficient Stock Available"
*   **Display Location**: Field-level (Quantity)

---

## 2. Rollup Summaries & Formulas (Flow 4 & Flow 5)

*   **Purchase Order Item Line Total**: Formula field `Line_Total__c` defined as `Quantity__c * Unit_Price__c`.
*   **Sales Order Item Line Total**: Formula field `Line_Total__c` defined as `Quantity__c * Unit_Price__c`.
*   **Purchase Order Total**: Roll-up Summary field `Total_Amount__c` on `Purchase_Order__c` calculating the SUM of `Purchase_Order_Item__c.Line_Total__c`.
*   **Sales Order Total**: Roll-up Summary field `Total_Amount__c` on `Sales_Order__c` calculating the SUM of `Sales_Order_Item__c.Line_Total__c`.

---

## 3. Record-Triggered Flows

### Flow 1: `Purchase_Order_Received`
*   **Trigger Object**: `Purchase_Order__c`
*   **Trigger Condition**: After Save, when `Status__c` transitions to `Received`.
*   **Process Steps**:
    1. Fetch all related `Purchase_Order_Item__c` records.
    2. Loop over each item:
        *   Retrieve the corresponding `Product__c` record.
        *   Increment `Product__c.Current_Stock__c` by `Purchase_Order_Item__c.Quantity__c`.
        *   Create an `Inventory_Transaction__c` record:
            *   `Product__c` = `Purchase_Order_Item__c.Product__c`
            *   `Quantity__c` = `Purchase_Order_Item__c.Quantity__c`
            *   `Transaction_Date__c` = `$Flow.CurrentDateTime`
            *   `Transaction_Type__c` = `'Stock In'`

### Flow 2: `Sales_Order_Confirmed`
*   **Trigger Object**: `Sales_Order__c`
*   **Trigger Condition**: After Save, when `Status__c` transitions to `Confirmed`.
*   **Process Steps**:
    1. Fetch all related `Sales_Order_Item__c` records.
    2. Loop over each item:
        *   Retrieve the corresponding `Product__c` record.
        *   Validate stock: If `Product__c.Current_Stock__c < Sales_Order_Item__c.Quantity__c`, throw Flow Custom Error: `"Insufficient Stock Available"`.
        *   If stock is sufficient, reduce `Product__c.Current_Stock__c` by `Sales_Order_Item__c.Quantity__c`.
        *   Create an `Inventory_Transaction__c` record:
            *   `Product__c` = `Sales_Order_Item__c.Product__c`
            *   `Quantity__c` = `Sales_Order_Item__c.Quantity__c`
            *   `Transaction_Date__c` = `$Flow.CurrentDateTime`
            *   `Transaction_Type__c` = `'Stock Out'`

### Flow 3: `Low_Stock_Alert`
*   **Trigger Object**: `Product__c`
*   **Trigger Condition**: After Save, when `Current_Stock__c` drops below `Minimum_Stock__c`.
*   **Process Steps**:
    1. Retrieve the Inventory Manager User record (Username: `backuproy0911.invmgr@inventory.app.com`).
    2. Create a high-priority `Task` assigned to the Inventory Manager:
        *   `Subject` = `"Low Stock Alert: " + Product__c.Name`
        *   `Priority` = `'High'`
        *   `Status` = `'Not Started'`
        *   `Description` = Detailed stock summary.
        *   `WhatId` = `Product__c.Id`
