# Security & Access Control Model

This document outlines the security configuration for the Student Application Management System.

---

## 1. Profiles & Roles

### Profiles
* **Standard Platform User**: Profile assigned to all system users.
* **System Administrator**: Full access to all objects, fields, apps, and records.

### Role Hierarchy
* **System Administrator**
  * **Admission_Manager** (Reports to: System Administrator)
    * **Admission_Executive** (Reports to: Admission_Manager)
    * **Document_Verifier** (Reports to: Admission_Manager)
    * **Finance_Officer** (Reports to: Admission_Manager)
    * **Student** (Reports to: Admission_Executive)

---

## 2. Organization-Wide Defaults (OWD)
Data visibility is restricted to enforce least privilege access.

| Object | Default Internal Access | Default External Access | Reason |
| :--- | :--- | :--- | :--- |
| `Course__c` | Public Read-Only | Public Read-Only | Anyone can view courses, but editing is restricted. |
| `Student_Application__c` | Private | Private | Applications contain sensitive student details. |
| `Document__c` | Controlled by Parent | Controlled by Parent | Master-Detail relationship with Student Application. |
| `Admission__c` | Private | Private | Admission details should only be visible to assigned staff. |
| `Payment__c` | Private | Private | Payments contain sensitive financial information. |

---

## 3. Permission Sets

### `Student_Access`
* **Course**: Read-Only access (Fewer fields editable, required fields readable)
* **Student Application**: Read, Create, Edit (Draft only via validation rules)
* **Document**: Read, Create, Edit (Pending verification only)
* **Payment**: Read-Only access
* **Admission**: No Access

### `Admission_Executive_Access`
* **Course**: Read-Only access
* **Student Application**: Read, Edit
* **Document**: Read, Edit
* **Payment**: Read-Only access
* **Admission**: Read, Create, Edit

### `Document_Verifier_Access`
* **Course**: Read-Only access
* **Student Application**: Read, Edit
* **Document**: Read, Edit (Verification Status, Rejection Reason)
* **Payment**: No Access
* **Admission**: No Access

### `Finance_Officer_Access`
* **Course**: Read-Only access
* **Student Application**: No Access
* **Document**: No Access
* **Payment**: Read, Create, Edit (Status updates on approved applications)
* **Admission**: No Access

### `Admission_Manager_Access`
* **Course**: Read-Only access
* **Student Application**: Read, Edit (Approve/Reject authority)
* **Document**: Read, Edit
* **Payment**: Read-Only access
* **Admission**: Read-Only access

---

## 4. Sharing Rules

To grant visibility outside the private defaults for specific business roles:

### `Student_Application__c` Sharing Rules
* Shared with **Admission_Executive** and **Document_Verifier** roles (Read/Write access).

### `Admission__c` Sharing Rules
* Shared with **Admission_Executive** and **Admission_Manager** roles (Read-only access).

### `Payment__c` Sharing Rules
* Shared with **Finance_Officer** role (Read/Write access).
* Shared with **Admission_Executive` and **Admission_Manager** roles (Read-only access).
