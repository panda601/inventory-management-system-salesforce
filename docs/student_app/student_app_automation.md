# Process Automation & Validation

This document outlines the validation rules, duplicate rules, record-triggered flows, and approval processes for the Student Application Management System.

---

## 1. Validation Rules

### Student Application (`Student_Application__c`)
* **`Date_of_Birth_Validation`**:
  * **Description**: Ensures applicants are at least 16 years old.
  * **Formula**: `Date_of_Birth__c > TODAY() - (365 * 16)`
  * **Error Message**: "Applicants must be at least 16 years of age."
  * **Error Location**: `Date_of_Birth__c`
* **`Lock_Approved_Applications`**:
  * **Description**: Prevents editing the application after it has been Approved.
  * **Formula**: `ISPICKVAL(PRIORVALUE(Application_Status__c), "Approved") && NOT(ISCHANGED(Application_Status__c))`
  * **Error Message**: "Approved applications cannot be modified."
  * **Error Location**: Top of Page

### Document (`Document__c`)
* **`Require_Rejection_Reason`**:
  * **Description**: Ensures a rejection reason is entered if the Verification Status is Rejected.
  * **Formula**: `ISPICKVAL(Verification_Status__c, "Rejected") && ISBLANK(Rejection_Reason__c)`
  * **Error Message**: "A rejection reason must be provided if the document is rejected."
  * **Error Location**: `Rejection_Reason__c`

---

## 2. Duplicate Rules

### Student Application Duplicate Rule
* **Matching Rule**:
  * **Criteria**: Match on `First_Name__c` (Fuzzy), `Last_Name__c` (Fuzzy), and `Email__c` (Exact) OR `Date_of_Birth__c` (Exact).
* **Action**:
  * **On Create**: Alert & Block (Allow bypass for Admins)
  * **On Edit**: Alert

---

## 3. Record-Triggered Flows

### 3.1 Flow: Student Application - After Save Actions
* **Trigger**: A record is created or updated.
* **Entry Conditions**: None (evaluated dynamically).
* **Actions**:
  * **Create Admission Record**:
    * **Condition**: `Application_Status__c` IS CHANGED to 'Approved' AND `Admission_Status__c` = 'Pending'.
    * **Action**: Create an `Admission__c` record. Set `Student_Application__c` = Application Id, `Course__c` = `Applied_Course__c`, and `Admission_Date__c` = Today. Update `Admission_Status__c` = 'Admitted'.
  * **Send Rejection Notification**:
    * **Condition**: `Application_Status__c` IS CHANGED to 'Rejected'.
    * **Action**: Send email alert to applicant's `Email__c` notifying them of the application status.

---

## 4. Approval Process

### Student Application Approval Process (`Student_Application_Approval_Process`)
* **Entry Criteria**: `Application_Status__c` = 'Submitted' AND `Document_Status__c` = 'Verified'.
* **Initial Submission Actions**:
  * Set `Application_Status__c` to 'Under Review'.
* **Step 1: Document Verification**
  * **Assigned To**: Queue: `Document_Verifiers_Queue`
  * **Action**: Approve if all documents are verified.
* **Step 2: Admission Approval**
  * **Assigned To**: Queue: `Admissions_Committee_Queue`
  * **Action**: Final decision to Approve or Reject the application.
* **Final Approval Actions**:
  * Set `Application_Status__c` to 'Approved'.
* **Final Rejection Actions**:
  * Set `Application_Status__c` to 'Rejected'.
