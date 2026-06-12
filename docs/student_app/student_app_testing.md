# Manual Testing & User Acceptance Testing (UAT) Workflow

This document provides a comprehensive, persona-driven guide for manually testing the features, security configurations, and automations of the **Student Application Management System**. Use this guide to simulate E2E user journeys across different roles.

---

## 👥 Persona Matrix & Credentials

Before initiating manual testing, verify that the following test users exist in the target org `StudentAppOrg` and have the specified configurations:

| Role | Test Username | Profile | Assigned Permission Sets |
| :--- | :--- | :--- | :--- |
| **System Administrator** | `723145roy.6036123142ec@agentforce.com` | System Administrator | *All System Permissions* |
| **Student** | `723145rroy@gmail.com.studentapp` | Standard Platform User | [Student_Access](file:///d:/SF%20Project/student_app/force-app/main/default/permissionsets/Student_Access.permissionset-meta.xml) |
| **Admission Manager** | `backuproy0911.admgr@student.app.com` | Standard Platform User | [Admission_Manager_Access](file:///d:/SF%20Project/student_app/force-app/main/default/permissionsets/Admission_Manager_Access.permissionset-meta.xml) |
| **Admission Executive** | `royayansh0039.exec@student.app.com` | Standard Platform User | [Admission_Executive_Access](file:///d:/SF%20Project/student_app/force-app/main/default/permissionsets/Admission_Executive_Access.permissionset-meta.xml) |
| **Document Verifier** | *Create test verifier user if needed* | Standard Platform User | [Document_Verifier_Access](file:///d:/SF%20Project/student_app/force-app/main/default/permissionsets/Document_Verifier_Access.permissionset-meta.xml) |
| **Finance Officer** | *Create test finance user if needed* | Standard Platform User | [Finance_Officer_Access](file:///d:/SF%20Project/student_app/force-app/main/default/permissionsets/Finance_Officer_Access.permissionset-meta.xml) |

> [!IMPORTANT]
> Universally required fields like `First_Name__c`, `Last_Name__c`, `Email__c`, `Date_of_Birth__c`, and `Applied_Course__c` on `Student_Application__c` are **automatically accessible** (read/write) to all users who have access to the object. They do not require explicit FLS declarations in permission sets.

---

## 🚀 E2E Use Cases & Scenarios

### Use Case A: Student Portal Application (The 5-Step Stepper)
* **Tester Persona:** **Student**
* **Objective:** Test the new 5-step application submission wizard, record type selection, and dynamic course filtering.
* **Steps:**
  1. Log in as the **Student** user.
  2. Open the **Student Portal / Dashboard** tab from the App Launcher.
  3. Click **Apply Now** to launch the `applicationWizard` LWC.
  4. **Step 1 (Application Type Selection):** Select one of the three program types:
     - *Undergraduate* (Default)
     - *Postgraduate*
     - *Diploma*
     Click **Next**.
  5. **Step 2 (Personal Details):** Fill in First Name, Last Name, Phone, Email, and Date of Birth (ensure age >= 16). Click **Next**.
  6. **Step 3 (Course Selection):**
     - Observe the course list. Verify that courses are dynamically filtered by the program type selected in Step 1.
     - Select a course. Check that capacity progress bars load properly. Click **Next**.
  7. **Step 4 (Document Upload):** Upload a mock PDF document for the required attachment slot. Click **Next**.
  8. **Step 5 (Review & Submit):** Verify that all typed details and selections are represented correctly on the summary card. Click **Submit Application**.
* **Expected Outcome:** The wizard closes, the application record is saved in `Submitted` status, and an approval request is automatically triggered.

---

### Use Case B: Business Rule Rules Enforcement
* **Tester Persona:** **Student** / **System Administrator**
* **Objective:** Verify that validation rules and triggers block invalid data.
* **Scenario 1 (Age Validation):**
  1. While in Step 2 of the `applicationWizard`, input a **Date of Birth** representing an age under 16 (e.g. less than 16 years from today).
  2. Click **Next** / try to save.
  - **Expected Outcome:** The LWC throws an inline validation error: *"Applicants must be at least 16 years of age."*
* **Scenario 2 (Duplicate Application Prevention):**
  1. Create a successful application with First Name: `Ayansh`, Last Name: `Roy`, Email: `ayansh.roy@studentapp.com`. Click **Save**.
  2. Attempt to create a second application with the exact same name and email.
  - **Expected Outcome:** The trigger intercepts the insert and throws: *"An application with the same name and email already exists."*

---

### Use Case C: Document Verification
* **Tester Persona:** **Document Verifier**
* **Objective:** Verify that verifiers can preview and approve/reject documents, and that rejection cascades status changes.
* **Steps:**
  1. Log in as the **Document Verifier**.
  2. Open a submitted **Student Application** record.
  3. Locate the associated **Document** record.
  4. Use the custom `documentViewer` LWC on the page to view and download the mock file.
  5. To test **Rejection**:
     - Edit the Document record.
     - Set the status to **Rejected**.
     - Try to save without entering a rejection reason.
       - *Expected:* Blocked by validation rule: *"Please provide a rejection reason when rejecting a document."*
     - Enter a comment in `Rejection_Reason__c` and click **Save**.
* **Expected Outcome:** The Document record status updates to `Rejected`. The backend trigger cascades this update, automatically setting the related **Student Application** status to `Rejected` and any associated **Admission** to `Rejected`.

---

### Use Case D: Admission Manager Approval Flow
* **Tester Persona:** **Admission Manager**
* **Objective:** Verify that approving an application automatically creates an Admission record and updates statuses.
* **Steps:**
  1. Log in as the **Admission Manager**.
  2. Open a pending **Student Application** record.
  3. Under the Approval History related list, click **Approve** on the pending request.
* **Expected Outcome:**
  - The application's **Application Status** changes to `Approved`.
  - The after-save automation triggers and automatically creates a related **Admission__c** record.
  - The application's **Admission Status** automatically updates to `Admitted` (verifying that the validation bypass for admitted students works).

---

### Use Case E: Payment Management & Ingestion
* **Tester Persona:** **Finance Officer**
* **Objective:** Ensure payments auto-populate amounts, and successes propagate status changes back to the application.
* **Steps:**
  1. Log in as the **Finance Officer**.
  2. Navigate to the **Payments** tab and click **New**.
  3. Associate the payment with an approved application.
  4. Leave the **Amount** field blank and click **Save**.
     - *Expected:* The `PaymentTriggerHandler` auto-populates `Amount__c` with the course's `Fees__c`.
  5. Update the payment's **Payment Status** to `Paid`.
* **Expected Outcome:** The related application's **Payment Status** is automatically updated to `Paid` via backend automation, and a payment confirmation email is dispatched.

---

### Use Case F: Course Capacity Enforcement
* **Tester Persona:** **System Administrator** / **Admission Executive**
* **Objective:** Ensure no admissions are allowed beyond a course's maximum capacity.
* **Steps:**
  1. Navigate to the **Courses** tab. Create or edit a course and set its **Capacity** to `1`.
  2. Submit two applications for this course.
  3. In the console, create an **Admission** record for Application 1. Save it (Success).
  4. Try to create an **Admission** record for Application 2. Save it.
* **Expected Outcome:** The save fails, and the capacity trigger blocks the insert with the message: *"Cannot complete admission. The selected course is already at maximum capacity."*

---

## 🔒 Security & Data Privacy Verification

### Use Case G: Private Record Visibility (OWD Validation)
* **Tester Persona:** **Student A** vs. **Student B**
* **Objective:** Verify that students cannot see each other's private data.
* **Steps:**
  1. Log in as **Student A** (`723145rroy@gmail.com.studentapp`).
  2. Verify you can view your own Application and Payment.
  3. Log in as **Student B** (or another non-admin test user).
  4. Navigate to the **Student Applications** and **Payments** list views.
* **Expected Outcome:** Student B cannot see any records belonging to Student A.

### Use Case H: Draft-Only Editing Constraint
* **Tester Persona:** **Student**
* **Objective:** Ensure students cannot modify applications after submission.
* **Steps:**
  1. Log in as the **Student** user.
  2. Open an application in **Draft** status. Edit and save (Success).
  3. Submit the application (status changes to `Submitted`).
  4. Try to edit and save any field.
* **Expected Outcome:** The save is blocked by validation rule, showing: *"Applicants can only modify their application while it is in Draft status."*

---

## 📊 Analytics & KPI Auditing

### Use Case I: Dashboard Real-time Metrics
* **Tester Persona:** **Admission Executive**
* **Objective:** Verify dashboard indicators and charts reload accurately.
* **Steps:**
  1. Log in as the **Admission Executive**.
  2. Open the **Dashboards** tab.
  3. Click **Refresh** on the **Admissions Executive Dashboard**.
* **Expected Outcome:** Funnel widgets, verification backlog counts, and revenue indicators reload in real time based on database state.
