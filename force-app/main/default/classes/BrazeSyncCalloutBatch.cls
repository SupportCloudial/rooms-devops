global class BrazeSyncCalloutBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private List<Id> recordIds;
    private String recordType;
    public List<Opportunity> opportunities;

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
                Log.setLogName('Braze Sync ' + recordType);
                Log.setObject(recordType);
                Log.setRelatedLead(leadRec.Id);
                BrazeRequestWrapper payload = new BrazeRequestWrapper();
                payload = prepareRequest(payload, leadRec);
                String recordIdToLog = '';
                if(this.recordType == 'Opportunity' && !opportunities.isEmpty()){
                    recordIdToLog = opportunities[0].Id;
                    Log.setRelatedOpportunity(recordIdToLog);
                } else {
                    recordIdToLog = leadRec.Id;
                }
                Log.setLogDescription('Braze Sync Callout Service | ' + recordType + ': ' + recordIdToLog );

                Log.add('Braze Sync Callout Batch ' + recordType + ': ' + recordIdToLog);
                Log.add('Endpoint: callout:Braze_Rest/users/track');
                Log.add('Method: POST');
                Log.add('Current User: ' + UserInfo.getUserName());
       
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:Braze_Rest/users/track'); // Named Credential
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                String requestBody = JSON.serialize(payload).replace('event_time', 'time');
                Log.add('Request: ' + requestBody);
                req.setBody(requestBody);
                HttpResponse res = http.send(req);
                Log.add('Response: ' + res.getBody());
                Log.add('StatusCode: ' + res.getStatusCode());
                Log.add('Status: ' + res.getStatus());
                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    Log.setStatus('Success');
                    Log.add(LoggingLevel.INFO, 'Success for ' + this.recordType +': ' + recordIdToLog + ' | Status: ' + res.getStatusCode());
                } else {
                    Log.setStatus('Error');
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
    
    public BrazeRequestWrapper prepareRequest(BrazeRequestWrapper wrapper, Lead lead) {
        opportunities = new List<Opportunity>();
        
        if(recordType == 'Opportunity') {
			opportunities = [SELECT Id, Name, StageName, Loss_Reason__c FROM Opportunity WHERE Id =: lead.ConvertedOpportunityId];
        }
        wrapper.attributes.add(new BrazeRequestWrapper.Attribute(lead, recordType, opportunities));
        wrapper.events.add(new BrazeRequestWrapper.Event(lead, recordType, opportunities));
        return wrapper;
    }

    // Finish method
    global void finish(Database.BatchableContext BC){
        // Optional: send email or logging
    }
}