import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAdminDashboardMetrics from '@salesforce/apex/DashboardController.getAdminDashboardMetrics';
import getMonthlyTrends from '@salesforce/apex/DashboardController.getMonthlyTrends';
import getCourseAnalytics from '@salesforce/apex/DashboardController.getCourseAnalytics';

export default class HomeDashboard extends NavigationMixin(LightningElement) {
    @track metrics = {
        totalApplications: 0,
        approvedApplications: 0,
        rejectedApplications: 0,
        pendingApplications: 0,
        verificationBacklog: 0,
        totalDocuments: 0,
        verifiedDocuments: 0,
        pendingDocuments: 0,
        rejectedDocuments: 0,
        totalPayments: 0,
        successPayments: 0,
        pendingPayments: 0,
        failedPayments: 0,
        totalRevenue: 0.00
    };
    @track recentApplications = [];
    @track recentPayments = [];
    @track isLoading = false;
    @track error;
    @track monthlyTrends = [];
    @track courseAnalytics = [];

    // Percentages for applications funnel
    @track approvedPercent = 0;
    @track pendingPercent = 0;
    @track rejectedPercent = 0;

    // Percentages for documents analytics
    @track docVerifiedPercent = 0;
    @track docPendingPercent = 0;
    @track docRejectedPercent = 0;

    wiredMetricsResult;
    wiredTrendsResult;
    wiredCourseResult;

    @wire(getAdminDashboardMetrics)
    wiredMetrics(result) {
        this.wiredMetricsResult = result;
        if (result.data) {
            this.metrics = {
                totalApplications: result.data.totalApplications || 0,
                approvedApplications: result.data.approvedApplications || 0,
                rejectedApplications: result.data.rejectedApplications || 0,
                pendingApplications: result.data.pendingApplications || 0,
                verificationBacklog: result.data.verificationBacklog || 0,
                totalDocuments: result.data.totalDocuments || 0,
                verifiedDocuments: result.data.verifiedDocuments || 0,
                pendingDocuments: result.data.pendingDocuments || 0,
                rejectedDocuments: result.data.rejectedDocuments || 0,
                totalPayments: result.data.totalPayments || 0,
                successPayments: result.data.successPayments || 0,
                pendingPayments: result.data.pendingPayments || 0,
                failedPayments: result.data.failedPayments || 0,
                totalRevenue: result.data.totalRevenue || 0.00
            };

            // Calculate funnel percentages
            const totalApps = this.metrics.totalApplications;
            if (totalApps > 0) {
                this.approvedPercent = Math.round((this.metrics.approvedApplications / totalApps) * 100);
                this.pendingPercent = Math.round((this.metrics.pendingApplications / totalApps) * 100);
                this.rejectedPercent = Math.round((this.metrics.rejectedApplications / totalApps) * 100);
            } else {
                this.approvedPercent = 0;
                this.pendingPercent = 0;
                this.rejectedPercent = 0;
            }

            // Calculate document percentages
            const totalDocs = this.metrics.totalDocuments;
            if (totalDocs > 0) {
                this.docVerifiedPercent = Math.round((this.metrics.verifiedDocuments / totalDocs) * 100);
                this.docPendingPercent = Math.round((this.metrics.pendingDocuments / totalDocs) * 100);
                this.docRejectedPercent = Math.round((this.metrics.rejectedDocuments / totalDocs) * 100);
            } else {
                this.docVerifiedPercent = 0;
                this.docPendingPercent = 0;
                this.docRejectedPercent = 0;
            }

            // Map recent applications
            if (result.data.recentApplications) {
                this.recentApplications = result.data.recentApplications.map(app => ({
                    ...app,
                    studentName: `${app.First_Name__c || ''} ${app.Last_Name__c || ''}`.trim(),
                    courseName: app.Applied_Course__r ? app.Applied_Course__r.Name : 'N/A',
                    statusClass: this.getStatusBadgeClass(app.Application_Status__c),
                    formattedDate: new Date(app.CreatedDate).toLocaleDateString()
                }));
            }

            // Map recent payments
            if (result.data.recentPayments) {
                this.recentPayments = result.data.recentPayments.map(pay => {
                    const student = pay.Student_Application__r ? `${pay.Student_Application__r.First_Name__c || ''} ${pay.Student_Application__r.Last_Name__c || ''}`.trim() : 'N/A';
                    const appNum = pay.Student_Application__r ? pay.Student_Application__r.Name : 'N/A';
                    return {
                        ...pay,
                        studentName: student,
                        appNumber: appNum,
                        statusClass: this.getPaymentStatusBadgeClass(pay.Payment_Status__c)
                    };
                });
            }
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            console.error('Error fetching admin dashboard metrics:', result.error);
        }
    }

