# PERSONAS.md

# Inventory Management System

## Project Overview

The Inventory Management System helps organizations manage products, suppliers, procurement, sales, inventory movements, reports, and dashboards through role-based access.

---

# Persona 1: System Administrator

## Name

Rahul Roy

## Role

System Administrator

## Goals

* Configure and maintain the application
* Manage users and permissions
* Monitor business operations
* Ensure data security
* Access all reports and dashboards

## Responsibilities

* Create users
* Assign roles
* Assign permission sets
* Configure security
* Monitor system health
* Manage reports and dashboards

## Objects Accessible

✓ Product__c

✓ Supplier__c

✓ Purchase_Order__c

✓ Purchase_Order_Item__c

✓ Sales_Order__c

✓ Inventory_Transaction__c

✓ Reports

✓ Dashboards

✓ Sales_Order_Item__c

## Permissions

Read

Create

Edit

Delete

View All

Modify All

## Dashboard Experience

Inventory Command Center

* Total Products
* Available Stock
* Low Stock Products
* Out Of Stock Products
* Purchase Orders
* Sales Orders
* Inventory Health Score
* Supplier Performance Score
* Monthly Inventory Trend
* Recent Transactions
* Top Selling Products

## Pain Points Solved

* No manual tracking
* Real-time visibility
* Centralized management
* Security and governance

---

# Persona 2: Inventory Manager

## Name

Amit Sharma

## Role

Inventory Manager

User:

[backuproy0911.invmgr@inventory.app.com](mailto:backuproy0911.invmgr@inventory.app.com)

## Goals

* Manage products and suppliers
* Procure inventory
* Monitor stock levels
* Prevent stock shortages
* Track inventory movement

## Responsibilities

* Create products
* Create suppliers
* Create purchase orders
* Receive inventory
* Monitor stock health
* Initiate reorders

## Objects Accessible

✓ Product__c

✓ Supplier__c

✓ Purchase_Order__c

✓ Purchase_Order_Item__c

✓ Inventory_Transaction__c

Read Only:

✓ Sales_Order__c

## Permissions

Read

Create

Edit

Delete

View All

## Dashboard Experience

Inventory Command Center

Sections:

* Inventory KPI Dashboard
* Low Stock Alert Panel
* Reorder Recommendation
* Inventory Health Score
* Purchase Order Dashboard
* Recent Transactions
* Supplier Performance Score
* Monthly Inventory Trend

## Daily Workflow

Login
↓
Check Inventory Dashboard
↓
Review Low Stock Alerts
↓
Create Purchase Orders
↓
Receive Inventory
↓
Verify Inventory Transactions
↓
Review Reports

## Pain Points Solved

* No stock shortages
* Automated inventory updates
* Easy procurement process
* Inventory analytics

---

# Persona 3: Sales Executive

## Name

Priya Verma

## Role

Sales Executive

User:

[backuproy0911.salesexec@inventory.app.com](mailto:backuproy0911.salesexec@inventory.app.com)

## Goals

* View product catalog
* Check stock availability
* Process customer orders
* Track sales performance

## Responsibilities

* Search products
* Create sales orders
* Create sales order items
* Monitor order status

## Objects Accessible

Read Only:

✓ Product__c

✓ Supplier__c

Full Access:

✓ Sales_Order__c

✓ Sales_Order_Item__c

Read Only:

✓ Inventory_Transaction__c

No Access:

✗ Purchase_Order__c

✗ Purchase_Order_Item__c

## Permissions

Read

Create

Edit

Own Records Only

## Dashboard Experience

Sales Command Center

Sections:

* Product Catalog
* Sales Dashboard
* Top Selling Products
* Recent Orders
* Product Search
* Revenue Metrics

## Daily Workflow

Login
↓
Open Product Catalog
↓
Check Stock Availability
↓
Create Sales Order
↓
Add Products
↓
Confirm Order
↓
Track Order Status

## Pain Points Solved

* Real-time stock visibility
* Faster order processing
* Reduced manual communication
* Better customer service

---

# Business Collaboration Flow

Inventory Manager
↓
Creates Products
↓
Creates Suppliers
↓
Creates Purchase Orders
↓
Receives Inventory
↓
Stock Updated
↓
Sales Executive
↓
Views Products
↓
Creates Sales Orders
↓
Inventory Reduced
↓
Admin Monitors Entire Process

---

# Security Model

System Administrator

Can access everything.

Inventory Manager

Can manage inventory operations.

Sales Executive

Can manage customer sales operations only.

Data visibility is controlled through:

* Role Hierarchy
* Permission Sets
* OWD
* Sharing Rules

---

# Business Outcome

✓ Centralized Inventory Management

✓ Real-Time Inventory Tracking

✓ Automated Procurement Process

✓ Controlled Sales Process

✓ Role-Based Security

✓ Analytics and Dashboards

✓ Production-Ready Salesforce Application
