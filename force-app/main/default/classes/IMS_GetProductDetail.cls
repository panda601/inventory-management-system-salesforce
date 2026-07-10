public with sharing class IMS_GetProductDetail {
    public class Request {
        @InvocableVariable(required=true description='The Product Record ID')
        public Id productId;
    }
    
    public class ProductDetails {
        @InvocableVariable public Id productId;
        @InvocableVariable public String name;
        @InvocableVariable public String productName;
        @InvocableVariable public String sku;
        @InvocableVariable public String category;
        @InvocableVariable public Decimal costPrice;
        @InvocableVariable public Decimal sellingPrice;
        @InvocableVariable public Decimal stockOnHand;
        @InvocableVariable public Decimal reorderPoint;
        @InvocableVariable public Decimal availableQuantity;
        @InvocableVariable public String status;
        @InvocableVariable public String productImage;
    }

    @InvocableMethod(label='Get Product Detail' description='Retrieve details for a product by its ID')
    public static List<ProductDetails> execute(List<Request> requests) {
        List<ProductDetails> responses = new List<ProductDetails>();
        for (Request req : requests) {
            ProductController.ProductDetailView detail = ProductController.getProduct(req.productId);
            if (detail != null) {
                ProductDetails det = new ProductDetails();
                det.productId = detail.Id;
                det.name = detail.Name;
                det.productName = detail.productName;
                det.sku = detail.sku;
                det.category = detail.category;
                det.costPrice = detail.costPrice;
                det.sellingPrice = detail.sellingPrice;
                det.stockOnHand = detail.stockOnHand;
                det.reorderPoint = detail.reorderPoint;
                det.availableQuantity = detail.availableQuantity;
                det.status = detail.status;
                det.productImage = detail.productImage;
                responses.add(det);
            } else {
                responses.add(null);
            }
        }
        return responses;
    }
}
