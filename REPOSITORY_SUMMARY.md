# Repository Summary - standalone Portfolio Release

This repository has been fully restructured and documented to serve as a high-quality portfolio demonstration of an **Inventory Management System (IMS)** built on the Salesforce platform.

## Key Portfolio Highlights

1. **Custom LWC Console Architecture**:
   * Unified, responsive parent shell (`inventoryCommandCenter`) dynamically checking user roles and building workspaces for three personas (Admin, Manager, Sales).
   * Visual ChartJS metrics graphs, product status alerts, interactive tables, and an approval action center.
   * Sticky custom headers and tab navigation layout (fixed in v1.0.1) aligned with the Salesforce Lightning global design.
2. **Bulk-Safe Apex Backend**:
   * Specialized, cacheable, and secured Apex controllers (`WITH USER_MODE`) optimized for high-velocity queries.
   * Fully automated stock-receiving triggers and return request processing logic.
3. **Reactive Low-Code Flows**:
   * Declarative flows automatically logging stock transactions upon purchase order receiving or sales order confirmations.
   * Return approval workflows handling repairs (stock-in + inspection status), replacements (stock out shipment), and refunds (financial updates only).
4. **Tightened Security Model**:
   * Object and field-level permissions enforced via Profile Permission Sets.
   * Security constraints restricting pricing rates and supplier directories from Sales Executives.
   * Granular Custom Permissions (`Can_Process_Return`, `Can_Approve_Refund`, `View_Profit_Metrics`) protecting endpoint execution.
5. **Real-Time UI Updates**:
   * Integrates Change Data Capture (CDC) platform events directly with LWC event subscriptions, refreshing UI components automatically on database updates.

## Repository Contents

* [force-app/](file:///d:/SF%20Project/force-app): Core Salesforce DX metadata (Custom Objects, Fields, LWC, Apex, Flows, and Permission Sets).
* [docs/](file:///d:/SF%20Project/docs): Comprehensive documentation including:
  * [Project Overview](file:///d:/SF%20Project/docs/PROJECT_OVERVIEW.md)
  * [System Architecture](file:///d:/SF%20Project/docs/SYSTEM_ARCHITECTURE.md)
  * [Application Architecture](file:///d:/SF%20Project/docs/APPLICATION_ARCHITECTURE.md)
  * [Database Schema](file:///d:/SF%20Project/docs/DATABASE_SCHEMA.md)
  * [Security Model](file:///d:/SF%20Project/docs/SECURITY_MODEL.md)
  * [Deployment Guide](file:///d:/SF%20Project/docs/DEPLOYMENT_GUIDE.md)
  * [Apex API Documentation](file:///d:/SF%20Project/docs/API_DOCUMENTATION.md)
  * [Test Report](file:///d:/SF%20Project/docs/TEST_REPORT.md)
  * [Manual Test Plan](file:///d:/SF%20Project/docs/MANUAL_TEST_PLAN.md)
  * [Release Notes](file:///d:/SF%20Project/docs/RELEASE_NOTES.md)
  * [Limitations & Scaling Roadmap](file:///d:/SF%20Project/docs/KNOWN_LIMITATIONS.md)
* [diagrams/](file:///d:/SF%20Project/diagrams): Mermaid source files diagramming system components, ERD, and flow cycles.
* [screenshots/](file:///d:/SF%20Project/screenshots): Premium visual mockups of system dashboards and layouts.
* [scripts/](file:///d:/SF%20Project/scripts): Data seeding and post-deploy anonymous Apex smoke testing scripts.
