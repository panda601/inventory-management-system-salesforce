# Reports & Dashboards Configuration

This document specifies the standard reports and dashboard configurations for the Student Application Management System.

---

## 1. Reports

### Report 1: Applications by Status
* **Report Type**: Student Applications (Custom Report Type or Standard if lookup allows)
* **Format**: Summary
* **Groupings**: `Application_Status__c` (Rows)
* **Columns**: `Application Number`, `First_Name__c`, `Last_Name__c`, `Applied_Course__c`, `CreatedDate`
* **Filters**: `CreatedDate` equals `THIS_FISCAL_YEAR`
* **Chart**: Donut Chart showing the count of applications by status.

### Report 2: Course Enrollment & Yield
* **Report Type**: Admissions with Student Applications and Courses
* **Format**: Summary
* **Groupings**: `Course__r.Name` (Rows)
* **Columns**: `Admission ID`, `Student_Name__c`, `Admission_Date__c`, `Enrollment_Number__c`, `Fees_Paid__c`
* **Filters**: `Admission_Date__c` equals `THIS_ACADEMIC_YEAR`
* **Chart**: Vertical Bar Chart showing the count of admissions per course.

### Report 3: Document Verification Backlog
* **Report Type**: Documents
* **Format**: Summary
* **Groupings**: `Verification_Status__c` (Rows)
* **Columns**: `Document Name`, `Student_Application__r.Name`, `Document_Type__c`, `CreatedDate`
* **Filters**: `Verification_Status__c` equals `Pending`

---

## 2. Dashboard: Admissions Executive Dashboard
A dashboard to give a high-level view of the application and admission pipeline to the Head of Admissions.

| Component | Visual Type | Source Report | Display Data / Metric |
| :--- | :--- | :--- | :--- |
| **Total Applications** | Metric Chart | Applications by Status | Record Count (Total) |
| **Application Funnel** | Donut Chart | Applications by Status | Count grouped by `Application_Status__c` |
| **Enrolled by Course** | Vertical Bar | Course Enrollment & Yield | Count grouped by `Course__r.Name` |
| **Verification Backlog** | Metric Chart | Document Verification Backlog | Record Count of 'Pending' documents |
