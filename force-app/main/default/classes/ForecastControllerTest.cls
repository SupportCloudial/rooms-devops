@isTest
public class ForecastControllerTest {

    @TestSetup
    static void setupTestData() {


        Locations__c loc = new Locations__c(
            Name = 'BSR City',
            City__c = 'Petah Tikva',
            Site_Name__c = 'BSR City',
            Address__c = 'בניין Y - השחם 3 פינת תוצרת הארץ 1, פתח תקווה',
            Area__c = 'Petah Tikva - Ramat Gan - Bnei Brak'
        );
        insert loc;

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        Product2 prod = new Product2(Name = 'SLA: Bronze', IsActive = true);
        insert prod;

        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod.Id, UnitPrice = 1000, IsActive = true);
        insert standardPBE;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today().addMonths(1),
            StageName = 'Prospecting',
            Location__c = loc.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert opp;

        OpportunityLineItem oppLineItem = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = standardPBE.Id,
            Quantity = 1,
            TotalPrice = 1000,
            Entry_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(1).addMonths(1)
        );
        insert oppLineItem;

        OpportunityLineItem oppLineItemWithoutEndDate = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = standardPBE.Id,
            Quantity = 1,
            TotalPrice = 1000,
            Entry_Date__c = Date.today()
        );
        insert oppLineItemWithoutEndDate;

        List<MonthlyPayment__c> testPayments = new List<MonthlyPayment__c>();
        for (Integer i = 0; i < 12; i++) {
            Date startDate = Date.today().toStartOfMonth().addMonths(i);
            testPayments.add(new MonthlyPayment__c(
                OpportunityLineItem__c = oppLineItem.Id,
                Opportunity__c = opp.Id,
                Room__c = prod.Id,
                Location__c = loc.Id,
                Stat_Date_Trigger__c = startDate
            ));
        }
        insert testPayments;

    }

    @isTest
    static void testFetchPaymentsOfOpportunity() {
        Test.startTest();
        List<ForecastController.WrapData> result = ForecastController.fetchPaymentsOfOpportunity();
        Test.stopTest();

        ForecastController.WrapData wrapData = result[0];
        System.assertEquals('BSR City', wrapData.locationName, 'Name should be BSR City');
    }

    @isTest
    static void testQueryMonthlyPayments() {
        Test.startTest();
        List<MonthlyPayment__c> payments = ForecastController.queryMonthlyPayments('');
        Test.stopTest();

        MonthlyPayment__c payment = payments[0];
        System.assertEquals('SLA: Bronze', payment.Products_Name__c, 'Name should be A-100912');
    }
}