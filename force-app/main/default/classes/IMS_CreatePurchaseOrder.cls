public with sharing class IMS_CreatePurchaseOrder {
    public class Request {
        @InvocableVariable(required=true description='The Supplier Record ID')
        public Id supplierId;
        @InvocableVariable(required=true description='The Product Record ID')
        public Id productId;
        @InvocableVariable(required=true description='The quantity to purchase')
        public Decimal quantity;
        @InvocableVariable(required=true description='The unit price for purchase')
        public Decimal unitPrice;
    }

    @InvocableMethod(label='Create Purchase Order' description='Create a new purchase order and item in draft state')
    public static List<Id> execute(List<Request> requests) {
        List<Id> responses = new List<Id>();
        for (Request req : requests) {
            try {
                Id poId = InventoryController.createPurchaseOrderWithItem(
                    req.supplierId,
                    req.productId,
                    req.quantity,
                    req.unitPrice
                );
                responses.add(poId);
            } catch (Exception e) {
                responses.add(null);
            }
        }
        return responses;
    }
}
