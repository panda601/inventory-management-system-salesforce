@isTest
public class InventoryScheduledJobsTest {
    @isTest
    static void testScheduledAndBatchJobs() {
        InventoryTestSupport.TestUsers users = InventoryTestSupport.createUsers();
        InventoryTestSupport.seedCoreData(users);

        // Modify SLA due date on Return Request to test escalation
        System.runAs(users.adminUser) {
            List<Return_Request__c> returnRequests = [SELECT Id, SLA_Due_Date__c, Is_Escalated__c FROM Return_Request__c];
            for (Return_Request__c req : returnRequests) {
                req.SLA_Due_Date__c = System.now().addDays(-1); // Overdue
                req.Is_Escalated__c = false;
            }
            update returnRequests;
            
            // Set product stock to low to trigger auto-reorder in finish method
            List<Product__c> products = [SELECT Id, Current_Stock__c, Minimum_Stock__c FROM Product__c];
            for (Product__c prod : products) {
                prod.Current_Stock__c = prod.Minimum_Stock__c;
            }
            update products;
        }

        Test.startTest();
        // Execute Schedulable
        String cronExpr = '0 0 0 15 3 ? 2027';
        System.schedule('Test Inventory Jobs Schedulable', cronExpr, new InventoryScheduledJobs());
        
        // Execute Batchable
        InventoryScheduledJobs batchJob = new InventoryScheduledJobs();
        Database.executeBatch(batchJob);
        Test.stopTest();

        // Verify return requests were escalated
        List<Return_Request__c> escalatedReturns = [SELECT Id, Is_Escalated__c FROM Return_Request__c WHERE Is_Escalated__c = true];
        System.assert(escalatedReturns.size() > 0, 'Return requests should be marked as escalated');
    }
}
