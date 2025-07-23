/**
 * @description       :
 * @author            : Samuel Krissi (skrissi@baybridgedigital.com)
 * @group             :
 * @last modified on  : 2024-08-15
 * @last modified by  : Samuel Krissi (skrissi@baybridgedigital.com)
**/
public class OpportunityPaymentsBatch implements Database.Batchable<SObject>, Schedulable {

    // Start method: query the OpportunityLineItems
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, OpportunityId, Product2Id, Opportunity.Location__c, Product2.Name, listPrice,' +
                                            '(SELECT Id, End_date__c FROM Monthly_Payments__r ORDER BY End_date__c DESC LIMIT 1) ' +
                                        'FROM OpportunityLineItem WHERE End_Date__c = NULL');
    }

    // Execute method: process each chunk of OpportunityLineItems
    public void execute(Database.BatchableContext BC, List<OpportunityLineItem> scope) {
        OpportunityService.generateMonthlyPaymentsForYearFromCrntDate(scope);
    }

    // Finish method: optional post-processing
    public void finish(Database.BatchableContext BC) {
    }
    /**
     * @description Executes the scheduled job.
     * @param context The schedulable context instance.
     * @return void This method does not return any value.
     **/
    public void execute(SchedulableContext context) {
        Database.executeBatch(new OpportunityPaymentsBatch(), 200); // Adjust batch size as needed
    }
}