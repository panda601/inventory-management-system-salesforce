# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-07-02
### Fixed
- Fixed Admin dashboard custom utility bar layout where it overlapped standard Salesforce global navigation.
- Configured sticky behavior for both utility bar and dashboard tabs so they stick cleanly below the standard navigation when scrolling.
- Resolved scroll overlaps and responsive collapse details on mobile view.

## [1.0.0] - 2026-06-12
### Added
- Created the **Inventory Management System (IMS)** Salesforce DX app.
- Configured Lightning Web Components (`inventoryCommandCenter`, `inventoryDashboard`, `returnManagementDashboard`, `productCatalog`, `productDetail`, etc.).
- Added Apex controllers, triggers, and comprehensive test coverage.
- Configured permission sets (`Admin_Access`, `Inventory_Manager_Access`, `Sales_Executive_Access`).
- Configured automated record-triggered flows for PO, SO, and Return processes.
