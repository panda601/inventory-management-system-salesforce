# Security Model & Access Control

This document describes the security model, sharing rules, and custom permission settings implemented in the Inventory Management System.

## Persona Permissions Summary

Access to custom objects, fields, and dashboard actions is tightly restricted using Salesforce **Permission Sets**.

| Salesforce Object / Field | Admin_Access | Inventory_Manager_Access | Sales_Executive_Access |
| :--- | :--- | :--- | :--- |
| **Product__c** | Read / Write | Read / Write | Read Only |
| **Product__c.Cost__c** | Read / Write | Read / Write | **No Access** (Hidden) |
| **Supplier__c** | Read / Write | Read / Write | **No Access** (Hidden) |
| **Purchase_Order__c** | Read / Write | Read / Write | **No Access** (Hidden) |
| **Sales_Order__c** | Read / Write | Read / Write | Read / Write |
| **Inventory_Transaction__c**| Read / Write | Read / Write | **No Access** (Hidden) |
| **Return_Request__c** | Read / Write | Read / Write | Read / Write (Own Only) |

## Custom Permissions & Application Controls

In addition to standard object-level and field-level security, we enforce granular logical execution barriers using **Custom Permissions**:

### 1. `Can_Process_Return`
* **Assigned To**: Admins and Inventory Managers.
* **Control**: Guards return state transitions (e.g. moving a return to `Under Review` or approving/rejecting it). If a Sales Executive attempts to call the Apex endpoint to process a return, the controller throws an `AuraHandledException` with a security violation.

### 2. `Can_Approve_Refund`
* **Assigned To**: Admins only.
* **Control**: Restricts final financial refund operations. Only users with this permission can move a return request to `Refunded`.

### 3. `View_Profit_Metrics`
* **Assigned To**: Admins only.
* **Control**: Controls visibility of revenue, cost, profit, and margin summaries on dashboards and reports. Apex controllers block data aggregation queries if the calling user lacks this permission.

## Sharing Settings & Record-Level Visibility

* **Organization-Wide Defaults (OWD)**:
  * `Return_Request__c` is configured as **Private**.
  * `Sales_Order__c` is configured as **Private**.
* **Sharing Rules**:
  * An owner-based sharing rule grants **Inventory Managers** read/write access to all returns in `Submitted` status so they can conduct initial reviews.
  * **Sales Executives** can only see return requests and sales orders that they own (`OwnerId = $User.Id`), preventing cross-sales representative visibility of customer interactions and return rates.