    @wire(getMonthlyTrends)
    wiredTrends(result) {
        this.wiredTrendsResult = result;
        if (result.data) {
            const trendsMap = new Map();
            const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            
            // Generate last 6 months placeholders
            for (let i = 5; i >= 0; i--) {
                const d = new Date();
                d.setMonth(d.getMonth() - i);
                const mo = d.getMonth() + 1; // 1-indexed
                const yr = d.getFullYear();
                const key = `${yr}-${mo}`;
                trendsMap.set(key, {
                    label: `${monthNames[mo - 1]} ${yr}`,
                    count: 0,
                    month: mo,
                    year: yr
                });
            }
            
            // Merge actual data from Apex
            result.data.forEach(r => {
                const key = `${r.year}-${r.month}`;
                if (trendsMap.has(key)) {
                    trendsMap.get(key).count = r.count || 0;
                }
            });
            
            const trendsList = Array.from(trendsMap.values());
            const maxCount = trendsList.reduce((m, r) => Math.max(m, r.count || 0), 1);
            
            this.monthlyTrends = trendsList.map(r => {
                const pct = Math.round(((r.count || 0) / maxCount) * 100);
                return {
                    ...r,
                    barStyle: `height: ${pct}%; background: linear-gradient(to top, #1B365D, #C9A84C);`,
                    barHeight: pct
                };
            });
        }
    }

    @wire(getCourseAnalytics)
    wiredCourseAnalytics(result) {
        this.wiredCourseResult = result;
        if (result.data) {
            this.courseAnalytics = result.data.map(r => {
                const pct = r.yieldPct || 0;
                const colorClass = pct >= 60 ? 'fill-success' : pct >= 30 ? 'fill-warning' : 'fill-danger';
                return {
                    ...r,
                    yieldBarStyle: `width: ${pct}%`,
                    combinedYieldClass: `progress-bar-fill ${colorClass}`
                };
            });
        }
    }

    getStatusBadgeClass(status) {
        switch (status) {
            case 'Approved':
                return 'slds-badge slds-theme_success slds-m-around_xx-small badge-custom badge-approved';
            case 'Rejected':
                return 'slds-badge slds-theme_error slds-m-around_xx-small badge-custom badge-rejected';
            case 'Submitted':
                return 'slds-badge slds-theme_warning slds-m-around_xx-small badge-custom badge-submitted';
            case 'Draft':
            default:
                return 'slds-badge slds-m-around_xx-small badge-custom badge-draft';
        }
    }

    getPaymentStatusBadgeClass(status) {
        switch (status) {
            case 'Paid':
                return 'slds-badge slds-theme_success slds-m-around_xx-small badge-custom badge-approved';
            case 'Failed':
                return 'slds-badge slds-theme_error slds-m-around_xx-small badge-custom badge-rejected';
            case 'Refunded':
                return 'slds-badge slds-m-around_xx-small badge-custom badge-draft';
            case 'Pending':
            default:
                return 'slds-badge slds-theme_warning slds-m-around_xx-small badge-custom badge-submitted';
        }
    }

    get paymentSuccessRate() {
        const total = this.metrics.totalPayments;
        if (total > 0) {
            return Math.round((this.metrics.successPayments / total) * 100);
        }
        return 0;
    }

    get formattedRevenue() {
        return this.metrics.totalRevenue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get approvedBarStyle() {
        return `width: ${this.approvedPercent}%`;
    }

    get pendingBarStyle() {
        return `width: ${this.pendingPercent}%`;
    }

    get rejectedBarStyle() {
        return `width: ${this.rejectedPercent}%`;
    }

    get docVerifiedBarStyle() {
        return `width: ${this.docVerifiedPercent}%`;
    }

    get docPendingBarStyle() {
        return `width: ${this.docPendingPercent}%`;
    }

    get docRejectedBarStyle() {
        return `width: ${this.docRejectedPercent}%`;
    }

    get hasRecentApplications() {
        return this.recentApplications && this.recentApplications.length > 0;
    }

    get hasRecentPayments() {
        return this.recentPayments && this.recentPayments.length > 0;
    }

    get hasMonthlyTrends() {
        return this.monthlyTrends && this.monthlyTrends.length > 0;
    }

    get hasCourseAnalytics() {
        return this.courseAnalytics && this.courseAnalytics.length > 0;
    }

    // Navigate to record detail page when clicking on the application record row
    handleRowClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    // Manual refresh action
    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredMetricsResult);
            await refreshApex(this.wiredTrendsResult);
            await refreshApex(this.wiredCourseResult);
        } catch (err) {
            console.error('Error refreshing admin dashboard metrics:', err);
        } finally {
            this.isLoading = false;
        }
    }
}