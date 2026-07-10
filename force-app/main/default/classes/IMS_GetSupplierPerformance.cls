public with sharing class IMS_GetSupplierPerformance {
    public class Request {
        @InvocableVariable(description='Dummy placeholder')
        public String placeholder;
    }

    public class SupplierPerformanceView {
        @InvocableVariable public String supplierName;
        @InvocableVariable public Decimal avgDeliveryTime;
        @InvocableVariable public Decimal orderAccuracy;
        @InvocableVariable public Integer lateDeliveries;
        @InvocableVariable public Integer rating;
    }

    @InvocableMethod(label='Get Supplier Performance' description='Retrieve performance metrics for suppliers')
    public static List<List<SupplierPerformanceView>> execute(List<Request> requests) {
        List<List<SupplierPerformanceView>> responses = new List<List<SupplierPerformanceView>>();
        
        List<InventoryDashboardController.SupplierPerformance> listPerf = InventoryDashboardController.getSupplierPerformanceData();
        List<SupplierPerformanceView> views = new List<SupplierPerformanceView>();
        for (InventoryDashboardController.SupplierPerformance sp : listPerf) {
            SupplierPerformanceView v = new SupplierPerformanceView();
            v.supplierName = sp.supplierName;
            v.avgDeliveryTime = sp.avgDeliveryTime;
            v.orderAccuracy = sp.orderAccuracy;
            v.lateDeliveries = sp.lateDeliveries;
            v.rating = sp.rating;
            views.add(v);
        }

        for (Request req : requests) {
            responses.add(views);
        }
        return responses;
    }
}
