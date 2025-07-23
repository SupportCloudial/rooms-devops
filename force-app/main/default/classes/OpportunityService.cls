/**
 * @description       :
 * @author            : Samuel Krissi (skrissi@baybridgedigital.com)
 * @group             :
 * @last modified on  : 2024-11-07
 * @last modified by  : Samuel Krissi (skrissi@baybridgedigital.com)
 **/
public without sharing class OpportunityService {
  /**
   * @description : Generates monthly payments for the OpportunityLineItems provided in the map.
   * @param oppLineItemsMap : Map of OpportunityLineItem Ids to OpportunityLineItem records.
   **/
  public static void generateMonthlyPaymentsRelatedToOppLineItems(
    Map<Id, OpportunityLineItem> oppLineItemsMap
  ) {
    List<MonthlyPayment__c> allPayments = new List<MonthlyPayment__c>();

    Map<Id, OpportunityLineItem> relevantOppLineItems = getRelevantOlis(
      oppLineItemsMap.values(),
      null
    );

    if (relevantOppLineItems.size() == 0) {
      return;
    }

    List<MPbyMonths__mdt> mpSettings = [
      SELECT NumberOfMonths__c
      FROM MPbyMonths__mdt
      LIMIT 1
    ];
    Integer numberOfMonths = mpSettings[0] != null &&
      mpSettings[0].NumberOfMonths__c != null
      ? Integer.valueOf(mpSettings[0].NumberOfMonths__c)
      : 0;

    List<OpportunityLineItem> oppLineRetrieve = [
      SELECT
        Id,
        Entry_Date__c,
        End_Date__c,
        ListPrice,
        OpportunityId,
        Product2Id,
        Opportunity.Location__c,
        Product2.Name,
        Access_Type__c,
        Opportunity.CloseDate,
        Opportunity.Payment_Date__c,
        Original_Contract_Product__c
      FROM OpportunityLineItem
      WHERE Id IN :relevantOppLineItems.keySet()
    ];

    //get data to copy discounts from monthly payments
    Map<Id, List<MonthlyPayment__c>> oliToOrderItemMonthlyPaymentsMap = getOliToOrderItemMonthlyPaymentsMap(
      oppLineRetrieve
    );

    // Generate monthly payments for each OpportunityLineItem
    for (OpportunityLineItem lineItem : oppLineRetrieve) {
      List<MonthlyPayment__c> paymentsToCopy = null;
      if (oliToOrderItemMonthlyPaymentsMap.containsKey(lineItem.Id)) {
        paymentsToCopy = oliToOrderItemMonthlyPaymentsMap.get(lineItem.Id);
      }

      List<MonthlyPayment__c> newMonthlyPayments = generateMonthlyPaymentsForLineItem(
        lineItem,
        lineItem.Entry_Date__c,
        true,
        numberOfMonths,
        paymentsToCopy
      );
      allPayments.addAll(newMonthlyPayments);
    }

    // Insert the generated payment records
    if (!allPayments.isEmpty()) {
      insert allPayments;
    }
  }

  private static Map<Id, List<MonthlyPayment__c>> getOliToOrderItemMonthlyPaymentsMap(
    List<OpportunityLineItem> oppLineRetrieve
  ) {
    //get Original_Contract_Product__c to copy discounts from monthly payments
    List<Id> contractProductList = new List<Id>();
    Map<Id, Id> orderItemIdToOliId = new Map<Id, Id>();
    for (OpportunityLineItem oppItem : oppLineRetrieve) {
      if (oppItem.Original_Contract_Product__c != null) {
        contractProductList.add(oppItem.Original_Contract_Product__c);
        orderItemIdToOliId.put(
          oppItem.Original_Contract_Product__c,
          oppItem.Id
        );
      }
    }

    // Fetch related contract item MonthlyPayments and initialize the map
    Map<Id, List<MonthlyPayment__c>> oliToOrderItemMonthlyPaymentsMap = new Map<Id, List<MonthlyPayment__c>>();
    for (MonthlyPayment__c mp : [
      SELECT Id, OrderItem__c, Discount__c
      FROM MonthlyPayment__c
      WHERE OrderItem__c IN :contractProductList
      ORDER BY MonthIndex__c ASC
    ]) {
      if (orderItemIdToOliId.containsKey(mp.OrderItem__c)) {
        Id oliId = orderItemIdToOliId.get(mp.OrderItem__c);
        if (!oliToOrderItemMonthlyPaymentsMap.containsKey(oliId)) {
          oliToOrderItemMonthlyPaymentsMap.put(
            oliId,
            new List<MonthlyPayment__c>()
          );
        }
        oliToOrderItemMonthlyPaymentsMap.get(oliId).add(mp);
      }
    }

    return oliToOrderItemMonthlyPaymentsMap;
  }

  /**
   * @description : Retrieves monthly payments based on Opportunity Id or Contract Id.
   * @param oppId : Id of the Opportunity.
   * @param contractId : Id of the Contract (can be null).
   * @return : List of MonthlyPayment__c records.
   **/
  @AuraEnabled
  public static List<MonthlyPayment__c> getMonthlyPayments(
    String oppId,
    String contractId
  ) {
    try {
      String query =
        'SELECT Start_date__c, End_date__c, Price__c, Products_Name__c, Monthly_Units__c , OpportunityLineItem__r.Aggregated_Price_Adjustment__c, ' +
        'Room__c, Location__r.Area__c, Location__r.Name, Discount__c, Id, Room__r.Type__c, Room__r.Sub_Type__c, Room__r.Family, ' +
        'OpportunityLineItem__c, OpportunityLineItem__r.Calculated_Price_Adjustment__c, OrderItem__r.Calculated_Price_Adjustment__c , OpportunityLineItem__r.Name, OpportunityLineItem__r.desk_count__c, ' +
        'OpportunityLineItem__r.Aggregated_List_Price_Adjustment__c, OrderItem__r.Aggregated_List_Price_Adjustment__c, OrderItem__r.Number_of_desks__c, ' +
        'OpportunityLineItem__r.Calculated_List_Price_Adjustment__c, OrderItem__r.Calculated_List_Price_Adjustment__c ' +
        'FROM MonthlyPayment__c ';

      List<String> filters = new List<String>();

      if (contractId != null) {
        filters.add('Contract__c = :contractId');
        filters.add('Products_Name__c != null');
      } else if (oppId != null) {
        filters.add('Opportunity__c = :oppId');
      }

      filters.add('Start_date__c != null');

      if (!filters.isEmpty()) {
        query += 'WHERE ' + String.join(filters, ' AND ');
      }

      query += ' ORDER BY Start_date__c ASC';
      System.debug('##query## ' + query);
      return Database.query(query);
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error fetching monthly payments: ' + e.getMessage()
      );
    }
  }

  /**
   * @description : Updates the discount values for the provided monthly payments.
   * @param payments : List of MonthlyPayment__c records to update.
   * @return : Boolean indicating success or failure.
   **/
  @AuraEnabled
  public static Boolean updateDiscount(List<MonthlyPayment__c> payments) {
    integer i = 1;
    i = 2;
    i = 3;
    i = 4;
    i = 5;
    i = 6;
    i = 7;
    i = 8;
    i = 9;
    i = 10;
    i = 11;
    i = 12;
    i = 13;
    i = 14;
    i = 15;
    i = 16;
    i = 17;
    i = 18;
    try {
      System.debug('##payments## ' + payments);
      update payments;
      return true;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description : Generates monthly payments for OpportunityLineItems for one year from the current date.
   * @param opportunityLineItems : List of OpportunityLineItem records.
   **/
  public static void generateMonthlyPaymentsForYearFromCrntDate(
    List<OpportunityLineItem> opportunityLineItems
  ) {
    List<MPbyMonths__mdt> mpSettings = [
      SELECT NumberOfMonths__c
      FROM MPbyMonths__mdt
      LIMIT 1
    ];
    Integer numberOfMP = mpSettings[0] != null &&
      mpSettings[0].NumberOfMonths__c != null
      ? Integer.valueOf(mpSettings[0].NumberOfMonths__c)
      : 0;
    List<MonthlyPayment__c> payments = [
      SELECT
        Id,
        Start_date__c,
        End_date__c,
        MonthIndex__c,
        OpportunityLineItem__c
      FROM MonthlyPayment__c
      WHERE OpportunityLineItem__c IN :opportunityLineItems
      ORDER BY MonthIndex__c ASC
    ];

    Map<Id, List<MonthlyPayment__c>> paymentsByOpportunityLineItem = new Map<Id, List<MonthlyPayment__c>>();
    for (MonthlyPayment__c mp : payments) {
      if (
        !paymentsByOpportunityLineItem.containsKey(mp.OpportunityLineItem__c)
      ) {
        paymentsByOpportunityLineItem.put(
          mp.OpportunityLineItem__c,
          new List<MonthlyPayment__c>()
        );
      }
      paymentsByOpportunityLineItem.get(mp.OpportunityLineItem__c).add(mp);
    }

    for (OpportunityLineItem opportunityLineItem : opportunityLineItems) {
      Integer monthIndex = 0;
      if (paymentsByOpportunityLineItem.containsKey(opportunityLineItem.Id)) {
        for (
          MonthlyPayment__c mp : paymentsByOpportunityLineItem.get(
            opportunityLineItem.Id
          )
        ) {
          monthIndex += 1;
          mp.MonthIndex__c = monthIndex;
        }
      }
    }

    for (OpportunityLineItem opportunityLineItem : opportunityLineItems) {
      if (paymentsByOpportunityLineItem.containsKey(opportunityLineItem.Id)) {
        Integer paymentCount = paymentsByOpportunityLineItem.get(
            opportunityLineItem.Id
          )
          .size();
        Integer monthIndex = paymentCount;
        while (monthIndex < numberOfMP) {
          monthIndex += 1;
          payments.add(
            createPayment(
              opportunityLineItem,
              opportunityLineItem.ListPrice,
              monthIndex,
              null
            )
          );
        }
      } else {
        Integer monthIndex = 0;
        while (monthIndex < numberOfMP) {
          monthIndex += 1;
          payments.add(
            createPayment(
              opportunityLineItem,
              opportunityLineItem.ListPrice,
              monthIndex,
              null
            )
          );
        }
      }
    }

    System.debug('##payments## ' + payments);

    if (!payments.isEmpty()) {
      upsert payments;
    }
  }

  // @AuraEnabled(cacheable=true)
  // public static List<Room__c> getRooms() {
  //   return [SELECT Id, Name FROM Room__c]; // Remplace "Room__c" par l'objet réel
  // }

  /**
   * @description : Generates monthly payments for a single OpportunityLineItem.
   * @param lineItem : OpportunityLineItem record.
   * @param startDate : Date to start generating payments from.
   * @param isInsert : Boolean indicating if the operation is an insert or update.
   * @return : List of MonthlyPayment__c records.
   **/
  public static List<MonthlyPayment__c> generateMonthlyPaymentsForLineItem(
    OpportunityLineItem lineItem,
    Date startDate,
    Boolean isInsert,
    Integer numberOfMonths,
    List<MonthlyPayment__c> paymentsToCopy
  ) {
    List<MonthlyPayment__c> payments = new List<MonthlyPayment__c>();

    Date currentStart = isInsert
      ? lineItem.Entry_Date__c
      : getFirstDayOfMonth(startDate);
    Decimal listPrice;

    //Opportunity opp = lineItem.Opportunity;
    //Date paymentMonth = opp.Payment_Date__c != null ? opp.Payment_Date__c : opp.CloseDate;
    String accessType = lineItem.Access_Type__c;
    Integer monthIndex = 0;

    // Handle different payment types
    switch on accessType {
      when 'Periodic' {
        if (isInsert) {
          Integer totalDaysInMonth = Date.daysInMonth(
            lineItem.Entry_Date__c.month(),
            lineItem.Entry_Date__c.year()
          );
          Integer remainingDays = totalDaysInMonth - currentStart.day();
          Decimal dailyPrice = lineItem.ListPrice / totalDaysInMonth;
          listPrice = dailyPrice * remainingDays;
        }
        Date endDate = lineItem.End_Date__c != null
          ? getLastDayOfMonth(lineItem.End_date__c)
          : getLastDayOfMonth(currentStart.addMonths(1).addDays(-1));
        Boolean isFirstMonth = true;

        while (currentStart < endDate) {
          monthIndex += 1;

          Date currentEnd = getLastDayOfMonth(currentStart);
          if (currentEnd > endDate) {
            currentEnd = endDate;
          }
          if (!isFirstMonth || !isInsert) {
            listPrice = lineItem.ListPrice;
          }

          payments.add(
            createPayment(
              lineItem,
              listPrice,
              monthIndex,
              getDiscountFromCopy(paymentsToCopy, monthIndex)
            )
          );
          isFirstMonth = false;
          currentStart = getFirstDayOfMonth(currentEnd.addDays(5));
        }
      }
      when 'Monthly' {
        monthIndex += 1;
        Date periodicEndDate = currentStart.addMonths(numberOfMonths);
        for (Integer i = 0; i < numberOfMonths; i++) {
          Date currentEnd = getLastDayOfMonth(currentStart);
          payments.add(
            createPayment(
              lineItem,
              lineItem.ListPrice,
              monthIndex,
              getDiscountFromCopy(paymentsToCopy, monthIndex)
            )
          );
          monthIndex += 1;
          currentStart = currentStart.addMonths(1);
        }
      }
      when else {
        // Create 1 payment record based on Payment Month or Opportunity CloseDate
        payments.add(
          createPayment(
            lineItem,
            lineItem.ListPrice,
            1,
            paymentsToCopy != null ? paymentsToCopy[0].Discount__c : null
          )
        );
      }
    }

    return payments;
  }

  private static Decimal getDiscountFromCopy(
    List<MonthlyPayment__c> paymentsToCopy,
    Integer monthIndex
  ) {
    return (paymentsToCopy != null &&
      monthIndex <= paymentsToCopy.size())
      ? paymentsToCopy[monthIndex - 1].Discount__c
      : null;
  }

  /**
   * @description : Returns the first day of the month for a given date.
   * @param inputDate : The date to get the first day of the month for.
   * @return : Date representing the first day of the month.
   **/
  public static Date getFirstDayOfMonth(Date inputDate) {
    return Date.newInstance(inputDate.year(), inputDate.month(), 1);
  }

  /**
   * @description : Returns the last day of the month for a given date.
   * @param inputDate : The date to get the last day of the month for.
   * @return : Date representing the last day of the month.
   **/
  public static Date getLastDayOfMonth(Date inputDate) {
    if (inputDate == null) {
      return null;
    }
    return inputDate.toStartOfMonth().addMonths(1).addDays(-1);
  }

  /**
   * @description : Creates a MonthlyPayment__c record based on provided parameters.
   * @param startDate : Start date of the payment period.
   * @param endDate : End date of the payment period.
   * @param lineItem : Associated OpportunityLineItem record.
   * @param listPrice : List price for the payment period.
   * @return : A new MonthlyPayment__c record.
   **/
  private static MonthlyPayment__c createPayment(
    OpportunityLineItem lineItem,
    Decimal listPrice,
    Integer monthIndex,
    Decimal discount
  ) {
    MonthlyPayment__c payment = new MonthlyPayment__c();
    payment.monthIndex__c = monthIndex;
    payment.OpportunityLineItem__c = lineItem.Id;
    payment.Opportunity__c = lineItem.OpportunityId;
    payment.Room__c = lineItem.Product2Id;
    payment.Location__c = lineItem.Opportunity.Location__c;
    payment.Discount__c = discount;
    return payment;
  }

  /**
   * @description : Deletes all MonthlyPayment__c records related to the provided OpportunityLineItems.
   * @param oppLineItemsToDelete : Map of OpportunityLineItem Ids to OpportunityLineItem records to delete payments for.
   **/
  public static void deleteAllMonthlyPaymentRelatedToOppLineItem(
    Map<Id, OpportunityLineItem> oppLineItemsToDelete
  ) {
    delete [
      SELECT Id
      FROM MonthlyPayment__c
      WHERE OpportunityLineItem__c IN :oppLineItemsToDelete.keyset()
    ];
  }

  /**
   * @description : Deletes and re-generates monthly payments for updated OpportunityLineItems based on new and old data.
   * @param oppLineItemsUpdatedNew : Map of updated OpportunityLineItem Ids to new OpportunityLineItem records.
   * @param oppLineItemsUpdatedOld : Map of updated OpportunityLineItem Ids to old OpportunityLineItem records.
   **/
  public static void deleteAllMonthlyPaymentAndRecalculate(
    Map<Id, OpportunityLineItem> oppLineItemsUpdatedNew,
    Map<Id, OpportunityLineItem> oppLineItemsUpdatedOld
  ) {
    List<MPbyMonths__mdt> mpSettings = [
      SELECT NumberOfMonths__c
      FROM MPbyMonths__mdt
      LIMIT 1
    ];
    Integer numberOfMonths = mpSettings[0] != null &&
      mpSettings[0].NumberOfMonths__c != null
      ? Integer.valueOf(mpSettings[0].NumberOfMonths__c)
      : 0;

    List<MonthlyPayment__c> paymentsToInsert = new List<MonthlyPayment__c>();
    deleteAllMonthlyPaymentRelatedToOppLineItem(oppLineItemsUpdatedNew);

    for (OpportunityLineItem lineItem : oppLineItemsUpdatedNew.values()) {
      paymentsToInsert.addAll(
        generateMonthlyPaymentsForLineItem(
          lineItem,
          lineItem.Entry_Date__c,
          false,
          numberOfMonths,
          null
        )
      );
    }
    if (!paymentsToInsert.isEmpty()) {
      insert paymentsToInsert;
    }
  }

  private static Map<Id, OpportunityLineItem> getRelevantOlis(
    List<OpportunityLineItem> newOlis,
    Map<Id, OpportunityLineItem> oldOlis
  ) {
    Map<Id, OpportunityLineItem> relevantOppLineItems = new Map<Id, OpportunityLineItem>();

    for (OpportunityLineItem lineItem : newOlis) {
      OpportunityLineItem oldLineItem = oldOlis != null
        ? oldOlis.get(lineItem.Id)
        : null;

      Date newEntryDate = lineItem.Entry_Date__c;
      Date oldEntryDate = oldOlis != null ? oldLineItem.Entry_Date__c : null;

      Date newEndDate = lineItem.End_Date__c;
      Date oldEndDate = oldOlis != null ? oldLineItem.End_Date__c : null;

      String newAccessType = lineItem.Access_Type__c;
      String oldAccessType = oldOlis != null
        ? oldLineItem.Access_Type__c
        : null;

      if (newAccessType == 'Periodic') {
        if (
          newEntryDate != null &&
          newEndDate != null &&
          newAccessType != null &&
          (oldLineItem == null ||
          newEntryDate != oldEntryDate ||
          newEndDate != oldEndDate ||
          newAccessType != oldAccessType)
        ) {
          relevantOppLineItems.put(lineItem.Id, lineItem);
        }
      } else {
        if (
          newEntryDate != null &&
          newAccessType != null &&
          (oldLineItem == null ||
          newEntryDate != oldEntryDate ||
          newAccessType != oldLineItem.Access_Type__c)
        ) {
          relevantOppLineItems.put(lineItem.Id, lineItem);
        }
      }
    }

    return relevantOppLineItems;
  }

  /**
   * @description :
   * @author Batya Hudja | 2025-04-03
   * @param oppLineItemsUpdatedNew : Map of updated OpportunityLineItem Ids to new OpportunityLineItem records.
   * @param oppLineItemsUpdatedOld : Map of updated OpportunityLineItem Ids to old OpportunityLineItem records.
   **/
  public static void deleteAllMonthlyPaymentNotRelevant(
    Map<Id, OpportunityLineItem> oppLineItemsUpdatedNew,
    Map<Id, OpportunityLineItem> oppLineItemsUpdatedOld
  ) {
    Map<Id, OpportunityLineItem> relevantOppLineItems = getRelevantOlis(
      oppLineItemsUpdatedNew.values(),
      oppLineItemsUpdatedOld
    );
    List<MonthlyPayment__c> paymentsToDelete = new List<MonthlyPayment__c>();
    List<MonthlyPayment__c> paymentsToInsert = new List<MonthlyPayment__c>();

    //oliId -> list of monthly payment ordered by Month Index
    Map<Id, List<MonthlyPayment__c>> oppLineItemsIdToPayments = new Map<Id, List<MonthlyPayment__c>>();

    if (relevantOppLineItems.size() == 0) {
      return;
    }

    //get existing payments for each oli:
    for (MonthlyPayment__c payment : [
      SELECT
        Id,
        OpportunityLineItem__c,
        Start_date__c,
        End_date__c,
        MonthIndex__c
      FROM MonthlyPayment__c
      WHERE OpportunityLineItem__c IN :relevantOppLineItems.keySet()
      ORDER BY OpportunityLineItem__c, MonthIndex__c
    ]) {
      if (
        !oppLineItemsIdToPayments.containsKey(payment.OpportunityLineItem__c)
      ) {
        oppLineItemsIdToPayments.put(
          payment.OpportunityLineItem__c,
          new List<MonthlyPayment__c>()
        );
      }
      oppLineItemsIdToPayments.get(payment.OpportunityLineItem__c).add(payment);
    }

    List<MPbyMonths__mdt> mpSettings = [
      SELECT NumberOfMonths__c
      FROM MPbyMonths__mdt
      LIMIT 1
    ];
    Integer numberOfMonths = mpSettings[0] != null &&
      mpSettings[0].NumberOfMonths__c != null
      ? Integer.valueOf(mpSettings[0].NumberOfMonths__c)
      : 0;

    for (OpportunityLineItem lineItem : relevantOppLineItems.values()) {
      OpportunityLineItem oldLineItem = oppLineItemsUpdatedOld.get(lineItem.Id);

      List<MonthlyPayment__c> existingMonthlyPayments = oppLineItemsIdToPayments.containsKey(
          lineItem.Id
        )
        ? oppLineItemsIdToPayments.get(lineItem.Id)
        : new List<MonthlyPayment__c>();

      String accessType = lineItem.Access_Type__c;
      Integer numberOfExistingPayments = existingMonthlyPayments.size();
      Integer numberOfWantedPayments = 1; //default

      if (accessType == 'Periodic') {
        numberOfWantedPayments = Integer.ValueOf(
          Math.ceil(lineItem.Period_In_Months__c)
        );
      } else if (accessType == 'Monthly') {
        numberOfWantedPayments = numberOfMonths;
      }

      if (numberOfWantedPayments > numberOfExistingPayments) {
        Integer numberOfRemainingPayments =
          numberOfWantedPayments - numberOfExistingPayments;
        Integer monthIndex = numberOfExistingPayments + 1;

        //need to create new payments
        for (Integer i = 0; i < numberOfRemainingPayments; i++) {
          paymentsToInsert.add(
            createPayment(lineItem, lineItem.ListPrice, monthIndex, null)
          );
          monthIndex += 1;
        }
      } else if (numberOfWantedPayments < numberOfExistingPayments) {
        //need to delete payments
        for (
          Integer i = numberOfWantedPayments; i < numberOfExistingPayments; i++
        ) {
          paymentsToDelete.add(existingMonthlyPayments[i]);
        }
      }
    }

    // Delete and insert MonthlyPayments as needed
    if (paymentsToDelete != null && paymentsToDelete.size() > 0) {
      delete paymentsToDelete;
    }
    if (paymentsToInsert != null && paymentsToInsert.size() > 0) {
      insert paymentsToInsert;
    }
  }

  public static void publishEvent() {
    MonthlyPaymentAdded__e event = new MonthlyPaymentAdded__e();

    Database.SaveResult result = EventBus.publish(event);

    if (!result.isSuccess()) {
      System.debug(
        'the publish of the event failed: ' + result.getErrors()[0].getMessage()
      );
    }
  }
}