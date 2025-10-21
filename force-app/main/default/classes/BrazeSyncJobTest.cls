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
                Loss_Reason__c = 'High Price',
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
                FirstName = 'John' + i,
                LastName = 'Doe' + i,
                Email = i + 'john.doe@test.com',
                MobilePhone = '9876543210',
                Company = 'Test Co.',
                Status = 'New',
                Desired_Location__c = loc.Id,
                HasOptedOutOfEmail = false,
            	HasOptedOutOfFax = true
            ));
        }
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
    
    @IsTest
    static void testBrazeRequestWrapper() {
        // Create a Lead with all key fields
        Lead testLead = [SELECT Id, FirstName, LastName, Email, MobilePhone, Status, Lost_Reason__c, Desired_Location__c, Desired_Location__r.Name, ConvertedOpportunityId, OwnerId, CreatedDate, HasOptedOutOfEmail, HasOptedOutOfFax FROM Lead LIMIT 1];
		Opportunity oppLost = new Opportunity();
        Opportunity oppWon = new Opportunity();
        for(Opportunity opp: [SELECT Id, Name, StageName, Loss_Reason__c FROM Opportunity]) {
            if( opp.StageName == 'Closed Lost' ) {
                oppLost = opp;
            }else if( opp.StageName == 'Closed Won' ) {
                oppWon = opp;
            }
        }
        BrazeRequestWrapper wrapper = new BrazeRequestWrapper();
        System.assertNotEquals(null, wrapper.attributes);
        System.assertNotEquals(null, wrapper.events);

        BrazeRequestWrapper.Attribute leadAttr = new BrazeRequestWrapper.Attribute(testLead, 'Lead', new List<Opportunity>());
        System.assertEquals(testLead.Email, leadAttr.email);
        System.assertEquals('opted_in', leadAttr.email_subscribe);
        System.assertEquals('unsubscribed', leadAttr.sms_subscribe);
        System.assertEquals('BSR City', leadAttr.desired_location);
        System.assertEquals(UserInfo.getTimeZone().getID(), leadAttr.time_zone);

        BrazeRequestWrapper.Attribute oppAttrLost = new BrazeRequestWrapper.Attribute(testLead, 'Opportunity', new List<Opportunity>{ oppLost });
        System.assertEquals('High Price', oppAttrLost.lost_reason);

        BrazeRequestWrapper.Event oppEventWon = new BrazeRequestWrapper.Event(testLead, 'Opportunity', new List<Opportunity>{ oppWon });
        System.assertEquals('opportunity_closed_won', oppEventWon.name);
        System.assertEquals('Closed Won', oppEventWon.properties.get('opportunity_stage'));

        BrazeRequestWrapper.Event oppEventLost = new BrazeRequestWrapper.Event(testLead, 'Opportunity', new List<Opportunity>{ oppLost });
        System.assertEquals('opportunity_closed_lost', oppEventLost.name);
        System.assertEquals('Closed Lost', oppEventLost.properties.get('opportunity_stage'));
    }
    
    @isTest
    static void testPhoneFixBatch_Lead() {
        // --- Test Data ---
        List<Lead> leads = new List<Lead>{
            new Lead(LastName='Test1', Company='Test Co', MobilePhone='054-4576526'), // Israeli - should format
            new Lead(LastName='Test2', Company='Test Co', MobilePhone='+972544576526'), // Already formatted
            new Lead(LastName='Test3', Company='Test Co', MobilePhone='+447856123456'), // Non-Israeli
            new Lead(LastName='Test4', Company='Test Co', MobilePhone='Call me later')  // Invalid (text)
        };
        insert leads;

        // --- Run Batch for Leads ---
        Test.startTest();
        Database.executeBatch(new PhoneFixBatch('Lead'), 50);
        Test.stopTest();

        // --- Validate ---
        List<Lead> updatedLeads = [SELECT Id, MobilePhone FROM Lead WHERE Id IN :leads];

        System.assertEquals('+972544576526', updatedLeads[0].MobilePhone, 'Should be formatted to +972');
        System.assertEquals('+972544576526', updatedLeads[1].MobilePhone, 'Should remain unchanged');
    }

    @isTest
    static void testPhoneFixBatch_Contact() {
        // --- Test Data ---
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName='Contact1', MobilePhone='058-7654321'), // Israeli
            new Contact(LastName='Contact2', MobilePhone='972587654321'), // Israeli without +
            new Contact(LastName='Contact3', MobilePhone='+11234567890'), // Non-Israeli
            new Contact(LastName='Contact4', MobilePhone='invalid phone') // Text
        };
        insert contacts;

        // --- Run Batch for Contacts ---
        Test.startTest();
        Database.executeBatch(new PhoneFixBatch('Contact'), 50);
        Test.stopTest();

        // --- Validate ---
        List<Contact> updatedContacts = [SELECT Id, MobilePhone FROM Contact WHERE Id IN :contacts];

        System.assertEquals('+972587654321', updatedContacts[0].MobilePhone, 'Should be formatted');
        System.assertEquals('+972587654321', updatedContacts[1].MobilePhone, 'Should be formatted');
    }
}