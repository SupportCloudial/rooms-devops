/**
 * @description       : implement a batch that generate number of monthlyPayments
 * @author            : LAURIE CS
 * @group             :
 * @last modified on  : 2024-10-13
 **/
public class ContractPaymentsBatch implements Database.Batchable<SObject>, Schedulable {
  public Database.QueryLocator start(Database.BatchableContext BC) {
    List<MPbyMonths__mdt> mpSettings = [
      SELECT NumberOfMonths__c
      FROM MPbyMonths__mdt
      LIMIT 1
    ];
    Integer numberOfMP = (mpSettings.isEmpty() ||
      mpSettings[0].NumberOfMonths__c == null)
      ? 0
      : Integer.valueOf(mpSettings[0].NumberOfMonths__c);
    Date monthsFromToday = Date.today().addMonths(numberOfMP);
    return Database.getQueryLocator(
      'SELECT Id, ServiceDate, Opportunity_Product__c, Contract__r.Id, Contract__r.Opportunity__c, Product2Id, Contract__r.Location__c, ' +
        'Contract__r.Contract_Termination_Date__c, ' +
        'Access_Type__c, Contract__r.Status, Product2.Name, ListPrice, ' +
        '(SELECT Id, Start_date__c, End_date__c FROM Monthly_Payments__r ORDER BY End_date__c DESC LIMIT 1) ' +
        'FROM OrderItem ' +
        'WHERE (Access_Type__c = \'Monthly\' AND Contract__r.Status = \'Activated\') limit 50000'
    );
  }

  // Execute method: process each chunk of OrderItems
  public void execute(Database.BatchableContext BC, List<OrderItem> scope) {
    ContractService.generateMonthlyPaymentsForYearFromCrntDate(scope);
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
    Database.executeBatch(new ContractPaymentsBatch(), 50);
  }
}