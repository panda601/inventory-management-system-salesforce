public with sharing class IMS_CreateSalesOrder {
    public class Request {
        @InvocableVariable(required=true description='The customer name')
        public String customerName;
        @InvocableVariable(required=true description='The Product Record ID')
        public Id productId;
        @InvocableVariable(required=true description='The quantity to sell')
        public Decimal quantity;
        @InvocableVariable(required=true description='The unit selling price')
        public Decimal unitPrice;
    }

    @InvocableMethod(label='Create Sales Order' description='Create a new Sales Order and line item in draft state')
    public static List<Id> execute(List<Request> requests) {
        List<Id> responses = new List<Id>();
        for (Request req : requests) {
            try {
                Sales_Order__c so = new Sales_Order__c(
                    Customer_Name__c = req.customerName,
                    Order_Date__c = System.today(),
                    Status__c = 'Draft'
                );
                insert as user so;

                Sales_Order_Item__c soi = new Sales_Order_Item__c(
                    Sales_Order__c = so.Id,
                    Product__c = req.productId,
                    Quantity__c = req.quantity,
                    Unit_Price__c = req.unitPrice
                );
                insert as user soi;

                responses.add(so.Id);
            } catch (Exception e) {
                responses.add(null);
            }
        }
        return responses;
    }
}
