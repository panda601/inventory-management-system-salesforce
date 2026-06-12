# Project Summary: Student Application Management System

Welcome to the **Student Application Management System** project documentation. This file provides a comprehensive overview of the Salesforce project, its modules, custom objects, frontend LWC design, business processes, and the details of all roles, permissions, and assigned user email IDs/usernames.

---

## 1. Project Overview & Scope
The Student Application Management System is a custom Salesforce application built within a Salesforce Developer Org to streamline the student enrollment pipeline. The system manages:
* **Course Cataloging**: Tracking courses, credits, capacities, fees, and active/inactive status.
* **Student Applications**: Ingestion and workflow management of prospective students' details.
* **Document Verification**: Uploading, reviewing, and verifying verification documents (academic transcripts, ID proofs) with rejection logging.
* **Admissions**: Automating the conversion of approved applications into institutional admissions, generating PDF certificates, and enrolling students.
* **Payment Processing**: Handling and tracking transaction fees, receipt numbers, and payment status updates.
* **Analytics**: Modern dashboards showing monthly application trends, document statuses, and payment metrics.

---

## 2. Salesforce Target Org
* **Default Org Username / Email**: `723145roy.6036123142ec@agentforce.com`

---

## 3. Database Schema & Object Model
The system is built around five core custom objects:

| Object | API Name | Fields & Key Characteristics |
| :--- | :--- | :--- |
| **Course** | `Course__c` | `Course_Code__c` (Text 10, Unique, Required), `Description__c` (Long Text), `Credits__c` (Number 2), `Capacity__c` (Number 4, Required), `Status__c` (Picklist: Active, Inactive), `Fees__c` (Currency). |
| **Student Application** | `Student_Application__c` | Name: `APP-{00000}` (Auto-Number). `First_Name__c` (Text 50, Required), `Last_Name__c` (Text 50, Required), `Email__c` (Email, Required), `Phone__c` (Phone), `Date_of_Birth__c` (Date, Required), `Applied_Course__c` (Lookup to Course), `Application_Status__c` (Picklist: Draft, Submitted, Under Review, Approved, Rejected), `Document_Status__c` (Picklist: Pending, Verified, Rejected), `Admission_Status__c` (Picklist: Pending, Admitted, Waitlisted). |
| **Document** | `Document__c` | Name: Text (80). `Student_Application__c` (Master-Detail to Student Application), `Document_Type__c` (Picklist: Academic Transcript, Identity Proof, Address Proof, Passport Photo), `Verification_Status__c` (Picklist: Pending, Verified, Rejected), `Rejection_Reason__c` (Text 255), `Verified_By__c` (Lookup to User). |
| **Admission** | `Admission__c` | Name: `ADM-{00000}` (Auto-Number). `Student_Application__c` (Lookup to Student Application, Unique, Required), `Student_Name__c` (Formula Text), `Course__c` (Lookup to Course, Required), `Admission_Date__c` (Date, Default: Today), `Enrollment_Number__c` (Text 20, Unique), `Fees_Paid__c` (Checkbox). |
| **Payment** | `Payment__c` | Name: `PAY-{00000}` (Auto-Number). `Student_Application__c` (Lookup to Student Application, Required), `Admission__c` (Lookup to Admission), `Course__c` (Lookup to Course), `Amount__c` (Currency, Required), `Payment_Status__c` (Picklist: Pending, Paid, Refunded), `Payment_Date__c` (Date, Required), `Transaction_Id__c` (Text, Unique), `Payment_Method__c` (Picklist: Cash, Card, Bank Transfer, UPI), `Receipt_Number__c` (Auto-Number: `RCPT-{00000}`). |

---

## 4. Frontend Design & Visualizations (LWC & Visualforce)
The user interface is designed using a custom, responsive **Navy & Gold University Theme** and contains the following modern elements:
1. **`studentDashboard`**: A Single Page Application (SPA) dashboard containing an application wizard toggle, payment status cards, and payment history columns.
2. **`applicationWizard`**: A multi-step application form with a custom numbered stepper and visual connecting bars showing completion progress.
3. **`applicationStatusTracker`**: A vertical status timeline displaying real-time tracking of the application, utilizing status-specific icons and colors.
4. **`courseAvailability`**: A mobile-friendly responsive card grid displaying course catalog details and available/total seats.
5. **`homeDashboard`**: An admin dashboard featuring Document Analytics panels, Payment KPIs, and a list of recent payment transactions.
6. **`documentViewer`**: A custom record page component that provides file previewing, opening, and downloading of uploaded files.
7. **`AdmissionPDF` (Visualforce)**: A print-ready, double-bordered institutional enrollment certificate complete with metadata placeholders and registrar signature blocks.

---

## 5. Security & Access Control Model
Data security is enforced using a strict security-first architecture:

### Organization-Wide Defaults (OWD)
* `Course__c`: **Public Read-Only**
* `Student_Application__c`: **Private**
* `Document__c`: **Controlled by Parent** (Master-Detail)
* `Admission__c`: **Private**
* `Payment__c`: **Private**

### Role Hierarchy
```
System Administrator
 └── Admission Manager
      └── Admission Executive
      └── Document Verifier
      └── Finance Officer
      └── Student
```

