# Release Notes

## Version 1.0.1 (Current Release) — July 02, 2026

This release fixes critical layout, scroll overlap, and responsive bugs in the Admin dashboard workspace.

### Fixed
* **Admin Dashboard Overlap**: Fixed the custom utility bar (🔔 Notifications + Quick Actions) which previously overlapped with the standard Salesforce global navigation.
* **Sticky Navigation Hierarchy**: Implemented clean nested sticky layouts. Scrolling now sticks standard navigation, utility bar, and dashboard tab headers sequentially without hiding content.
* **Responsive Layout**: Ensured text labels collapse into icons on tablet/mobile views, preventing page-level horizontal scrollbars.
* **Opaque Backgrounds**: Set solid white backgrounds (`background: #ffffff`) on sticky elements so background content does not leak behind headers when scrolling.

---

## Version 1.0.0 (Initial Release) — June 12, 2026

The initial deployment of the **Inventory Management System (IMS)**, implementing core inventory database layers, flows, Apex tests, and custom LWC dashboards.

### Features
* **Role-Based Workspaces**: Multi-role LWC container resolving view structures for Admin, Inventory Manager, and Sales Executive.
* **Real-Time Data Refresh**: Dashboard wires integrated with Change Data Capture (CDC) platform events to automatically update counters.
* **Automated Transactions**: Record-triggered flows matching purchase order receiving and sales order confirmations to physical stock mutators.
* **Return/RMA Approvals**: Split workflow enabling Sales requests, Manager review, and Admin final approval.
* **Low Stock Alerts**: Automatic reorder warnings with suggested purchase quantities based on restock capacity.
