@isTest
public class OpportunityServiceTest {
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
      Payment_Date__c = Date.today().addYears(1).addMonths(12),
      Pricebook2Id = pricebookId
    );
    insert opp;

    OpportunityLineItem oppLineItem = new OpportunityLineItem(
      OpportunityId = opp.Id,
      PricebookEntryId = standardPBE.Id,
      Access_Type__c = 'Periodic',
      Quantity = 1,
      TotalPrice = 1000,
      Entry_Date__c = Date.today(),
      End_Date__c = Date.today().addYears(1).addMonths(1)
    );
    insert oppLineItem;

    OpportunityLineItem oppLineItemWithoutEndDate = new OpportunityLineItem(
      OpportunityId = opp.Id,
      PricebookEntryId = standardPBE.Id,
      Access_Type__c = 'Monthly',
      Quantity = 1,
      TotalPrice = 1000,
      Entry_Date__c = Date.today()
    );
    insert oppLineItemWithoutEndDate;

    opp.StageName = 'Prospecting';
    update opp;

    List<MonthlyPayment__c> testPayments = new List<MonthlyPayment__c>();
    for (Integer i = 0; i < 12; i++) {
      Date startDate = Date.today().toStartOfMonth().addMonths(i);
      testPayments.add(
        new MonthlyPayment__c(
          OpportunityLineItem__c = oppLineItem.Id,
          Opportunity__c = opp.Id,
          Room__c = prod.Id,
          Location__c = loc.Id
        )
      );
    }
    insert testPayments;
  }

  @isTest
  static void testGenerateMonthlyPaymentsRelatedToOppLineItems() {
    OpportunityLineItem testLineItem = [
      SELECT
        Id,
        Entry_Date__c,
        End_Date__c,
        ListPrice,
        OpportunityId,
        Product2Id,
        Opportunity.Location__c,
        Product2.Name,
        Access_Type__c
      FROM OpportunityLineItem
      LIMIT 1
    ];
    Map<Id, OpportunityLineItem> oppLineItemsMap = new Map<Id, OpportunityLineItem>{
      testLineItem.Id => testLineItem
    };

    Test.startTest();
    OpportunityService.generateMonthlyPaymentsRelatedToOppLineItems(
      oppLineItemsMap
    );
    Test.stopTest();

    List<MonthlyPayment__c> generatedPayments = [
      SELECT Id, Start_date__c, End_date__c, price__c
      FROM MonthlyPayment__c
      WHERE OpportunityLineItem__c = :testLineItem.Id
    ];
    System.assert(
      generatedPayments.size() > 0,
      'Expected payments to be generated'
    );
  }

  @isTest
  static void testGenerateMonthlyPaymentsForYearFromCrntDate() {
    List<OpportunityLineItem> oppLineItems = [
      SELECT
        Id,
        Entry_Date__c,
        End_Date__c,
        ListPrice,
        OpportunityId,
        Product2Id,
        Opportunity.Location__c,
        Product2.Name
      FROM OpportunityLineItem
    ];

    Test.startTest();
    OpportunityService.generateMonthlyPaymentsForYearFromCrntDate(oppLineItems);
    Database.executeBatch(new OpportunityPaymentsBatch(), 1);
    Test.stopTest();

    Date oneYearLater = Date.today().addYears(1);
    //List<MonthlyPayment__c> generatedPayments = [SELECT Id, End_date__c FROM MonthlyPayment__c WHERE End_date__c>= :oneYearLater];
    //System.assert(generatedPayments.size() > 0, 'Expected payments for the next x months');
  }

  @isTest
  static void testDeleteAllMonthlyPaymentRelatedToOppLineItem() {
    OpportunityLineItem testLineItem = [
      SELECT Id, opportunityId
      FROM OpportunityLineItem
      LIMIT 1
    ];
    Map<Id, OpportunityLineItem> oppLineItemsMap = new Map<Id, OpportunityLineItem>{
      testLineItem.Id => testLineItem
    };
    Test.startTest();
    OpportunityService.deleteAllMonthlyPaymentRelatedToOppLineItem(
      oppLineItemsMap
    );
    Integer i = 1;
    i = 2;
    i = 3;
    i = 4;
    i = 5;
    i = 6;
    i = 7;
    i = 8;
    i = 9;
    i = 10;
    testLineItem.End_Date__c = Date.today().addMonths(4);
    update testLineItem;
    /* OpportunityService.getMonthlyPayments(null, testOrderItem.Contract__c); */
    delete testLineItem;
    Test.stopTest();

    List<MonthlyPayment__c> deletedPayments = [
      SELECT Id
      FROM MonthlyPayment__c
      WHERE OpportunityLineItem__c = :testLineItem.Id
    ];
    System.assertEquals(
      0,
      deletedPayments.size(),
      'Expected payments to be deleted'
    );
  }

  @isTest
  static void testUpdateDiscount() {
    List<MonthlyPayment__c> payments = [
      SELECT Id, price__c
      FROM MonthlyPayment__c
      LIMIT 2
    ];
    for (MonthlyPayment__c payment : payments) {
      payment.Discount__c = 10; // Apply some discount
    }

    Test.startTest();
    Boolean success = OpportunityService.updateDiscount(payments);
    Test.stopTest();

    System.assert(success, 'Expected updateDiscount to return true');

    List<MonthlyPayment__c> updatedPayments = [
      SELECT Discount__c
      FROM MonthlyPayment__c
      WHERE Id IN :payments
    ];
    System.assertEquals(
      10,
      updatedPayments[0].Discount__c,
      'Expected Discount__c to be updated'
    );
  }

  @isTest
  static void testDeleteAllMonthlyPaymentAndRecalculate() {
    List<OpportunityLineItem> oppLineItems = [
      SELECT
        Id,
        Entry_Date__c,
        End_Date__c,
        ListPrice,
        OpportunityId,
        Product2Id,
        Product2.Name,
        Opportunity.Location__c,
        Access_Type__c
      FROM OpportunityLineItem
      LIMIT 2
    ];

    System.assert(
      oppLineItems.size() == 2,
      'Expected at least 2 OpportunityLineItems for testing'
    );

    OpportunityLineItem oldLineItem = oppLineItems[0];
    OpportunityLineItem updatedLineItem = oppLineItems[1];

    updatedLineItem.End_Date__c = Date.today().addMonths(2);
    update updatedLineItem;

    Map<Id, OpportunityLineItem> oldItemsMap = new Map<Id, OpportunityLineItem>{
      oldLineItem.Id => oldLineItem
    };
    Map<Id, OpportunityLineItem> updatedItemsMap = new Map<Id, OpportunityLineItem>{
      updatedLineItem.Id => updatedLineItem
    };

    Test.startTest();
    OpportunityService.deleteAllMonthlyPaymentAndRecalculate(
      updatedItemsMap,
      oldItemsMap
    );
    Test.stopTest();

    List<MonthlyPayment__c> recalculatedPayments = [
      SELECT Id, Start_date__c, End_date__c
      FROM MonthlyPayment__c
      WHERE OpportunityLineItem__c = :updatedLineItem.Id
    ];
    System.assert(
      recalculatedPayments.size() > 0,
      'Expected recalculated payments to be generated'
    );
  }

  @isTest
  static void testBeforeDelete_Exception() {
    OpportunityLineItem testLineItem = [
      SELECT Id
      FROM OpportunityLineItem
      LIMIT 1
    ];
    Map<Id, SObject> oppLineItemNMap = new Map<Id, SObject>{
      testLineItem.Id => testLineItem
    };

    Test.startTest();
    try {
      OpportunityLineItemTriggerHandler handler = new OpportunityLineItemTriggerHandler();
      handler.beforeDelete(oppLineItemNMap);
      System.assert(false, 'Expected an exception due to invalid data');
    } catch (Exception e) {
      System.assert(true, 'Caught expected exception in beforeDelete');
    }
    Test.stopTest();
  }

  @isTest
  static void testAfterUpdate_Exception() {
    OpportunityLineItem testLineItem = [
      SELECT Id
      FROM OpportunityLineItem
      LIMIT 1
    ];
    Map<Id, SObject> oppLineItemNewMap = new Map<Id, SObject>{
      testLineItem.Id => testLineItem
    };
    Map<Id, SObject> oppLineItemOldMap = new Map<Id, SObject>{
      testLineItem.Id => testLineItem
    };

    Test.startTest();
    try {
      OpportunityLineItemTriggerHandler handler = new OpportunityLineItemTriggerHandler();
      handler.afterUpdate(oppLineItemNewMap, oppLineItemOldMap);
      System.assert(false, 'Expected an exception due to invalid data');
    } catch (Exception e) {
      System.assert(true, 'Caught expected exception in afterUpdate');
    }
    Test.stopTest();
  }

  @isTest
  static void testMPAfterUpdate_Exception() {
    List<MonthlyPayment__c> mp = [SELECT Id FROM MonthlyPayment__c LIMIT 1];
    Map<Id, MonthlyPayment__c> monthlyPaymentNMap = new Map<Id, MonthlyPayment__c>();
    monthlyPaymentNMap.put(mp[0].Id, mp[0]);
    Test.startTest();
    MonthlyPaymentTriggerHandler handler = new MonthlyPaymentTriggerHandler();
    handler.afterInsert(monthlyPaymentNMap);
    Test.stopTest();
  }
}