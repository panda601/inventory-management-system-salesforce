# Security & Access Control Model - Inventory Management System

This document specifies the target security configuration, OWD sharing settings, role hierarchy, sharing rules, and permission sets for the Inventory Management System.

---

## 1. Organization-Wide Defaults (OWD)

| Object | API Name | Default Internal Access | Default External Access | Reason |
| :--- | :--- | :--- | :--- | :--- |
| **Product** | `Product__c` | **Public Read-Only** | Public Read-Only | Sales Executives must view products but cannot modify them. |
| **Supplier** | `Supplier__c` | **Private** | Private | Restrict supplier contact information. |
| **Purchase Order** | `Purchase_Order__c` | **Private** | Private | Procurement information must be private. |
| **Purchase Order Item** | `Purchase_Order_Item__c` | **Controlled by Parent** | Controlled by Parent | Master-Detail relationship. |
| **Sales Order** | `Sales_Order__c` | **Private** | Private | Sales orders must be private to owner/sales executive. |
| **Inventory Transaction** | `Inventory_Transaction__c` | **Private** | Private | Private ledger of stock adjustments. |

---

## 2. Role Hierarchy

```
System Administrator
 └── Inventory Manager Role
      └── Sales Executive Role
```

* **Inventory Manager Role**: Users in this role oversee warehouse operations, supplier relations, and PO placement.
* **Sales Executive Role**: Users in this role create Sales Orders.

---

## 3. Permission Sets & Access Matrix

### Permission Set 1: `Inventory_Manager_Access`
* **Object Permissions**:
  * `Product__c`: Read, Create, Edit (View All/Modify All)
  * `Supplier__c`: Read, Create, Edit (View All/Modify All)
  * `Purchase_Order__c`: Read, Create, Edit (View All/Modify All)
  * `Purchase_Order_Item__c`: Read, Create, Edit (View All/Modify All)
  * `Inventory_Transaction__c`: Read, Create, Edit (View All/Modify All)
* **Field-Level Security**:
  * Read/Write on `Product__c.Category__c`, `Supplier__c.Address__c`, `Supplier__c.Email__c`, `Supplier__c.Phone__c`.
  * Read-only on `Purchase_Order__c.PO_Number__c`, `Purchase_Order__c.Total_Amount__c`, `Purchase_Order_Item__c.Line_Total__c`.

### Permission Set 2: `Sales_Executive_Access`
* **Object Permissions**:
  * `Product__c`: Read
  * `Sales_Order__c`: Read, Create, Edit
* **Field-Level Security**:
  * Read-only on `Product__c.Category__c` and `Sales_Order__c.Order_Number__c`.

---

## 4. Sharing & Visibility Rules

* **Inventory Manager**:
  * Inherits access to all Sales Executive records via Role Hierarchy.
  * Can view all Products, Suppliers, Purchase Orders, and Inventory Transactions via "View All" permissions in `Inventory_Manager_Access`.
* **Sales Executive**:
  * Can view Products (Public Read-Only OWD).
  * Can view own Sales Orders (Private OWD).
  * Has no access to Suppliers, Purchase Orders, or Inventory Transactions.
