/**
 * @description       :
 * @author            : Samuel Krissi (skrissi@baybridgedigital.com)
 * @group             :
 * @last modified on  : 2024-07-31
 * @last modified by  : Samuel Krissi (skrissi@baybridgedigital.com)
**/
trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert , before delete, after update, before update ) {
    new OpportunityLineItemTriggerHandler().run();

}