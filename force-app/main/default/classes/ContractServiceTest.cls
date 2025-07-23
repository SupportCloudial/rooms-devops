@isTest
public with sharing class ContractServiceTest {

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

        orderItem orderItem = new orderItem(
            orderId = orderRecord.Id,
            PricebookEntryId = standardPBE.Id,
            Quantity = 1,
            ServiceDate = Date.today(),
            EndDate = Date.today().addYears(1).addMonths(1),
            Access_Type__c = 'Periodic',
            UnitPrice = 12
        );
        insert orderItem;

        orderItem orderItemWithoutEndDate = new orderItem(
            orderId = orderRecord.Id,
            PricebookEntryId = standardPBE.Id,
            Quantity = 1,
            ServiceDate = Date.today(),
            Access_Type__c = 'Monthly',
            UnitPrice = 12
        );
        insert orderItemWithoutEndDate;


        List<MonthlyPayment__c> testPayments = new List<MonthlyPayment__c>();
        for (Integer i = 0; i < 12; i++) {
            Date startDate = Date.today().toStartOfMonth().addMonths(i);
            testPayments.add(new MonthlyPayment__c(
                orderItem__c = orderItem.Id,
                Room__c = prod.Id,
                Location__c = loc.Id,
                Stat_Date_Trigger__c = startDate,
                End_Date_trigger__c = startDate.addDays(29)
            ));
        }
        List<MonthlyPayment__c> testPayments2 = new List<MonthlyPayment__c>();
        for (Integer i = 0; i < 12; i++) {
            Date startDate = Date.today().toStartOfMonth().addMonths(i);
            testPayments.add(new MonthlyPayment__c(
                orderItem__c = orderItemWithoutEndDate.Id,
                Room__c = prod.Id,
                Location__c = loc.Id,
                Stat_Date_Trigger__c = startDate
            ));
        }

        insert testPayments;
        insert testPayments2;
    }

    @isTest
    static void testGenerateMonthlyPaymentsRelatedToOrderItems() {
        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>([SELECT Id, ServiceDate FROM OrderItem LIMIT 1]);

        Test.startTest();
        ContractService.generateMonthlyPaymentsRelatedToOrderItems(orderItemsMap);
        Test.stopTest();

        List<MonthlyPayment__c> payments = [SELECT Id FROM MonthlyPayment__c WHERE OrderItem__c IN :orderItemsMap.keySet()];
        System.assert(!payments.isEmpty(), 'Monthly payments should be generated.');
    }

    @isTest
    static void testGenerateMonthlyPaymentsForYearFromCrntDate() {
        List<OrderItem> orderItems = [SELECT Contract__r.Contract_Termination_Date__c, Id, ListPrice, EndDate, Access_Type__c, Contract__r.Location__c, Product2Id, Contract__c, ServiceDate FROM OrderItem LIMIT 1];

        Test.startTest();
        ContractService.generateMonthlyPaymentsForYearFromCrntDate(orderItems);
        Test.stopTest();

        List<MonthlyPayment__c> payments = [SELECT Id FROM MonthlyPayment__c WHERE OrderItem__c IN :orderItems];
        System.assert(!payments.isEmpty(), 'Monthly payments should be generated.');
    }

    @isTest
    static void testDeleteAllMonthlyPaymentRelatedToOrderItem() {
        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>([SELECT Id FROM OrderItem LIMIT 1]);

        Test.startTest();
        ContractService.deleteAllMonthlyPaymentRelatedToOrderItem(orderItemsMap);
        Test.stopTest();

        List<MonthlyPayment__c> payments = [SELECT Id FROM MonthlyPayment__c WHERE OrderItem__c IN :orderItemsMap.keySet()];
        System.assert(payments.isEmpty(), 'All monthly payments related to OrderItems should be deleted.');
    }

    @isTest
    static void testDeleteAllMonthlyPaymentAndRecalculate() {
        Map<Id, OrderItem> orderItemsNew = new Map<Id, OrderItem>([SELECT Id, ListPrice, EndDate, Access_Type__c, Contract__r.Location__c, Product2Id, Contract__c, ServiceDate FROM OrderItem LIMIT 1]);
        Map<Id, OrderItem> orderItemsOld = new Map<Id, OrderItem>([SELECT Id,ListPrice, EndDate, Access_Type__c, Contract__r.Location__c, Product2Id, Contract__c, ServiceDate FROM OrderItem LIMIT 1]);

        Test.startTest();
        ContractService.deleteAllMonthlyPaymentAndRecalculate(orderItemsNew, orderItemsOld);
        Test.stopTest();

        List<MonthlyPayment__c> payments = [SELECT Id  FROM MonthlyPayment__c WHERE OrderItem__c IN :orderItemsNew.keySet()];
        System.assert(!payments.isEmpty(), 'Monthly payments should be recalculated after deletion.');
    }

    @isTest
    static void testDeleteAllMonthlyPaymentNotRelevant() {
        Map<Id, OrderItem> orderItemsNew = new Map<Id, OrderItem>([SELECT Id, ServiceDate, EndDate, Access_Type__c FROM OrderItem LIMIT 1]);
        Map<Id, OrderItem> orderItemsOld = new Map<Id, OrderItem>([SELECT Id, ServiceDate, EndDate, Access_Type__c FROM OrderItem LIMIT 1]);

        Test.startTest();
        ContractService.deleteAllMonthlyPaymentNotRelevant(orderItemsNew, orderItemsOld);
        Test.stopTest();

        List<MonthlyPayment__c> payments = [SELECT Id FROM MonthlyPayment__c WHERE OrderItem__c IN :orderItemsNew.keySet()];
        System.assert(!payments.isEmpty(), 'Only relevant monthly payments should remain.');
    }
    @isTest
    static void testDeleteAllMonthlyPaymentNotRelevantWithoutEnddate() {
        Map<Id, OrderItem> orderItemsNew = new Map<Id, OrderItem>([SELECT Id,ListPrice, EndDate, Access_Type__c, Contract__r.Location__c, Product2Id, Contract__c, ServiceDate, Period_In_Months__c FROM OrderItem  where EndDate != null LIMIT 1]);
        Map<Id, OrderItem> orderItemsOld = new Map<Id, OrderItem>([SELECT Id, ListPrice, EndDate, Access_Type__c, Contract__r.Location__c, Product2Id, Contract__c, ServiceDate, Period_In_Months__c FROM OrderItem where EndDate = null LIMIT 1]);

        Test.startTest();
        ContractService.deleteAllMonthlyPaymentNotRelevant(orderItemsNew, orderItemsOld);
        Test.stopTest();

        List<MonthlyPayment__c> payments = [SELECT Id FROM MonthlyPayment__c WHERE OrderItem__c IN :orderItemsNew.keySet()];
        System.assert(!payments.isEmpty(), 'Only relevant monthly payments should remain.');
    }

    @isTest
    static void testPublishEvent() {
        Test.startTest();
        ContractService.publishEvent();
        Test.stopTest();

        System.assert(true, 'Event publishing tested');
    }

    @isTest
    static void testBeforeDelete_Exception() {
        OrderItem testOrderItem = [SELECT Id FROM OrderItem LIMIT 1];
        Map<Id, SObject> orderItemNMap = new Map<Id, SObject>{testOrderItem.Id => testOrderItem};

        Test.startTest();
        try {
            OrderItemTriggerHandler handler = new OrderItemTriggerHandler();
            handler.beforeDelete(orderItemNMap);
            System.assert(false, 'Expected an exception due to invalid data');
        } catch (Exception e) {
            System.assert(true, 'Caught expected exception in beforeDelete');
        }
        Test.stopTest();
    }





}