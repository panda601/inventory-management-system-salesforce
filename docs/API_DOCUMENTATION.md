# Apex API Documentation

This document describes the signatures, input parameters, return values, and role-based permissions for endpoints exposed by the IMS Apex controllers.

---

## 1. `InventoryController`

Core provider for console utilities, role mappings, and return request processing.

### `getUserRole`
Resolves the calling user's custom role (Admin, Manager, or Sales) based on assigned permission sets.
* **Signature**:
  ```apex
  @AuraEnabled(cacheable=true)
  public static String getUserRole()
  ```
* **Returns**: `String` (`'Admin'`, `'Manager'`, or `'Sales'`).

### `getReturnRequests`
Returns list of return requests. Enforces private sharing visibility.
* **Signature**:
  ```apex
  @AuraEnabled(cacheable=true)
  public static List<Return_Request__c> getReturnRequests()
  ```
* **Returns**: `List<Return_Request__c>`.

### `processReturnRequest`
Advances return request status and triggers subsequent stock level mutations.
* **Signature**:
  ```apex
  @AuraEnabled
  public static void processReturnRequest(Id requestId, String nextStatus, String rejectionReason)
  ```
* **Parameters**:
  * `requestId`: `Id` (Return Request record ID)
  * `nextStatus`: `String` (New status value)
  * `rejectionReason`: `String` (Required if status is `Rejected`)
* **Security**: Enforces `Can_Process_Return` custom permission. Throws exception if access is denied.

---

## 2. `InventoryDashboardController`

Handles dashboard calculations, KPI counters, and profit/loss values.

### `getAdminDashboardSummary`
Aggregates quantities, pending counts, revenue totals, procurement costs, and profits.
* **Signature**:
  ```apex
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getAdminDashboardSummary()
  ```
* **Security**: Enforces `View_Profit_Metrics` custom permission before returning cost or profit calculations.
* **Returns**: `Map<String, Object>` containing KPI fields:
  * `totalProducts`: `Integer`
  * `availableInventory`: `Decimal`
  * `lowStock`: `Integer`
  * `revenue`: `Decimal`
  * `procurementCost`: `Decimal`
  * `profit`: `Decimal`
  * `profitMargin`: `Decimal`

### `getMonthlyPnLData`
Retrieves monthly aggregated trend data for ChartJS line/bar components.
* **Signature**:
  ```apex
  @AuraEnabled(cacheable=true)
  public static List<PnLDataWrapper> getMonthlyPnLData()
  ```
* **Returns**: `List<PnLDataWrapper>` representing monthly performance arrays.

---

## 3. `ProductController`

Handles catalog browsing and detail requests.

### `getProductList`
Returns a list of products.
* **Signature**:
  ```apex
  @AuraEnabled(cacheable=true)
  public static List<Product__c> getProductList(String searchKey, String statusFilter)
  ```
* **Parameters**:
  * `searchKey`: `String` (filters by Product Name or SKU)
  * `statusFilter`: `String` (filters by Status)
* **Returns**: `List<Product__c>`.
