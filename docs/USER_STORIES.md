# User Stories

This document lists the user stories that guide the design and development of the Inventory Management System.

## Admin User Stories

* **US-101: Real-Time Financial Dashboard**
  * *As an* Admin,
  * *I want to* see real-time revenue, cost, profit, and margin summaries on a clean dashboard,
  * *So that* I can monitor high-level business performance without waiting for end-of-month accounting runs.

* **US-102: Refund Decision Approvals**
  * *As an* Admin,
  * *I want to* review returns marked for refund and issue final approvals,
  * *So that* I can prevent unauthorized cash outflows while maintaining customer satisfaction.

## Inventory Manager User Stories

* **US-201: Inbound Stock Receiving**
  * *As an* Inventory Manager,
  * *I want to* mark incoming purchase orders as `Received`,
  * *So that* the system automatically increments product stock levels and logs a stock-in ledger record.

* **US-202: Low Stock Alerts**
  * *As an* Inventory Manager,
  * *I want to* receive real-time dashboard notifications when a product's current stock falls below its minimum threshold,
  * *So that* I can place restock purchase orders before stock starvation occurs.

* **US-203: Return Request Initial Review**
  * *As an* Inventory Manager,
  * *I want to* review return requests submitted by sales representatives,
  * *So that* I can inspect the returned items and advance the request to `Under Review` or `Rejected`.

## Sales Executive User Stories

* **US-301: Product Catalog Browsing**
  * *As a* Sales Executive,
  * *I want to* browse the product catalog and inspect real-time available stock levels,
  * *So that* I can make accurate commitments to customers.

* **US-302: Order Placement Verification**
  * *As a* Sales Executive,
  * *I want to* be blocked from saving sales orders that exceed a product's available stock,
  * *So that* we avoid stock starvation and unfulfilled order backlogs.

* **US-303: Return Request Intake**
  * *As a* Sales Executive,
  * *I want to* log return requests for damaged or unwanted products and track their progress through my own returns dashboard tab,
  * *So that* I can keep customers informed of replacement shipments or refund processing.
