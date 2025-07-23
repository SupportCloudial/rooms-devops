/**
 * @description       : trigger handler for MonthlyPayment Object
 * @author            : LAURIE CS
 * @last modified on  : 2024-11-07
 * @created on  : 2024-10-28
 * @last modified by  : LAURIE CS
 **/
public with sharing class MonthlyPaymentTriggerHandler extends TriggerHandler {
  public MonthlyPaymentTriggerHandler() {
    super('MonthlyPaymentTriggerHandler');
  }

  public override void afterInsert(Map<Id, SObject> monthlyPaymentNMap) {
    Map<Id, MonthlyPayment__c> mpMap = (Map<Id, MonthlyPayment__c>) monthlyPaymentNMap;
    MonthlyPaymentService.updateAggregatedPriceAdjustmentForLineItem(mpMap);
    MonthlyPaymentService.updateAggregatedPriceAdjustmentForOrderItem(mpMap);
    MonthlyPaymentService.updateListPriceAggregatedAdjustmentForLineItem(mpMap);
    //MonthlyPaymentService.updateListPriceAggregatedAdjustmentForOrderItem(
    //  mpMap
    //);
  }

  public override void afterUpdate(
    Map<Id, SObject> triggerNewMap,
    Map<Id, SObject> triggerOldMap
  ) {
    Map<Id, MonthlyPayment__c> mpMap = (Map<Id, MonthlyPayment__c>) triggerNewMap;
    MonthlyPaymentService.updateAggregatedPriceAdjustmentForLineItem(mpMap);
    MonthlyPaymentService.updateAggregatedPriceAdjustmentForOrderItem(mpMap);
    //MonthlyPaymentService.updateListPriceAggregatedAdjustmentForOrderItem(
    //  mpMap
    //);
    MonthlyPaymentService.updateListPriceAggregatedAdjustmentForLineItem(mpMap);
  }
}