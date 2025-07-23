@isTest
public with sharing class AddOppProductController_Test {

    @testSetup
    static void setup() {
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

        Id pricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(Name = 'SLA: Bronze', Location__c = loc.Id, Type__c = 'Standard Products', IsActive = true);
        insert prod;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert standardPBE;

        Opportunity opp1 = new Opportunity(
            Name = 'Test On demand Opportunity',
            CloseDate = Date.today().addMonths(1),
            StageName = 'New',
            Location__c = loc.Id,
            Pricebook2Id = pricebookId,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('On demand Opportunity').getRecordTypeId()
        );

        Opportunity opp2 = new Opportunity(
            Name = 'Test Standard Opportunity',
            CloseDate = Date.today().addMonths(1),
            StageName = 'New',
            Location__c = loc.Id,
            Pricebook2Id = pricebookId,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId()
        );

        insert new List<Opportunity> {opp1, opp2};
        
    }

    @isTest
    static void getProductsByOppLocationOnDemand_test() {
        Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('On demand Opportunity').getRecordTypeId();

        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE RecordTypeId=:recTypeId LIMIT 1];
        Id oppId = opp.Id;
        List<AddOppProductController.ProductData> products = AddOppProductController.getProductsByOppLocation(oppId);
    }

    @isTest
    static void getProductsByOppLocationstandard_test() {
        Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();

        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE RecordTypeId=:recTypeId LIMIT 1];
        Id oppId = opp.Id;
        List<AddOppProductController.ProductData> products = AddOppProductController.getProductsByOppLocation(oppId);
    }

    @isTest
    static void addProductsToOpp_test() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Id oppId = opp.Id;

        List<String> productEntryIds = new List<String>();

        AddOppProductController.addProductsToOpp(productEntryIds, oppId);
    }

}