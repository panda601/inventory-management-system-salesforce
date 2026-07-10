# Agent.md

## Epic 1: Student Application Management

### US-001: Create Student Application

As a Student,
I want to submit an application for a course,
so that I can apply for admission.

Acceptance Criteria:

* Student details can be entered.
* Course can be selected.
* Application is saved successfully.
* Application Number is generated automatically.

---

### US-002: View Application Status

As a Student,
I want to track my application status,
so that I know the progress of my admission.

Acceptance Criteria:

* Status is visible.
* Progress stages are displayed.
* Latest status is always shown.

---

### US-003: Update Draft Application

As a Student,
I want to update my application before submission,
so that I can correct mistakes.

Acceptance Criteria:

* Draft applications can be edited.
* Submitted applications become read-only.

---

## Epic 2: Course Management

### US-004: Manage Courses

As an Admission Administrator,
I want to create and manage courses,
so that students can apply to available programs.

Acceptance Criteria:

* Create course.
* Edit course.
* Track available seats.
* View course fees.

---

### US-005: Monitor Seat Availability

As an Admission Executive,
I want to see available seats,
so that I can manage admissions effectively.

Acceptance Criteria:

* Available seats displayed.
* Seats decrease after admission.
* Seats cannot become negative.

---

## Epic 3: Document Verification

### US-006: Upload Student Documents

As an Admission Executive,
I want to upload required documents,
so that student records are complete.

Acceptance Criteria:

* Multiple document types supported.
* Documents linked to application.
* Upload status tracked.

---

### US-007: Verify Documents

As a Document Verifier,
I want to verify student documents,
so that only valid applications proceed.

Acceptance Criteria:

* Mark document as Verified.
* Mark document as Rejected.
* Add verification comments.

---

### US-008: Identify Missing Documents

As a Document Verifier,
I want to identify missing documents,
so that students can complete their application.

Acceptance Criteria:

* Missing documents highlighted.
* Verification status visible.

---

## Epic 4: Application Review

### US-009: Review Student Applications

As an Admission Executive,
I want to review submitted applications,
so that eligible students can proceed.

Acceptance Criteria:

* View all submitted applications.
* Update review remarks.
* Change review status.

---

### US-010: Assign Applications for Review

As a System Administrator,
I want applications routed to the correct reviewer,
so that reviews happen efficiently.

Acceptance Criteria:

* Queue assignment works.
* Reviewer receives notification.

---

## Epic 5: Approval Process

### US-011: Submit Application for Approval

As an Admission Executive,
I want to submit reviewed applications for approval,
so that managers can make final decisions.

Acceptance Criteria:

* Approval process starts.
* Manager receives approval request.

---

### US-012: Approve Application

As an Admission Manager,
I want to approve qualified applications,
so that admissions can be created.

Acceptance Criteria:

* Status changes to Approved.
* Admission record created automatically.

---

### US-013: Reject Application

As an Admission Manager,
I want to reject unqualified applications,
so that invalid admissions are prevented.

Acceptance Criteria:

* Status changes to Rejected.
* Rejection reason stored.

---

## Epic 6: Admission Management

### US-014: Create Admission Record

As the System,
I want to automatically create admission records,
so that approved students are enrolled.

Acceptance Criteria:

* Admission record created automatically.
* Course linked correctly.

---

### US-015: View Admission Summary

As an Admission Executive,
I want to see a complete admission summary,
so that I can verify enrollment information.

Acceptance Criteria:

* Student details displayed.
* Course details displayed.
* Admission details displayed.

---

## Epic 7: Notifications

### US-016: Approval Notification

As a Student,
I want to receive approval notifications,
so that I know my application has been approved.

Acceptance Criteria:

* Email sent.
* Status updated.

---

### US-017: Rejection Notification

As a Student,
I want to receive rejection notifications,
so that I know the outcome of my application.

Acceptance Criteria:

* Email sent.
* Reason included.

---

## Epic 8: Reports & Dashboards

### US-018: View Application Dashboard

As an Admission Manager,
I want dashboards showing application metrics,
so that I can monitor admissions.

Acceptance Criteria:

* Total Applications.
* Approved Applications.
* Rejected Applications.
* Pending Applications.

---

### US-019: View Course Statistics

As an Admission Manager,
I want course-wise application statistics,
so that I can analyze demand.

Acceptance Criteria:

* Applications by course.
* Admissions by course.

---

### US-020: View Monthly Trends

As an Admission Manager,
I want monthly admission reports,
so that I can analyze growth.

Acceptance Criteria:

* Monthly charts available.
* Exportable reports.

---

## Epic 9: LWC Development

### US-021: Student Application Wizard

As a Student,
I want a guided multi-step application form,
so that submitting an application is easier.

Acceptance Criteria:

* Multi-step process.
* Validation at each step.
* Review before submission.

---

### US-022: Application Status Tracker

As a Student,
I want a visual status tracker,
so that I can track progress.

Acceptance Criteria:

* Progress bar displayed.
* Current stage highlighted.

---

### US-023: Course Availability Component

As a Student,
I want to see available seats,
so that I can choose a course.

Acceptance Criteria:

* Seats displayed.
* Real-time updates.

---

### US-024: Student Dashboard

As an Admission Manager,
I want KPI cards and charts,
so that I can quickly understand admission performance.

Acceptance Criteria:

* KPI Cards.
* Charts.
* Recent Applications.

---

## Epic 10: Security & Administration

### US-025: Manage User Access

As a System Administrator,
I want to control access to application data,
so that security is maintained.

Acceptance Criteria:

* Permission Sets assigned.
* Profiles configured.
* Sharing Rules enforced.

---

### US-026: Prevent Duplicate Applications

As a System Administrator,
I want duplicate applications prevented,
so that data quality is maintained.

Acceptance Criteria:

* Duplicate Rule active.
* Duplicate warning displayed.

---

### US-027: Audit Admissions Process

As a System Administrator,
I want to audit application changes,
so that compliance requirements are met.

Acceptance Criteria:

* Field History Tracking enabled.
* Status changes tracked.
