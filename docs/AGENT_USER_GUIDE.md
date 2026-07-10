# Agent User Guide - Inventory Operations Agent

Welcome to your Inventory Operations Agent! This guide will help you understand how to interact with the agent, issue commands, and troubleshoot any runtime issues.

---

## 1. Overview of Capabilities

The agent can assist you in English with the following domains:
1. **Inventory**: Check product specifications, pricing, stock levels, and general inventory health summaries.
2. **Procurement**: Create purchase orders in draft status. (Draft status allows warehouse managers to review orders before finalizing).
3. **Sales**: Create sales orders in draft status and check product availability.
4. **Suppliers**: Search suppliers and retrieve vendor lead time and rating statistics.
5. **Returns (RMA)**: Update return requests and submit resolutions (Repairs, Replacements, Refunds).
6. **System Admin**: Request audit summaries and check custom object record counts.
7. **Analytics**: Review product sales leaderboards, revenue totals, profit margins, and supplier performance rankings.
8. **Alerts**: Ask for warning notifications about products that have dropped below their minimum stock levels.
9. **Images**: Request deletion of a product image file from the system.

---

## 2. Sample Conversations & Utterances

Here are some natural language commands you can try with the agent:

* **General**:
  * *"Hello"* -> Receives a greeting outlining the agent's capabilities.
* **Inventory Health**:
  * *"What is our overall inventory health?"* -> Returns active products count, low stock count, and out of stock count.
* **Product Detail**:
  * *"Show details for product a00g5000000xxxxx"* -> Returns category, SKU, stock level, unit cost, and price.
* **Procurement**:
  * *"Create a purchase order of 50 units for product a00g5000000xxxxx from supplier a01g5000000yyyyy at 15.00 each"* -> Returns the created Purchase Order ID.
* **Sales Orders**:
  * *"Create a sales order for Acme Corp for 10 units of product a00g5000000xxxxx at 25.00 each"* -> Returns the created Sales Order ID.
* **Supplier Performance**:
  * *"Show supplier performance ratings"* -> Displays a breakdown of vendor lead times, order accuracies, and ratings.
* **Low Stock Alerts**:
  * *"Do we have any low stock warnings?"* -> Lists products at or below their minimum stock level.
* **Product Performance**:
  * *"Show the product sales leaderboard"* -> Lists products sorted by revenue and profit margin.

---

## 3. Troubleshooting & Admin Tips

### 1. "Permissions Issue" or "Unable to Query"
If the agent reports that it cannot fetch data or encountered a permission error:
1. Ensure the `InventoryOperationsAgent_Access` permission set is assigned to the running Einstein Agent User.
2. Ensure the custom fields on the custom objects (like `Product__c`, `Supplier__c`, etc.) have Read/Write FLS enabled.

### 2. Updating the Agent Config
If you want to add new topics or modify instructions:
1. Deactivate the agent first:
   ```bash
   sf agent deactivate --api-name InventoryOperationsAgent -o admin
   ```
2. Edit the local `InventoryOperationsAgent.agent` file.
3. Validate and publish the agent:
   ```bash
   sf agent publish authoring-bundle --api-name InventoryOperationsAgent -o admin
   ```
4. Reactivate the agent:
   ```bash
   sf agent activate --api-name InventoryOperationsAgent -o admin
   ```
