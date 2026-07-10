public with sharing class IMS_GetLowStockAlerts {
    public class Request {
        @InvocableVariable(description='Dummy placeholder')
        public String placeholder;
    }

    public class LowStockAlertView {
        @InvocableVariable public Id productId;
        @InvocableVariable public String name;
        @InvocableVariable public String productName;
        @InvocableVariable public String sku;
        @InvocableVariable public Decimal currentStock;
        @InvocableVariable public Decimal minimumStock;
        @InvocableVariable public String status;
    }

    @InvocableMethod(label='Get Low Stock Alerts' description='Retrieve active products with stock at or below minimum stock level')
    public static List<List<LowStockAlertView>> execute(List<Request> requests) {
        List<List<LowStockAlertView>> responses = new List<List<LowStockAlertView>>();
        
        List<Product__c> monitorData = InventoryController.getMonitorData();
        List<LowStockAlertView> alerts = new List<LowStockAlertView>();
        for (Product__c prod : monitorData) {
            if (prod.Current_Stock__c <= prod.Minimum_Stock__c) {
                LowStockAlertView alert = new LowStockAlertView();
                alert.productId = prod.Id;
                alert.name = prod.Name;
                alert.productName = prod.Product_Name__c;
                alert.sku = prod.SKU__c;
                alert.currentStock = prod.Current_Stock__c;
                alert.minimumStock = prod.Minimum_Stock__c;
                alert.status = prod.Status__c;
                alerts.add(alert);
            }
        }

        for (Request req : requests) {
            responses.add(alerts);
        }
        return responses;
    }
}
