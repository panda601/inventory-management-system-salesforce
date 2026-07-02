# Deployment & Setup Guide

This document describes how to deploy and configure the **Inventory Management System (IMS)** in a Salesforce Scratch Org, Sandbox, or Developer Edition.

---

## Prerequisites

1. Install **Salesforce CLI (sf)**:
   ```bash
   npm install -g @salesforce/cli
   ```
2. Install **Visual Studio Code** and the **Salesforce Extension Pack**.
3. Install **Node.js** (v18 or higher recommended) and run package installs:
   ```bash
   npm install
   ```

---

## Step-by-Step Deployment

### 1. Authenticate with your Target Org
Authenticate with your Salesforce scratch org, sandbox, or developer edition:
```bash
sf org login web --alias my-target-org --set-default
```

### 2. Deploy Metadata
Deploy the root `force-app` metadata folder containing the custom objects, fields, classes, triggers, and Lightning Web Components:
```bash
sf project deploy start --source-dir force-app --target-org my-target-org
```

### 3. Assign Permission Sets
Assign the correct persona permission set to your deployment user (e.g. Admin access):
```bash
sf org assign permset --name Admin_Access --target-org my-target-org
```
For other roles, assign `Inventory_Manager_Access` or `Sales_Executive_Access` as needed:
```bash
sf org assign permset --name Inventory_Manager_Access --target-org my-target-org
sf org assign permset --name Sales_Executive_Access --target-org my-target-org
```

### 4. Import / Seed Sample Data
Execute the anonymous Apex seed script to create initial active products, suppliers, purchase orders, sales orders, and return requests:
```bash
sf apex run --file scripts/apex/seed_and_verify_e2e.apex --target-org my-target-org
```

### 5. Verify the Installation
Run the Apex unit test suite to ensure that all database rules and Apex controllers are compiled and fully functional:
```bash
sf apex run test --test-level RunLocalTests --wait 10 --target-org my-target-org
```

---

## post-deploy Configuration & Sharing

1. **Activate Change Data Capture (CDC)**:
   * Go to **Setup** -> **Change Data Capture**.
   * Add the following custom objects to the Selected Entities list:
     * `Product__c`
     * `Return_Request__c`
     * `Inventory_Transaction__c`
     * `Sales_Order__c`
     * `Purchase_Order__c`
   * Click **Save**. This ensures LWC dashboard widgets refresh in real-time.
2. **Assign Layouts and App Access**:
   * Add the **Inventory Command Center** LWC component tab to the standard Salesforce Lightning navigation or home layout.
   * Make sure users have permission to access the `Inventory Management System` App through App Manager.
