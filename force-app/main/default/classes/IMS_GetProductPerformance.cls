public with sharing class IMS_GetProductPerformance {
    public class Request {
        @InvocableVariable(description='Dummy placeholder')
        public String placeholder;
    }

    public class ProductPerformanceView {
        @InvocableVariable public String productName;
        @InvocableVariable public Decimal quantitySold;
        @InvocableVariable public Decimal revenue;
        @InvocableVariable public Decimal cost;
        @InvocableVariable public Decimal profit;
        @InvocableVariable public Decimal margin;
    }

    @InvocableMethod(label='Get Product Performance' description='Retrieve product sales and margin performance leaderboard')
    public static List<List<ProductPerformanceView>> execute(List<Request> requests) {
        List<List<ProductPerformanceView>> responses = new List<List<ProductPerformanceView>>();
        
        List<InventoryDashboardController.ProductPerformance> listPerf = InventoryDashboardController.getProductPerformanceData();
        List<ProductPerformanceView> views = new List<ProductPerformanceView>();
        for (InventoryDashboardController.ProductPerformance pp : listPerf) {
            ProductPerformanceView v = new ProductPerformanceView();
            v.productName = pp.productName;
            v.quantitySold = pp.quantitySold;
            v.revenue = pp.revenue;
            v.cost = pp.cost;
            v.profit = pp.profit;
            v.margin = pp.margin;
            views.add(v);
        }

        for (Request req : requests) {
            responses.add(views);
        }
        return responses;
    }
}
