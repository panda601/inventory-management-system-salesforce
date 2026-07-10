public with sharing class IMS_GetInventoryHealth {
    public class Request {
        @InvocableVariable(description='Dummy placeholder')
        public String placeholder;
    }
    
    public class HealthSummary {
        @InvocableVariable public Integer totalProducts;
        @InvocableVariable public Decimal availableStock;
        @InvocableVariable public Integer lowStock;
        @InvocableVariable public Integer outOfStock;
    }

    @InvocableMethod(label='Get Inventory Health' description='Retrieve summary metrics for inventory health')
    public static List<HealthSummary> execute(List<Request> requests) {
        List<HealthSummary> responses = new List<HealthSummary>();
        
        InventoryDashboardController.InventorySummary summary = InventoryDashboardController.getInventorySummary();
        
        for (Request req : requests) {
            HealthSummary health = new HealthSummary();
            if (summary != null) {
                health.totalProducts = summary.totalProducts;
                health.availableStock = summary.availableStock;
                health.lowStock = summary.lowStock;
                health.outOfStock = summary.outOfStock;
            }
            responses.add(health);
        }
        return responses;
    }
}
