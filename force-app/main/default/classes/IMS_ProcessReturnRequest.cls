public with sharing class IMS_ProcessReturnRequest {
    public class Request {
        @InvocableVariable(required=true description='The Return Request Record ID')
        public Id requestId;
        @InvocableVariable(required=true description='Target status: Submitted, Under Review, Approved, Rejected, Refunded')
        public String status;
        @InvocableVariable(description='Resolution type: Repair, Replacement, Refund')
        public String resolutionType;
    }

    @InvocableMethod(label='Process Return Request' description='Process status transition for a Return Request record')
    public static List<Boolean> execute(List<Request> requests) {
        List<Boolean> responses = new List<Boolean>();
        for (Request req : requests) {
            try {
                InventoryController.processReturnRequestExtended(
                    req.requestId,
                    req.status,
                    req.resolutionType
                );
                responses.add(true);
            } catch (Exception e) {
                responses.add(false);
            }
        }
        return responses;
    }
}
