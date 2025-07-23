trigger MonthlyPaymentTrigger on MonthlyPayment__c (before insert, before update, after insert, after update) {
    new MonthlyPaymentTriggerHandler().run();

}