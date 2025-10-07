@isTest
private class BrazeSyncJobTest {

    @testSetup
    static void setupTestData() {
        // Create some Opportunities
        Account acc = new Account(Name = 'Test Account', Industry = 'Other');
        insert acc;
        
        Id pricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(Name = 'SLA: Bronze', IsActive = true);
        insert prod;
    
        PricebookEntry standardPBE = new PricebookEntry(
          Pricebook2Id = pricebookId,
          Product2Id = prod.Id,
          UnitPrice = 1000,
          IsActive = true
        );
        insert standardPBE;
        
        Locations__c loc = new Locations__c(
          Name = 'BSR City',
          City__c = 'Petah Tikva',
          Site_Name__c = 'BSR City',
          Address__c = 'בניין Y - השחם 3 פינת תוצרת הארץ 1, פתח תקווה',
          Area__c = 'Petah Tikva - Ramat Gan - Bnei Brak'
        );
        insert loc;

        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < 2; i++) {
            opps.add(new Opportunity(
                Name = 'TestOpp' + i,
                CloseDate = System.today().addDays(10),
                Start_Date__c = System.today(),
				StageName = 'New',
                AccountId = acc.Id,
                Pricebook2Id = pricebookId,
                Location__c = loc.Id
            ));
        }
        insert opps;
        
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        for(Opportunity opp: opps) {
            OpportunityLineItem olis = new OpportunityLineItem(
              OpportunityId = opp.Id,
              Quantity = 1,
              UnitPrice = 100,
              PricebookEntryId = standardPBE.Id,
              Entry_Date__c = System.today()
            );
            oppLineItems.add(olis);
		}
        insert oppLineItems;
    
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Opportunity opp: opps) {
            oppsToUpdate.add(new Opportunity(
                Id = opp.Id,
				StageName = 'Closed Won',
                Loss_Reason__c = 'Test',
                Contract_Type__c = 'Monthly',
                Track_CPI_Date__c = System.today()
            ));
        }
        oppsToUpdate[0].StageName = 'Closed Lost';
        update oppsToUpdate;
            
        // Create some Leads
        List<Lead> leads = new List<Lead>();
        for(Integer i = 0; i < 2; i++) {
            leads.add(new Lead(
                LastName = 'TestLead' + i,
                Company = 'TestCompany',
                IsConverted = true
                //ConvertedAccountId = acc.Id,
                //ConvertedOpportunityId = opps[0].Id
            ));
        }
        //leads[0].ConvertedOpportunityId = opps[1].Id;
        insert leads;
    }

    @isTest
    static void testSendToBrazeWithLeads() {
        // Get Lead Ids
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Id> leadIds = new List<Id>();
        for(Lead l : leads){
            leadIds.add(l.Id);
        }

        // Prepare BrazeFlowBatchRequest for Leads
        BrazeSyncJob.BrazeFlowBatchRequest req = new BrazeSyncJob.BrazeFlowBatchRequest();
        req.recordIds = leadIds;
        req.recordType = 'Lead';

        Test.startTest();
        // Set mock dynamically
    	BrazeHttpMock.setMock(201, 'Created', '{"message":"Lead synced successfully"}');
        
        BrazeSyncJob.sendToBraze(new List<BrazeSyncJob.BrazeFlowBatchRequest>{ req });
        Test.stopTest();

        // Assert that a batch job was queued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(!jobs.isEmpty(), 'Expected a batch job to be queued');
    }

    @isTest
    static void testSendToBrazeWithOpportunities() {
        // Get Lead Ids
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Id> leadIds = new List<Id>();
        for(Lead l : leads){
            leadIds.add(l.Id);
        }

        // Prepare BrazeFlowBatchRequest for Opportunities
        BrazeSyncJob.BrazeFlowBatchRequest req = new BrazeSyncJob.BrazeFlowBatchRequest();
        req.recordIds = leadIds;
        req.recordType = 'Opportunity';

        Test.startTest();
        // Set mock dynamically
    	BrazeHttpMock.setMock(201, 'Created', '{"message":"Lead synced successfully"}');
        
        BrazeSyncJob.sendToBraze(new List<BrazeSyncJob.BrazeFlowBatchRequest>{ req });
        Test.stopTest();

        // Assert that a batch job was queued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(!jobs.isEmpty(), 'Expected a batch job to be queued');
    }
    
    @isTest
    static void testSendToBrazeWithLeads_Fail() {
        // Get Lead Ids
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Id> leadIds = new List<Id>();
        for(Lead l : leads){
            leadIds.add(l.Id);
        }

        // Prepare BrazeFlowBatchRequest for Leads
        BrazeSyncJob.BrazeFlowBatchRequest req = new BrazeSyncJob.BrazeFlowBatchRequest();
        req.recordIds = leadIds;
        req.recordType = 'Lead';

        Test.startTest();
        // Set mock dynamically
    	BrazeHttpMock.setMock(401, 'Server Error', '{"message":"Error"}');
        
        BrazeSyncJob.sendToBraze(new List<BrazeSyncJob.BrazeFlowBatchRequest>{ req });
        Test.stopTest();

        // Assert that a batch job was queued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(!jobs.isEmpty(), 'Expected a batch job to be queued');
    }

    @isTest
    static void testSendToBrazeWithOpportunities_Fail() {
        // Get Lead Ids
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Id> leadIds = new List<Id>();
        for(Lead l : leads){
            leadIds.add(l.Id);
        }

        // Prepare BrazeFlowBatchRequest for Opportunities
        BrazeSyncJob.BrazeFlowBatchRequest req = new BrazeSyncJob.BrazeFlowBatchRequest();
        req.recordIds = leadIds;
        req.recordType = 'Opportunity';

        Test.startTest();
        // Set mock dynamically
    	BrazeHttpMock.setMock(401, 'Server Error', '{"message":"Error"}');
        
        BrazeSyncJob.sendToBraze(new List<BrazeSyncJob.BrazeFlowBatchRequest>{ req });
        Test.stopTest();

        // Assert that a batch job was queued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(!jobs.isEmpty(), 'Expected a batch job to be queued');
    }
    
    @isTest
    static void testSendToBrazeWithOpportunities_NullResponse() {
        // Get Lead Ids
        List<Lead> leads = [SELECT Id FROM Lead];
        List<Id> leadIds = new List<Id>();
        for(Lead l : leads){
            leadIds.add(l.Id);
        }

        // Prepare BrazeFlowBatchRequest for Opportunities
        BrazeSyncJob.BrazeFlowBatchRequest req = new BrazeSyncJob.BrazeFlowBatchRequest();
        req.recordIds = leadIds;
        req.recordType = 'Opportunity';

        Test.startTest();
        // Set mock dynamically
    	BrazeHttpMock.setMock(500, 'Server Error', '');
        
        BrazeSyncJob.sendToBraze(new List<BrazeSyncJob.BrazeFlowBatchRequest>{ req });
        Test.stopTest();

        // Assert that a batch job was queued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(!jobs.isEmpty(), 'Expected a batch job to be queued');
    }

    @isTest
    static void testSendToBrazeWithEmptyIds() {
        BrazeSyncJob.BrazeFlowBatchRequest req = new BrazeSyncJob.BrazeFlowBatchRequest();
        req.recordIds = new List<Id>(); // empty
        req.recordType = 'Lead';

        Test.startTest();
        BrazeSyncJob.sendToBraze(new List<BrazeSyncJob.BrazeFlowBatchRequest>{ req });
        Test.stopTest();

        // Should not have queued any batch job
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assertEquals(0, jobs.size(), 'No batch job should be queued for empty recordIds');
    }
}