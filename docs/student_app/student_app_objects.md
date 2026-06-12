# Object Model & Schema Design

This document outlines the custom objects, fields, and relationships for the Student Application Management System.

---

## 1. Course (`Course__c`)
Tracks courses available for enrollment.
* **Name (Standard Field)**: Course Name (Text, 80)
* **Fields**:
  * `Course_Code__c` (Text, 10, Unique, Required)
  * `Description__c` (Long Text Area, 1000)
  * `Credits__c` (Number, 2, 0)
  * `Capacity__c` (Number, 4, 0, Required)
  * `Status__c` (Picklist: Active, Inactive)
  * `Fees__c` (Currency, 8, 2)

## 2. Student Application (`Student_Application__c`)
Represents an application submitted by a student.
* **Name (Standard Field)**: Application Number (Auto-Number: `APP-{00000}`)
* **Fields**:
  * `First_Name__c` (Text, 50, Required)
  * `Last_Name__c` (Text, 50, Required)
  * `Email__c` (Email, Required)
  * `Phone__c` (Phone)
  * `Date_of_Birth__c` (Date, Required)
  * `Applied_Course__c` (Lookup to `Course__c`, Required)
  * `Application_Status__c` (Picklist: Draft, Submitted, Under Review, Approved, Rejected) - Default: `Draft`
  * `Document_Status__c` (Picklist: Pending, Verified, Rejected) - Default: `Pending`
  * `Admission_Status__c` (Picklist: Pending, Admitted, Waitlisted) - Default: `Pending`

## 3. Document (`Document__c`)
Tracks verification documents submitted for an application (e.g., transcripts, ID).
* **Name (Standard Field)**: Document Name (Text, 80)
* **Fields**:
  * `Student_Application__c` (Master-Detail to `Student_Application__c`, Required)
  * `Document_Type__c` (Picklist: Academic Transcript, Identity Proof, Address Proof, Passport Photo)
  * `Verification_Status__c` (Picklist: Pending, Verified, Rejected) - Default: `Pending`
  * `Rejection_Reason__c` (Text, 255)
  * `Verified_By__c` (Lookup to User)

## 4. Admission (`Admission__c`)
Represents the final admission record once an application is approved.
* **Name (Standard Field)**: Admission ID (Auto-Number: `ADM-{00000}`)
* **Fields**:
  * `Student_Application__c` (Lookup to `Student_Application__c`, Unique, Required)
  * `Student_Name__c` (Formula, Text: `Student_Application__r.First_Name__c & ' ' & Student_Application__r.Last_Name__c`)
  * `Course__c` (Lookup to `Course__c`, Required)
  * `Admission_Date__c` (Date, Required, Default: Today)
  * `Enrollment_Number__c` (Text, 20, Unique)
  * `Fees_Paid__c` (Checkbox, Default: False)
