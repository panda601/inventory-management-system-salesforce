# Project Overview - Inventory Management System (IMS)

## Executive Summary
The **Inventory Management System (IMS)** is a professional-grade, custom enterprise solution built natively on the Salesforce platform. It is designed to handle modern multi-role inventory operations, procurement cycles, sales pipelines, and return workflows. The app bridges the gap between sales activity and warehousing operations by providing real-time synchronization, validation controls, and persona-driven dashboard experiences.

## Business Problem
Many medium-to-large distribution and manufacturing enterprises face operational friction due to disconnected silos between sales representatives and inventory/procurement managers:
1. **Inventory Blindness**: Sales Executives confirm orders without real-time stock status, leading to stock starvation, delayed fulfillment, and dissatisfied customers.
2. **Lagging Metrics**: Executives and inventory admins rely on end-of-month reporting rather than real-time dashboards to analyze revenue, procurement costs, and profits.
3. **Broken Return Workflows**: Product returns (RMA processes) lack automated handoffs, leading to slow processing times, stock level mismatches, and incorrect adjustment ledgers.
4. **Security Vulnerabilities**: Unauthorized roles gaining access to cost rates, financial summaries, or supplier contract details.
5. **Lack of Visual Catalog Context**: Absence of product images in standard listings makes product identification slower and more prone to warehouse errors.

## Technical Solution
IMS addresses these challenges by introducing a native Salesforce application combining:
* **Interactive Lightning Web Components (LWC)**: A unified role-based command center with responsive charts and tables for three target personas (Admin, Inventory Manager, Sales Executive). Includes a custom Supplier Detail override dashboard and dynamic Product Catalog/Detail views.
* **Native Product Image Management**: An admin-only uploader component (`productImageUploader`) leveraging Salesforce Files (`ContentVersion` and `ContentDocumentLink`) to upload, replace, and delete product images, while enforcing read-only visibility for managers and sales executives.
* **Automated Apex Controllers**: Bulk-safe controllers optimized for fast querying, real-time transaction logging, and role-based permissions. Dynamically resolves Salesforce File download URLs (`/sfc/servlet.shepherd/version/download/{ContentVersionId}`) in-memory for dynamic LWC image rendering with error fallback safety.
* **Automated Low-Code Flow Builders**: Orchestrates inbound procurement and return adjustments, ensuring that inventory ledgers mutate automatically with zero manual entry errors.
* **Granular Permission Sets & Sharing Rules**: Restricts access to sensitive financial metrics (like profit/loss data), supplier records, and media management controls strictly to authorized roles.
* **Einstein Agentforce AI Operations Layer**: A production-ready, multi-agent AI assistant ("Inventory Operations Agent") following a central hub-and-spoke pattern. It dynamically routes natural language user requests to 9 specialized spoke topics (Inventory, Purchase, Sales, Supplier, Return, Admin, Analytics, Notification, and Product Image) backed by 10 secure, invocable Apex actions to perform live CRM audits, transaction creation, and analytical leaderboards.

