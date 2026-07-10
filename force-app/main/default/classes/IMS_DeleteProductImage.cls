public with sharing class IMS_DeleteProductImage {
    public class Request {
        @InvocableVariable(required=true description='The Product Record ID')
        public Id productId;
    }

    @InvocableMethod(label='Delete Product Image' description='Delete the Salesforce Files image associated with the product')
    public static List<Boolean> execute(List<Request> requests) {
        List<Boolean> responses = new List<Boolean>();
        for (Request req : requests) {
            try {
                ProductImageController.deleteProductImage(req.productId);
                responses.add(true);
            } catch (Exception e) {
                responses.add(false);
            }
        }
        return responses;
    }
}
