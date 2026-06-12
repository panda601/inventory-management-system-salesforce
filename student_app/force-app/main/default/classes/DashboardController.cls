public with sharing class DashboardController {
    // Get application count metrics for the current student
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getStudentMetrics() {
        Map<String, Integer> metrics = new Map<String, Integer>{
            'Total' => 0,
            'Approved' => 0,
            'Rejected' => 0,
            'Pending' => 0
        };
        
        String userEmail = UserInfo.getUserEmail();
        List<Student_Application__c> apps = [
            SELECT Application_Status__c 
            FROM Student_Application__c 
            WHERE Email__c = :userEmail
            WITH USER_MODE
        ];
        
        metrics.put('Total', apps.size());
        for (Student_Application__c app : apps) {
            if (app.Application_Status__c == Constants.APP_STATUS_APPROVED) {
                metrics.put('Approved', metrics.get('Approved') + 1);
            } else if (app.Application_Status__c == Constants.APP_STATUS_REJECTED) {
                metrics.put('Rejected', metrics.get('Rejected') + 1);
            } else {
                metrics.put('Pending', metrics.get('Pending') + 1);
            }
        }
        
        return metrics;
    }

    // Get administrative metrics for the admissions team
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAdminDashboardMetrics() {
        Map<String, Object> dashboardData = new Map<String, Object>();
        
        // Count metrics
        Integer totalApps = 0;
        Integer approvedApps = 0;
        Integer rejectedApps = 0;
        Integer pendingApps = 0;
        
        List<Student_Application__c> allApps = [
            SELECT Application_Status__c 
            FROM Student_Application__c
            WITH USER_MODE
        ];
        
        totalApps = allApps.size();
        for (Student_Application__c app : allApps) {
            if (app.Application_Status__c == Constants.APP_STATUS_APPROVED) {
                approvedApps++;
            } else if (app.Application_Status__c == Constants.APP_STATUS_REJECTED) {
                rejectedApps++;
            } else {
                pendingApps++;
            }
        }
        
        dashboardData.put('totalApplications', totalApps);
        dashboardData.put('approvedApplications', approvedApps);
        dashboardData.put('rejectedApplications', rejectedApps);
        dashboardData.put('pendingApplications', pendingApps);
        
        // Verification Backlog count (Pending documents)
        Integer backlogCount = [
            SELECT COUNT() 
            FROM Document__c 
            WHERE Verification_Status__c = :Constants.VERIFY_STATUS_PENDING
            WITH USER_MODE
        ];
        dashboardData.put('verificationBacklog', backlogCount);

        // Document KPIs
        Integer totalDocs = [SELECT COUNT() FROM Document__c WITH USER_MODE];
        Integer verifiedDocs = [SELECT COUNT() FROM Document__c WHERE Verification_Status__c = 'Verified' WITH USER_MODE];
        Integer pendingDocs = [SELECT COUNT() FROM Document__c WHERE Verification_Status__c = 'Pending' WITH USER_MODE];
        Integer rejectedDocs = [SELECT COUNT() FROM Document__c WHERE Verification_Status__c = 'Rejected' WITH USER_MODE];

        dashboardData.put('totalDocuments', totalDocs);
        dashboardData.put('verifiedDocuments', verifiedDocs);
        dashboardData.put('pendingDocuments', pendingDocs);
        dashboardData.put('rejectedDocuments', rejectedDocs);

        // Payment KPIs
        Integer totalPayments = [SELECT COUNT() FROM Payment__c WITH USER_MODE];
        Integer successPayments = [SELECT COUNT() FROM Payment__c WHERE Payment_Status__c = :Constants.PAY_STATUS_PAID WITH USER_MODE];
        Integer pendingPayments = [SELECT COUNT() FROM Payment__c WHERE Payment_Status__c = :Constants.PAY_STATUS_PENDING WITH USER_MODE];
        Integer failedPayments = [SELECT COUNT() FROM Payment__c WHERE Payment_Status__c = :Constants.PAY_STATUS_FAILED WITH USER_MODE];

        Decimal totalRevenue = 0.00;
        List<AggregateResult> paymentAggs = [
            SELECT SUM(Amount__c) totalAmt 
            FROM Payment__c 
            WHERE Payment_Status__c = :Constants.PAY_STATUS_PAID
            WITH USER_MODE
        ];
        if (!paymentAggs.isEmpty() && paymentAggs[0].get('totalAmt') != null) {
            totalRevenue = (Decimal)paymentAggs[0].get('totalAmt');
        }

        dashboardData.put('totalPayments', totalPayments);
        dashboardData.put('successPayments', successPayments);
        dashboardData.put('pendingPayments', pendingPayments);
        dashboardData.put('failedPayments', failedPayments);
        dashboardData.put('totalRevenue', totalRevenue);

        // Recent Payments
        List<Payment__c> recentPayments = [
            SELECT Id, Name, Amount__c, Payment_Status__c, Payment_Date__c, Payment_Method__c,
                   Transaction_Id__c, Receipt_Number__c,
                   Student_Application__r.Name, Student_Application__r.First_Name__c, Student_Application__r.Last_Name__c
            FROM Payment__c
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        dashboardData.put('recentPayments', recentPayments);
 
        // Recent Applications feed
        List<Student_Application__c> recentApps = [
            SELECT Id, Name, First_Name__c, Last_Name__c, Application_Status__c, CreatedDate, Applied_Course__r.Name
            FROM Student_Application__c
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        dashboardData.put('recentApplications', recentApps);
        
        return dashboardData;
    }

    // Get monthly application/admission trends for the last 6 months
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getMonthlyTrends() {
        List<Map<String, Object>> trends = new List<Map<String, Object>>();
        
        Date sixMonthsAgo = Date.today().addMonths(-5).toStartOfMonth();
        
        List<AggregateResult> monthlyApps = [
            SELECT CALENDAR_YEAR(CreatedDate) yr, CALENDAR_MONTH(CreatedDate) mo, COUNT(Id) appCount
            FROM Student_Application__c
            WHERE CreatedDate >= :sixMonthsAgo
            WITH USER_MODE
            GROUP BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
            ORDER BY CALENDAR_YEAR(CreatedDate) ASC, CALENDAR_MONTH(CreatedDate) ASC
        ];
        
        String[] monthNames = new String[]{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
        
        for (AggregateResult ar : monthlyApps) {
            Integer mo = (Integer) ar.get('mo');
            Integer yr = (Integer) ar.get('yr');
            Integer cnt = (Integer) ar.get('appCount');
            Map<String, Object> row = new Map<String, Object>{
                'label'  => monthNames[mo - 1] + ' ' + String.valueOf(yr),
                'count'  => cnt,
                'month'  => mo,
                'year'   => yr
            };
            trends.add(row);
        }
        
        return trends;
    }

    // Get course-wise enrollment analytics
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCourseAnalytics() {
        // Query 1: total applications per course (top 10)
        List<AggregateResult> totalAggs = [
            SELECT Applied_Course__r.Name courseName, COUNT(Id) total
            FROM Student_Application__c
            WHERE Applied_Course__c != null
            WITH USER_MODE
            GROUP BY Applied_Course__r.Name
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];

        // Query 2: approved applications per course
        List<AggregateResult> approvedAggs = [
            SELECT Applied_Course__r.Name courseName, COUNT(Id) approved
            FROM Student_Application__c
            WHERE Applied_Course__c != null
              AND Application_Status__c = :Constants.APP_STATUS_APPROVED
            WITH USER_MODE
            GROUP BY Applied_Course__r.Name
        ];

        Map<String, Integer> approvedMap = new Map<String, Integer>();
        for (AggregateResult ar : approvedAggs) {
            approvedMap.put((String) ar.get('courseName'), (Integer) ar.get('approved'));
        }

        List<Map<String, Object>> courseData = new List<Map<String, Object>>();
        for (AggregateResult ar : totalAggs) {
            String cName  = (String) ar.get('courseName');
            Integer total = (Integer) ar.get('total');
            Integer approved = approvedMap.containsKey(cName) ? approvedMap.get(cName) : 0;
            Decimal yieldPct = total > 0
                ? (Decimal.valueOf(approved) / Decimal.valueOf(total) * 100).setScale(0)
                : 0;
            courseData.add(new Map<String, Object>{
                'courseName' => cName,
                'total'      => total,
                'approved'   => approved,
                'yieldPct'   => yieldPct
            });
        }

        return courseData;
    }
}
