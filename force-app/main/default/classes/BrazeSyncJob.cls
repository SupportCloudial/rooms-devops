public with sharing class BrazeSyncJob {

    @InvocableMethod(label='Send Leads/Opportunities to Braze (Batch)')
    public static void sendToBraze(List<BrazeFlowBatchRequest> requests){
        for(BrazeFlowBatchRequest req : requests){
            if(req.recordIds != null && !req.recordIds.isEmpty()){
                Database.executeBatch(new BrazeSyncCalloutBatch(req.recordIds, req.recordType), 10);
            }
        }
    }

    public class BrazeFlowBatchRequest {
        @InvocableVariable(required=true)
        public List<Id> recordIds;

        @InvocableVariable(required=true)
        public String recordType; // 'Lead' or 'Opportunity'
    }
}