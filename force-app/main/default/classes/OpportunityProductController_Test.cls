@isTest
public with sharing class OpportunityProductController_Test {
    @testSetup
    static void setup() {
        Date testDate = System.now().date().addDays(-10);

        Locations__c loc = new Locations__c(
            Name = 'BSR City',
            City__c = 'Petah Tikva',
            Site_Name__c = 'BSR City',
            Address__c = 'בניין Y - השחם 3 פינת תוצרת הארץ 1, פתח תקווה',
            Area__c = 'Petah Tikva - Ramat Gan - Bnei Brak'
        );
        insert loc;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(lastName = 'test',Email='alex@test.com', AccountId = acc.Id);
        insert con;

        Contract contract = new Contract(AccountId = acc.Id, Type__c = 'New Business', status = 'Draft', StartDate = testDate, Members_Registred__c = false, Main_contact__c=con.id);
        insert contract;

        contract.Status = 'Activated';
        update contract;

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

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today().addMonths(1),
            StageName = 'New',
            Location__c = loc.Id,
            Pricebook2Id = pricebookId,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId()
        );
        insert opp;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            UnitPrice = 1000,
            PricebookEntryId = standardPBE.Id,
            Quantity = 1,
            Products_Type__c = 'Standard Products',
            Entry_Date__c = Date.today().addMonths(1),
            End_date__c = Date.today().addMonths(2)
        );

        Order orderRecord = new Order(
            AccountId = acc.Id,
            Pricebook2Id = pricebookId,
            OpportunityId = opp.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            location__c = loc.Id
        );
        insert orderRecord;

        orderItem orderItem = new orderItem(
            orderId = orderRecord.Id,
            Contract__c = contract.Id,
            PricebookEntryId = standardPBE.Id,
            Quantity = 1,
            ServiceDate = Date.today().addYears(1),
            EndDate = Date.today().addYears(1).addMonths(3),
            Access_Type__c = 'Periodic',
            UnitPrice = 12
        );
        insert orderItem;

        orderItem orderItemWithoutEndDate = new orderItem(
            orderId = orderRecord.Id,
            Contract__c = contract.Id,
            PricebookEntryId = standardPBE.Id,
            Quantity = 1,
            ServiceDate = Date.today(),
            Access_Type__c = 'Monthly',
            UnitPrice = 12,
            EndDate = Date.today().addMonths(3)
        );
        insert orderItemWithoutEndDate;

        insert oli;

    }

    @isTest
    static void getOppProducts_test() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id oppId = opp.Id;
        List<OpportunityProductController.OpportunityProductData> olis = OpportunityProductController.getOppProducts(oppId);

        Assert.areEqual(1, olis.size());
    }

    @isTest
    static void saveLineItemsSuccess_test() {
        string recordTypeName = 'On demand Opportunity';
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id oppId = opp.Id;

        List<string> oliIds = new List<string>();

        List<OpportunityLineItem> lineItems = [
                                                SELECT Id, Opportunity.RecordTypeId, Opportunity.RecordType.Name, Product2Id, Product2.Name, UnitPrice,
                                                    Desk_Count__c, Access_Type__c, Entry_Date__c, End_date__c,Products_Type__c, Product_Sub_Type__c,
                                                    Quantity, TotalPrice, Temporary__c, Description, ListPrice
                                                FROM OpportunityLineItem
                                                WHERE OpportunityId = :oppId
                                            ];

        for (OpportunityLineItem oli : lineItems) {
            oliIds.add(oli.Id);
        }

        OpportunityProductController.UpdateRecordResult result = OpportunityProductController.saveLineItems(recordTypeName, oliIds, lineItems);

        Assert.areEqual(false, result.hasErrors);
    }

    @isTest
    static void saveLineItemsError1_test() {
        string recordTypeName = 'On demand Opportunity';
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id oppId = opp.Id;

        List<OpportunityLineItem> lineItems = [
                                                SELECT Id, Opportunity.RecordTypeId, Opportunity.RecordType.Name, Product2Id, Product2.Name, UnitPrice,
                                                    Desk_Count__c, Access_Type__c, Entry_Date__c, End_date__c,Products_Type__c, Product_Sub_Type__c,
                                                    Quantity, TotalPrice, Temporary__c, Description, ListPrice
                                                FROM OpportunityLineItem
                                                WHERE OpportunityId = :oppId
                                            ];

        List<string> oliIds = new List<string>();
        for (OpportunityLineItem oli : lineItems) {
            oliIds.add(oli.Id);

            oli.Access_Type__c = 'Daily';
            oli.Quantity = 4;
        }

        OpportunityProductController.UpdateRecordResult result = OpportunityProductController.saveLineItems(recordTypeName, oliIds, lineItems);
        Assert.areEqual(true, result.hasErrors);
    }

    @isTest
    static void saveLineItemsError2_test() {
        string recordTypeName = 'Standard Opportunity';
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id oppId = opp.Id;

        List<OpportunityLineItem> lineItems = [
                                                SELECT Id, Opportunity.RecordTypeId, Opportunity.RecordType.Name, Product2Id, Product2.Name, UnitPrice,
                                                    Desk_Count__c, Access_Type__c, Entry_Date__c, End_date__c,Products_Type__c, Product_Sub_Type__c,
                                                    Quantity, TotalPrice, Temporary__c, Description, ListPrice
                                                FROM OpportunityLineItem
                                                WHERE OpportunityId = :oppId
                                            ];

        List<string> oliIds = new List<string>();
        for (OpportunityLineItem oli : lineItems) {
            oliIds.add(oli.Id);

            oli.Access_Type__c = 'Monthly';
            oli.End_date__c = Date.today();
            oli.Quantity = 4;
            oli.Temporary__c = true;
        }

        OpportunityProductController.UpdateRecordResult result = OpportunityProductController.saveLineItems(recordTypeName, oliIds, lineItems);
        Assert.areEqual(true, result.hasErrors);
    }

    @isTest
    static void deleteLineItems_test() {

        string res = OpportunityProductController.deleteLineItems(null);
        Assert.areEqual('No items to delete', res);

        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id oppId = opp.Id;
        List<OpportunityLineItem> lineItems = [
                                                SELECT Id, Opportunity.RecordTypeId, Opportunity.RecordType.Name, Product2Id, Product2.Name, UnitPrice,
                                                    Desk_Count__c, Access_Type__c, Entry_Date__c, End_date__c,Products_Type__c, Product_Sub_Type__c,
                                                    Quantity, TotalPrice, Temporary__c, Description, ListPrice
                                                FROM OpportunityLineItem
                                                WHERE OpportunityId = :oppId
                                            ];

        List<string> itemIds = new List<string>();
        for (OpportunityLineItem oli : lineItems) {
            itemIds.add(oli.Id);
        }
        res = OpportunityProductController.deleteLineItems(itemIds);
        Assert.areEqual('Success', res);
    }

    @isTest
    static void getContracts_test(){
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id oppId = opp.Id;
        
        List<OpportunityProductController.OpportunityProductData> olis = OpportunityProductController.getContracts(oppId);
    }
}