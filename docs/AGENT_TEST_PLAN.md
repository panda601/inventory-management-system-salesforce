# Agent Test Plan - Inventory Operations Agent

This document defines the testing strategy, test classes, and manual verification protocols for validating the Inventory Operations Agent and its actions.

## 1. Local Validation

Before deploying or publishing, local syntax and semantic checks are performed using the Salesforce CLI:
```bash
sf agent validate authoring-bundle --api-name InventoryOperationsAgent -o admin
```
This verifies:
- Agent script syntax correctness.
- Topic transitions and links.
- Correct references to target Invocable Apex classes.

---

## 2. Automated Apex Unit Tests

The test class `IMS_AgentActionsTest` is used to verify all 10 invocable Apex actions. It mocks the database state, runs all actions synchronously, and asserts correct responses and data processing.

### Run Automated Tests
Execute the test class via Salesforce CLI:
```bash
sf apex run test --class-names IMS_AgentActionsTest -o admin --wait 10
```

---

## 3. Live Preview & Smoke Testing

To test the agent's natural language understanding, topic classification, and actual Apex execution in the org, use the `agent preview` commands.

### Step 1: Start Preview Session
Start a session using live actions:
```bash
sf agent preview start --api-name InventoryOperationsAgent -o admin --use-live-actions --json
```
*Note the returned `sessionId`.*

### Step 2: Test Scenarios

#### Scenario A: Master Greeting & Router
* **Input**: `"hello"`
* **Expected Output**: Greeting response summarizing capabilities (inventory, sales, procurement, returns, analytics).

#### Scenario B: System Health Audit
* **Input**: `"How is the health of the system?"`
* **Expected Output**: A count summary of active products, total suppliers, pending POs, pending SOs, and pending returns.

#### Scenario C: Stock Alert Scan
* **Input**: `"Show me the low stock alerts."`
* **Expected Output**: A list of products at or below their minimum stock thresholds (e.g. Dell Keyboard).

#### Scenario D: Product Sales Leaderboard
* **Input**: `"Show product performance leaderboard"`
* **Expected Output**: A detailed leaderboard of products, displaying revenue, quantity sold, profit, and margin.

#### Scenario E: Supplier Performance Ratings
* **Input**: `"Check supplier performance ratings"`
* **Expected Output**: Performance stats (average delivery time, accuracy, late deliveries, rating) for all suppliers.

### Step 3: End Preview Session
```bash
sf agent preview end --api-name InventoryOperationsAgent --session-id <session_id> -o admin --json
```
