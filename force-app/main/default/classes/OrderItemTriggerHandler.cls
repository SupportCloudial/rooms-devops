/**
 * @description       :The OrderItemTriggerHandler class handles OrderItem trigger events, managing the creation, deletion, and updating of related monthly payments through the
 * 						 ContractService. It executes specific actions after insert, before delete, and after update trigger events.
 * @author            : LAURIE CS
 * @group             :
 * @last modified on  : 2024-10-13
**/
public with sharing class OrderItemTriggerHandler extends TriggerHandler {

	public OrderItemTriggerHandler() {
		super('OrderItemTriggerHandler');
	}

    /**
	 * @description Function for Trigger after insert relate to OrderItem
	 * @param orderItemNMap orderItemNMap map from trigger.new
	 **/
	public override void afterInsert(Map<Id, SObject> orderItemNMap) {
		try {
			System.debug(orderItemNMap);
			Map<Id, OrderItem> orderItem = (Map<Id, OrderItem>) orderItemNMap;
            ContractService.generateMonthlyPaymentsRelatedToOrderItems(orderItem);
			ContractService.publishEvent();
		} catch (Exception e) {
			throw e;
		} finally {
		}
	}

    /**
	 * @description Function for Trigger before delete relate to OrderItem
	 * @param orderItemNMap orderItemNMap map from trigger.new
	 **/
	public override void beforeDelete(Map<Id, SObject> orderItemNMap) {
		try {
			Map<Id, OrderItem> orderItemToDelete = (Map<Id, OrderItem>) orderItemNMap;
            ContractService.deleteAllMonthlyPaymentRelatedToOrderItem(orderItemToDelete);
		} catch (Exception e) {
			throw e;
		} finally {
		}
	 }

	/**
	 * @description Function for Trigger after update relate to OrderItem
	* @param triggerNewMap
	* @param triggerOldMap
	**/
	public override void afterUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
		try {
			Map<Id, OrderItem> orderItemUpdateNew = (Map<Id, OrderItem>) triggerNewMap;
			Map<Id, OrderItem> orderItemUpdateOld = (Map<Id, OrderItem>) triggerOldMap;
            ContractService.deleteAllMonthlyPaymentNotRelevant(orderItemUpdateNew, orderItemUpdateOld);
		} catch (Exception e) {
			throw e;
		} finally {
		}
	}
}