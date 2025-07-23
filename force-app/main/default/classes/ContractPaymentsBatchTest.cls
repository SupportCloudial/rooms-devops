@isTest
public with sharing class ContractPaymentsBatchTest {
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
      Pricebook2Id = pricebookId
    );
    insert opp;

    Order orderRecord = new Order(
      AccountId = acc.Id,
      Pricebook2Id = pricebookId,
      OpportunityId = opp.Id,
      EffectiveDate = Date.today(),
      Status = 'Draft',
      location__c = loc.Id
    );
    insert orderRecord;

    Contract con = new Contract(
      AccountId = acc.Id,
      Status = 'Draft',
      Contract_Termination_Reason__c = 'Price - Competitors',
      Contract_Termination_Date__c = Date.today().addMonths(12)
    );
    insert con;

    orderItem orderItem = new orderItem(
      orderId = orderRecord.Id,
      PricebookEntryId = standardPBE.Id,
      Quantity = 1,
      Contract__c = con.Id,
      ServiceDate = Date.today(),
      EndDate = Date.today().addYears(1).addMonths(1),
      Access_Type__c = 'Monthly',
      UnitPrice = 12
    );
    insert orderItem;

    List<MonthlyPayment__c> testPayments = new List<MonthlyPayment__c>();
    for (Integer i = 0; i < 12; i++) {
      Date startDate = Date.today().toStartOfMonth().addMonths(i);
      testPayments.add(
        new MonthlyPayment__c(
          orderItem__c = orderItem.Id,
          Contract__c = con.Id,
          Room__c = prod.Id,
          Location__c = loc.Id,
          Stat_Date_Trigger__c = startDate,
          End_Date_trigger__c = startDate.addDays(29)
        )
      );
    }
    insert testPayments;
  }

  @isTest
  static void testGenerateMonthlyPaymentsRelatedToOrderItemsBatch() {
    Contract con = [SELECT Id, Status FROM Contract LIMIT 1];
    con.Status = 'Activated';
    update con;

    Test.startTest();
    ContractPaymentsBatch b = new ContractPaymentsBatch();
    database.executeBatch(b, 200);
    Test.stopTest();
  }
}