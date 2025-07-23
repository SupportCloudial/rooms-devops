/**
 * @description       :
 * @author            : Samuel Krissi (skrissi@baybridgedigital.com)
 * @group             :
 * @last modified on  : 2024-07-31
 * @last modified by  : Samuel Krissi (skrissi@baybridgedigital.com)
**/
public with sharing class OpportunityLineItemTriggerHandler extends TriggerHandler {
	/** @description default constructor */
	public OpportunityLineItemTriggerHandler() {
		super('OpportunityLineItemTriggerHandler');
	}

    	/**
	 * @description Function for Trigger after insert relate to OpportunityLineItem
	 * @author Samuel Krissi
	 * @param oppLineItemNMap oppLineItemNMap map from trigger.new
	 **/
	public override void afterInsert(Map<Id, SObject> oppLineItemNMap) {
		try {
			Map<Id, OpportunityLineItem> oppLineItem = (Map<Id, OpportunityLineItem>) oppLineItemNMap;
            OpportunityService.generateMonthlyPaymentsRelatedToOppLineItems(oppLineItem);
			OpportunityService.publishEvent();
		} catch (Exception e) {
			throw e;
		} finally {
		}
	}
    	/**
	 * @description Function for Trigger before delete relate to OpportunityLineItem
	 * @author Samuel Krissi
	 * @param oppLineItemNMap oppLineItemNMap map from trigger.new
	 **/
	public override void beforeDelete(Map<Id, SObject> oppLineItemNMap) {
		try {
			Map<Id, OpportunityLineItem> oppLineItemToDelete = (Map<Id, OpportunityLineItem>) oppLineItemNMap;
            OpportunityService.deleteAllMonthlyPaymentRelatedToOppLineItem(oppLineItemToDelete);
		} catch (Exception e) {
			throw e;
		} finally {
		}
	}

	/**
	 * @description Function for Trigger after update relate to OpportunityLineItem
	* @author Samuel Krissi (skrissi@baybridgedigital.com) | 2024-07-31
	* @param triggerNewMap
	* @param triggerOldMap
	**/
	public override void afterUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
		try {
			Map<Id, OpportunityLineItem> oppLineItemUpdateNew = (Map<Id, OpportunityLineItem>) triggerNewMap;
			Map<Id, OpportunityLineItem> oppLineItemUpdateOld = (Map<Id, OpportunityLineItem>) triggerOldMap;

			OpportunityService.deleteAllMonthlyPaymentNotRelevant(oppLineItemUpdateNew, oppLineItemUpdateOld);

		} catch (Exception e) {
			throw e;
		}
	}






}