@isTest
public with sharing class MonthlyPaymentServiceTest {
  @isTest
  static void test_updateAggregatedPriceAdjustmentForLineItem() {
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

    OpportunityLineItem olis = new OpportunityLineItem(
      OpportunityId = opp.Id,
      Quantity = 1,
      UnitPrice = 100,
      PricebookEntryId = standardPBE.Id
    );
    insert olis;

    Order orderRecord = new Order(
      AccountId = acc.Id,
      Pricebook2Id = pricebookId,
      OpportunityId = opp.Id,
      EffectiveDate = Date.today(),
      Status = 'Draft',
      Location__c = loc.Id
    );
    insert orderRecord;

    Contract con = new Contract(
      AccountId = acc.Id,
      Status = 'Draft',
      Contract_Termination_Reason__c = 'Price - Competitors',
      Contract_Termination_Date__c = Date.today().addMonths(12)
    );
    insert con;

    OrderItem orderItem = new OrderItem(
      OrderId = orderRecord.Id,
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
          OpportunityLineItem__c = olis.Id,
          Contract__c = con.Id,
          Room__c = prod.Id,
          Location__c = loc.Id,
          Stat_Date_Trigger__c = startDate,
          End_Date_trigger__c = startDate.addDays(29),
          Discount__c = 10 // ✅ 1 x 10 = 10 de Calculated_Price_Adjutment__c
        )
      );
    }
    insert testPayments;

    // Créer une map avec un seul élément
    MonthlyPayment__c mp = testPayments[0];
    Map<Id, MonthlyPayment__c> mpMap = new Map<Id, MonthlyPayment__c>{
      mp.Id => mp
    };

    Test.startTest();
    MonthlyPaymentService.updateAggregatedPriceAdjustmentForLineItem(mpMap);
    Test.stopTest();

    // Vérifie que l’agrégation est bien 10 x 12 = 120
    olis = [
      SELECT Aggregated_Price_Adjustment__c
      FROM OpportunityLineItem
      WHERE Id = :olis.Id
    ];
    System.assertEquals(
      120,
      olis.Aggregated_Price_Adjustment__c,
      'The aggregated price adjustment should be 120'
    );
  }

  @isTest
  static void test_updateAggregatedPriceAdjustmentForOrderItem() {
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

    OpportunityLineItem olis = new OpportunityLineItem(
      OpportunityId = opp.Id,
      Quantity = 1,
      UnitPrice = 100,
      PricebookEntryId = standardPBE.Id
    );
    insert olis;

    Order orderRecord = new Order(
      AccountId = acc.Id,
      Pricebook2Id = pricebookId,
      OpportunityId = opp.Id,
      EffectiveDate = Date.today(),
      Status = 'Draft',
      Location__c = loc.Id
    );
    insert orderRecord;

    Contract con = new Contract(
      AccountId = acc.Id,
      Status = 'Draft',
      Contract_Termination_Reason__c = 'Price - Competitors',
      Contract_Termination_Date__c = Date.today().addMonths(12)
    );
    insert con;

    OrderItem orderItem = new OrderItem(
      OrderId = orderRecord.Id,
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
          OpportunityLineItem__c = olis.Id,
          Contract__c = con.Id,
          Room__c = prod.Id,
          Location__c = loc.Id,
          Stat_Date_Trigger__c = startDate,
          End_Date_trigger__c = startDate.addDays(29),
          Discount__c = 10 // ✅ 1 x 10 = 10 de Calculated_Price_Adjutment__c
        )
      );
    }
    insert testPayments;

    // Créer une map avec un seul élément
    MonthlyPayment__c mp = testPayments[0];
    Map<Id, MonthlyPayment__c> mpMap = new Map<Id, MonthlyPayment__c>{
      mp.Id => mp
    };

    Test.startTest();
    MonthlyPaymentService.updateAggregatedPriceAdjustmentForOrderItem(mpMap);
    Test.stopTest();

    // Vérifie que l’agrégation est bien 10 x 12 = 120
    olis = [
      SELECT Aggregated_Price_Adjustment__c
      FROM OpportunityLineItem
      WHERE Id = :olis.Id
    ];
    System.assertEquals(
      120,
      olis.Aggregated_Price_Adjustment__c,
      'The aggregated price adjustment should be 120'
    );
  }
}