# Object Model - Inventory Management System (Phase 2 Data Model)

This document specifies the exact fields, API names, relationships, and validation criteria for all custom objects in the Inventory Management System.

---

## 1. Product (`Product__c`)
* **API Name**: `Product__c`
* **Label**: Product
* **Plural Label**: Products
* **Record Name Field**: Product Name (Text, Required)

### Custom Fields:
| Field Label | API Name | Data Type | Length / Precision | Required | Default / Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Product Description | `Product_Name__c` | Text | 255 | Yes | The name/description of the product. |
| SKU | `SKU__c` | Text (Unique, Case-Sensitive) | 50 | Yes | Unique Stock Keeping Unit. |
| Category | `Category__c` | Picklist | - | No | Product category (e.g. Electronics, Apparel, Food, Home, Other). |
| Price | `Price__c` | Currency | 16, 2 | Yes | The retail price of the product. |
| Current Stock | `Current_Stock__c` | Number | 18, 0 | Yes | Current quantity in stock (Default: 0). |
| Minimum Stock | `Minimum_Stock__c` | Number | 18, 0 | Yes | Minimum stock level before reorder warning (Default: 10). |
| Status | `Status__c` | Picklist | - | Yes | Status of the product (Active, Inactive). Default: Active. |

---

## 2. Supplier (`Supplier__c`)
* **API Name**: `Supplier__c`
* **Label**: Supplier
* **Plural Label**: Suppliers
* **Record Name Field**: Supplier Name (Text, Required)

### Custom Fields:
| Field Label | API Name | Data Type | Length / Precision | Required | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Supplier Company Name | `Supplier_Name__c` | Text | 255 | Yes | The company name of the supplier. |
| Email | `Email__c` | Email | - | No | Contact email for the supplier. |
| Phone | `Phone__c` | Phone | - | No | Contact phone number for the supplier. |
| Address | `Address__c` | Text | 255 | No | Physical/mailing address of the supplier. |
| Status | `Status__c` | Picklist | - | Yes | Operational status (Active, Inactive). Default: Active. |

---

## 3. Purchase Order (`Purchase_Order__c`)
* **API Name**: `Purchase_Order__c`
* **Label**: Purchase Order
* **Plural Label**: Purchase Orders
* **Record Name Field**: Purchase Order Number (Auto-Number: `PO-{00000}`)

### Custom Fields:
| Field Label | API Name | Data Type | Length / Precision | Required | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| PO Number | `PO_Number__c` | Auto Number | - | No | Auto-generated PO Number. |
| Supplier | `Supplier__c` | Lookup (`Supplier__c`) | - | Yes | The supplier for the PO. |
| Order Date | `Order_Date__c` | Date | - | Yes | Date the order was placed. |
| Status | `Status__c` | Picklist | - | Yes | PO Status (Draft, Approved, Received, Cancelled). Default: Draft. |
| Total Amount | `Total_Amount__c` | Roll-up Summary | - | No | SUM of Purchase Order Item Line Totals. |

---

## 4. Purchase Order Item (`Purchase_Order_Item__c`)
* **API Name**: `Purchase_Order_Item__c`
* **Label**: Purchase Order Item
* **Plural Label**: Purchase Order Items
* **Record Name Field**: PO Item Number (Auto-Number: `POI-{00000}`)

### Custom Fields:
| Field Label | API Name | Data Type | Length / Precision | Required | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Purchase Order | `Purchase_Order__c` | Master-Detail (`Purchase_Order__c`) | - | Yes | Parent Purchase Order. |
| Product | `Product__c` | Lookup (`Product__c`) | - | Yes | The product being ordered. |
| Quantity | `Quantity__c` | Number | 18, 0 | Yes | Quantity of the product ordered. |
| Unit Price | `Unit_Price__c` | Currency | 16, 2 | Yes | Unit cost for this specific item. |
| Line Total | `Line_Total__c` | Formula (Currency) | 16, 2 | No | Formula: `Quantity__c * Unit_Price__c`. |

---

## 5. Sales Order (`Sales_Order__c`)
* **API Name**: `Sales_Order__c`
* **Label**: Sales Order
* **Plural Label**: Sales Orders
* **Record Name Field**: Sales Order Number (Auto-Number: `SO-{00000}`)

### Custom Fields:
| Field Label | API Name | Data Type | Length / Precision | Required | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Order Number | `Order_Number__c` | Auto Number | - | No | Auto-generated Sales Order Number. |
| Customer Name | `Customer_Name__c` | Text | 255 | Yes | Customer's full name. |
| Order Date | `Order_Date__c` | Date | - | Yes | Date the sales order was created. |
| Status | `Status__c` | Picklist | - | Yes | Sales Order Status (Draft, Confirmed, Delivered, Cancelled). Default: Draft. |
| Total Amount | `Total_Amount__c` | Currency | 16, 2 | Yes | The total amount of the sales order. |

---

## 6. Inventory Transaction (`Inventory_Transaction__c`)
* **API Name**: `Inventory_Transaction__c`
* **Label**: Inventory Transaction
* **Plural Label**: Inventory Transactions
* **Record Name Field**: Transaction Number (Auto-Number: `TXN-{00000}`)

### Custom Fields:
| Field Label | API Name | Data Type | Length / Precision | Required | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Product | `Product__c` | Master-Detail (`Product__c`) | - | Yes | The product adjusted by this transaction. |
| Transaction Type | `Transaction_Type__c` | Picklist | - | Yes | Type of stock movement (Stock In, Stock Out, Adjustment). |
| Quantity | `Quantity__c` | Number | 18, 0 | Yes | Quantity of items moved. |
| Transaction Date | `Transaction_Date__c` | Date/Time | - | Yes | Date/time of the transaction. |
