global class BrazeSyncCalloutBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private List<Id> recordIds;
    private String recordType;

    // Constructor
    global BrazeSyncCalloutBatch(List<Id> recIds, String type){
        this.recordIds = recIds;
        this.recordType = type;
    }

    // Start method: query records
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT Id, FirstName, LastName, Email, MobilePhone, Status, Lost_Reason__c, Desired_Location__c, ConvertedOpportunityId, OwnerId, CreatedDate
            FROM Lead WHERE Id IN :recordIds
        ]);
    }

    // Execute method: process each batch
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Http http = new Http();

        for(sObject rec : scope){
            try {
                Lead leadRec = (Lead) rec;
                Log.setLogName('Rooms Braze Integration');
                Log.setLogDescription('Braze Sync Callout Service | lead id: ' + leadRec.Id);
                
                Log.add('Class: BrazeSyncCalloutBatch');
                Log.setRelatedLead(leadRec.Id);
					
                BrazeRequestWrapper payload = new BrazeRequestWrapper(leadRec, recordType);
                String recordIdToLog;

                if(this.recordType == 'Opportunity' && !payload.opportunities.isEmpty()){
                    recordIdToLog = payload.opportunities[0].Id;
                    Log.setRelatedOpportunity(recordIdToLog);
                } else {
                    recordIdToLog = leadRec.Id;
                }
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:Braze_Rest/users/track'); // Named Credential
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                String requestBody = JSON.serialize(payload).replace('event_time', 'time');
                Log.add('req Body: ' + requestBody);
                req.setBody(requestBody);
                HttpResponse res = http.send(req);
                Log.add('res body: '+ res.getBody());
                
                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    Log.add(LoggingLevel.INFO, 'Success for ' + this.recordType +': ' + recordIdToLog + ' | Status: ' + res.getStatusCode());
                } else {
                    Log.add(LoggingLevel.ERROR,
                        'Failed for ' + this.recordType +': ' + recordIdToLog +
                        ' | Status Code: ' + res.getStatusCode() +
                        ' | Status: ' + res.getStatus() +
                        ' | Response Body: ' + res.getBody()
                    );
                }
            }catch(Exception ex) {
            	Log.add(ex);
            }finally {
                Log.insertLog();
            }
        }
    }

    // Finish method
    global void finish(Database.BatchableContext BC){
        // Optional: send email or logging
    }
}