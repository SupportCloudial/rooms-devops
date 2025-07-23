/**
 * @description       :
 * @author            : LAURIE CS
 * @group             :
 * @last modified on  : 2024-10-13
**/
trigger OrderItemTrigger on OrderItem (after insert , before delete, after update ) {
    new OrderItemTriggerHandler().run();

}