### Sharing Rules
* **`Student_Application__c`**:
  * Shared with `Admission Executive` and `Document Verifier` roles via criteria-based rules.
* **`Admission__c`**:
  * Shared with the `Admission Executive` role.
* **`Payment__c`**:
  * Shared with the `Finance Officer` role.

---

## 6. Permissions, Roles & Email User Assignments

Below is the matrix of permission sets, roles, and assigned email IDs or usernames:

### Production Users
These users are active in the target org `723145roy.6036123142ec@agentforce.com`:

| User Name / ID | Assigned Role | Assigned Profile | Assigned Permission Sets | Description |
| :--- | :--- | :--- | :--- | :--- |
| **`723145roy.6036123142ec@agentforce.com`** | System Administrator | System Administrator | None | Org owner / System Administrator. Main portal tester. |
| **`backuproy0911.admgr@student.app.com`** | Admission_Manager | Standard Platform User | `Admission_Manager_Access` | Responsible for overviewing approvals, managing admissions, and read-only payment access. |
| **`royayansh0039.exec@student.app.com`** | Admission_Executive | Standard Platform User | `Admission_Executive_Access`, `Document_Verifier_Access`, `Finance_Officer_Access` | Front-line worker handling student documents, admissions, and financial logging. |
| **`723145rroy@gmail.com.studentapp`** | Student | Standard Platform User | `Student_Access` | Dedicated Student user. Portal access only. |

### Unit Testing Mock Users (Apex Context)
The following mock users are created programmatically in `SecurityModelTest.cls` to validate the security model:

| Mock Email ID | Role | Profile | Permission Set Assigned | Context Verified |
| :--- | :--- | :--- | :--- | :--- |
| **`studenta@test.com`** | Student | Standard Platform User | `Student_Access` | Can see/edit own application, document, and payment. Cannot see other students' records. |
| **`studentb@test.com`** | Student | Standard Platform User | `Student_Access` | Verified that Student B has no visibility of Student A's records due to Private OWD. |
| **`exec@test.com`** | Admission_Executive | Standard Platform User | `Admission_Executive_Access` | Can see applications via sharing rules but has no access to payments. |
| **`verifier@test.com`** | Document_Verifier | Standard Platform User | `Document_Verifier_Access` | Can see applications and verify documents but has no access to admissions or payments. |
| **`finance@test.com`** | Finance_Officer | Standard Platform User | `Finance_Officer_Access` | Can see and manage payments via sharing rules but cannot see student applications or admissions. |

---

## 7. Implemented Business Logic, Triggers & Workflows

Data integrity, automation, and validation are enforced using Apex and Flow:

### Triggers & Apex Handlers
1. **`StudentApplicationTrigger` (`StudentApplicationHandler.cls`)**:
   * **Duplicate Prevention**: Rejects duplicate active applications containing the same First Name, Last Name, and Email to maintain clean database records.
   * **Rejection Syncing**: Automatically updates `Admission_Status__c = 'Rejected'` whenever `Application_Status__c = 'Rejected'`.
2. **`AdmissionTrigger` (`AdmissionHandler.cls`)**:
   * **Course Capacity Control**: Queries active enrollments in real-time. If the number of admissions exceeds the course capacity, the transaction is blocked, preventing over-enrollment.
3. **`DocumentTrigger` (`DocumentTriggerHandler.cls`)**:
   * **Document Rejection Propagation**: Automatically propagates verification failure from `Document__c` to parent `Student_Application__c` (setting `Document_Status__c = 'Rejected'` and `Admission_Status__c = 'Rejected'`).
4. **`PaymentTrigger` (`PaymentTriggerHandler.cls`)**:
   * **Amount Auto-Population**: Dynamically fetches the tuition fee from the course associated with the application and populates `Amount__c` on insert.
   * **Course Name Cache**: Caches the course name onto the payment record's text field (`Course__c`) for audit and analytics reporting.

### Declarative Automations (Flows & Approval Processes)
1. **`Student_Application_Approval_Process`**:
   * An approval process routed to the `Admission_Manager` role. When approved, a final approval field update sets `Application_Status__c = 'Approved'`.
2. **`Student_Application_After_Save` Flow**:
   * Triggers when the application's status changes to `Approved`. Automatically creates a child `Admission__c` record and sets the parent application's `Admission_Status__c` to `Admitted`.
3. **`Student_Application_Notifications` Flow**:
   * Automatically dispatches personalized transactional email alerts on Submission, Approval, and Rejection using correct merge fields (`{!$Record.Name}`).
4. **`Send_Payment_Confirmation_Email` Flow**:
   * Automatically emails a payment confirmation receipt with payment details upon status transition to `Paid`.
5. **`Update_Application_Payment_Status` Flow**:
   * Syncs custom payment records back to the parent application's payment status tracking indicators.

### Validation Rules
* **`Date_of_Birth_Validation`**: Blocks student enrollment if the applicant's age is under 16 years.
* **`Lock_Approved_Applications`**: Prevents modification of critical application details once the application is approved (except for payment/admission status updates).
* **`Student_Edit_Draft_Only`**: Restricts editing of student applications to `Draft` status only for users with the Student role.

