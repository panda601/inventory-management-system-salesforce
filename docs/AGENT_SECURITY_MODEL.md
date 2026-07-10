# Agent Security Model - Inventory Operations Agent

This document outlines the security architecture, license requirements, and access controls built around the Inventory Operations Agent.

## 1. Einstein Agent User License & Boundaries

The Einstein Agent User runs under a restricted Salesforce license (`PID_DigitalAgent`). This license restricts typical standard user permissions (such as report creation, application views, standard dashboards) but allows API access and execution of custom business logic.

Due to this boundary:
- Standard permission sets containing restricted user permissions (e.g., `Admin_Access`) cannot be directly assigned.
- Access must be explicitly granted via custom permission sets that are compatible with the Einstein Agent User's license.

---

## 2. Custom Permission Set Design

The custom permission set `InventoryOperationsAgent_Access` provides the agent user with all permissions required to execute the invocable Apex classes and query the CRM objects safely.

### Class Execution Permissions
Grants access to execute the following invocable classes:
- `IMS_GetProductDetail`
- `IMS_GetInventoryHealth`
- `IMS_CreatePurchaseOrder`
- `IMS_CreateSalesOrder`
- `IMS_ProcessReturnRequest`
- `IMS_GetSupplierPerformance`
- `IMS_GetProductPerformance`
- `IMS_GetLowStockAlerts`
- `IMS_DeleteProductImage`
- `IMS_GetSystemHealth`

### Custom Object CRUD Permissions
Grants full access to query and write records on all custom objects:
* **Product (`Product__c`)**: Read, Create, Edit, Delete, View All, Modify All
* **Supplier (`Supplier__c`)**: Read, Create, Edit, Delete, View All, Modify All
* **Purchase Order (`Purchase_Order__c`)**: Read, Create, Edit, Delete, View All, Modify All
* **Purchase Order Item (`Purchase_Order_Item__c`)**: Read, Create, Edit, Delete
* **Sales Order (`Sales_Order__c`)**: Read, Create, Edit, Delete, View All, Modify All
* **Sales Order Item (`Sales_Order_Item__c`)**: Read, Create, Edit, Delete
* **Inventory Transaction (`Inventory_Transaction__c`)**: Read, Create, Edit, Delete, View All, Modify All
* **Return Request (`Return_Request__c`)**: Read, Create, Edit, Delete, View All, Modify All
* **Inventory Audit Log (`Inventory_Audit_Log__c`)**: Read, Create, Edit, Delete, View All, Modify All

### Field-Level Security (FLS)
Grants access to all custom fields (e.g., `Category__c`, `Total_Amount__c`, `Stock_On_Hand__c`, `RMA_Number__c`, `Resolution_Type__c`, etc.), ensuring the agent's database queries run compile-clean and return all required properties.

---

## 3. Data Sharing & Role Hierarchy

- **With Sharing**: The Apex actions are declared `with sharing` where appropriate to respect Salesforce sharing rules.
- **Organization-Wide Defaults (OWD)**: The agent respects the organization-wide sharing defaults of the custom objects.
- **Role Hierarchy**: The agent inherits record-level access based on the Einstein Agent User's role assignment in the hierarchy.
- **Validation Rules**: All automated transactions (e.g., Sales Order creation) respect existing system validations (such as `VR_004_Stock_Check` and `VR_002_Quantity_Positive`). If a validation rule fails, the Apex action catches the DML exception and returns an informative error message back to the agent.
