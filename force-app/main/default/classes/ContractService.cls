/**
 * @description       :The ContractService class manages creating, updating, and deleting monthly payments
 *                      for OrderItem records based on contract details. It recalculates payments and triggers events when new payments are added.
 * @author            : LAURIE CS
 * @group             :
 * @last modified on  : 2024-10-13
 **/
public with sharing class ContractService {
  /**
   * @description : Generates monthly payments for the OrderItems provided in the map.
   * @param orderItemsMap : Map of OrderItem Ids to OrderItem records.
   **/
  public static void generateMonthlyPaymentsRelatedToOrderItems(
    Map<Id, OrderItem> orderItemsMap
  ) {
    List<MPbyMonths__mdt> mpSettings = [
      SELECT NumberOfMonths__c
      FROM MPbyMonths__mdt
      LIMIT 1
    ];
    Integer numberOfMonths = mpSettings.isEmpty() ||
      mpSettings[0].NumberOfMonths__c == null
      ? 0
      : Integer.valueOf(mpSettings[0].NumberOfMonths__c);

    List<OrderItem> orderItemRetrieve = [
      SELECT
        Id,
        ServiceDate,
        Opportunity_Product__c,
        EndDate,
        ListPrice,
        Access_Type__c,
        Contract__c,
        Contract__r.StartDate,
        Contract__r.EndDate,
        Contract__r.Location__c,
        Product2Id
      FROM OrderItem
      WHERE Id IN :orderItemsMap.keySet()
    ];

    List<Id> oppProductList = new List<Id>();
    for (OrderItem orderItem : orderItemRetrieve) {
      if (orderItem.Opportunity_Product__c != null) {
        oppProductList.add(orderItem.Opportunity_Product__c);
      }
    }

    // Fetch related MonthlyPayments and initialize the map
    Map<Id, List<MonthlyPayment__c>> orderItemToMonthlyPaymentsMap = new Map<Id, List<MonthlyPayment__c>>();
    for (MonthlyPayment__c mp : [
      SELECT Id, OpportunityLineItem__c, Discount__c
      FROM MonthlyPayment__c
      WHERE OpportunityLineItem__c IN :oppProductList
      ORDER BY MonthIndex__c ASC
    ]) {
      for (OrderItem orderItem : orderItemRetrieve) {
        if (orderItem.Opportunity_Product__c == mp.OpportunityLineItem__c) {
          if (!orderItemToMonthlyPaymentsMap.containsKey(orderItem.Id)) {
            orderItemToMonthlyPaymentsMap.put(
              orderItem.Id,
              new List<MonthlyPayment__c>()
            );
          }
          orderItemToMonthlyPaymentsMap.get(orderItem.Id).add(mp);
        }
      }
    }

    List<MonthlyPayment__c> allPayments = new List<MonthlyPayment__c>();
    for (OrderItem orderItem : orderItemRetrieve) {
      List<MonthlyPayment__c> newPayments = new List<MonthlyPayment__c>();
      if (orderItemToMonthlyPaymentsMap.containsKey(orderItem.Id)) {
        List<MonthlyPayment__c> paymentsToCopy = orderItemToMonthlyPaymentsMap.get(
          orderItem.Id
        );
        newPayments = generateMonthlyPaymentsForOrderItem(
          orderItem,
          orderItem.ServiceDate,
          true,
          numberOfMonths,
          paymentsToCopy
        );
      } else {
        newPayments = generateMonthlyPaymentsForOrderItem(
          orderItem,
          orderItem.ServiceDate,
          true,
          numberOfMonths,
          null
        );
      }

      allPayments.addAll(newPayments);
    }

    System.debug('allPayments = ' + allPayments);

    if (!allPayments.isEmpty()) {
      insert allPayments;
    }
  }

  /**
   * @description : Generates monthly payments for OrderItems for one year from the current date.
   * @param orderItems : List of OrderItem records.
   **/

  public static void generateMonthlyPaymentsForYearFromCrntDate(
    List<OrderItem> orderItems
  ) {
    List<MPbyMonths__mdt> mpSettings = [
      SELECT NumberOfMonths__c
      FROM MPbyMonths__mdt
      LIMIT 1
    ];
    Integer numberOfMP = (mpSettings.isEmpty() ||
      mpSettings[0].NumberOfMonths__c == null)
      ? 0
      : Integer.valueOf(mpSettings[0].NumberOfMonths__c);

    List<MonthlyPayment__c> existingPayments = [
      SELECT Id, MonthIndex__c, OrderItem__c
      FROM MonthlyPayment__c
      WHERE OrderItem__c IN :orderItems
      ORDER BY OrderItem__c, MonthIndex__c
    ];

    Map<Id, Set<Integer>> existingIndexesByOrderItem = new Map<Id, Set<Integer>>();
    for (MonthlyPayment__c mp : existingPayments) {
      if (!existingIndexesByOrderItem.containsKey(mp.OrderItem__c)) {
        existingIndexesByOrderItem.put(mp.OrderItem__c, new Set<Integer>());
      }
      if (mp.MonthIndex__c != null) {
        existingIndexesByOrderItem.get(mp.OrderItem__c)
          .add(mp.MonthIndex__c.intValue());
      }
    }
    List<MonthlyPayment__c> newPayments = new List<MonthlyPayment__c>();

    for (OrderItem orderItem : orderItems) {
      Date startDate = orderItem.ServiceDate;
      Date terminationDate = orderItem.Contract__r.Contract_Termination_Date__c;
      Integer totalMonths = getCustomPaymentMonthCount(
        startDate,
        terminationDate
      );

      Set<Integer> existingIndexes = existingIndexesByOrderItem.containsKey(
          orderItem.Id
        )
        ? existingIndexesByOrderItem.get(orderItem.Id)
        : new Set<Integer>();

      for (Integer i = 0; i < totalMonths; i++) {
        Integer monthIndex = i + 1;
        if (!existingIndexes.contains(monthIndex)) {
          newPayments.add(
            createPayment(orderItem, orderItem.ListPrice, monthIndex, null)
          );
        }
      }
    }
    if (!newPayments.isEmpty()) {
      upsert newPayments;
    }
  }

  public static Integer getCustomPaymentMonthCount(
    Date startDate,
    Date terminationDate
  ) {
    Date limitDate = Date.today().addMonths(24);
    Date endDate = (terminationDate != null &&
      terminationDate < limitDate)
      ? terminationDate
      : limitDate;
    if (endDate < startDate) {
      return 0;
    }
    Integer months =
      (endDate.year() - startDate.year()) * 12 +
      (endDate.month() - startDate.month()) +
      1;
    if (endDate.day() < startDate.day()) {
      months--;
    }
    return months > 0 ? months : 0;
  }

  /**
   * @description : Generates monthly payments for a single OrderItem.
   * @param orderItem : OrderItem record.
   * @param startDate : Date to start generating payments from.
   * @param isInsert : Boolean indicating if the operation is an insert or update.
   * @return : List of MonthlyPayment__c records.
   **/
  public static List<MonthlyPayment__c> generateMonthlyPaymentsForOrderItem(
    OrderItem orderItem,
    Date startDate,
    Boolean isInsert,
    Integer numberOfMonths,
    List<MonthlyPayment__c> paymentsToCopy
  ) {
    List<MonthlyPayment__c> payments = new List<MonthlyPayment__c>();
    Date currentStart = isInsert
      ? orderItem.ServiceDate
      : getFirstDayOfMonth(startDate);
    Integer monthIndex = 0;
    Decimal listPrice = orderItem.ListPrice;

    Date endDate = (orderItem.EndDate != null)
      ? getLastDayOfMonth(orderItem.EndDate)
      : currentStart.addMonths(1);
    Boolean isFirstMonth = true;

    if (orderItem.Access_Type__c == 'Periodic') {
      if (isInsert) {
        Integer totalDaysInMonth = Date.daysInMonth(
          currentStart.month(),
          currentStart.year()
        );
        Integer remainingDays = totalDaysInMonth - currentStart.day();
        listPrice = (orderItem.ListPrice / totalDaysInMonth) * remainingDays;
      }
      while (currentStart <= endDate) {
        monthIndex++;
        payments.add(
          createPayment(
            orderItem,
            listPrice,
            monthIndex,
            getDiscountFromCopy(paymentsToCopy, monthIndex)
          )
        );
        currentStart = getFirstDayOfMonth(currentStart.addMonths(1));
        listPrice = orderItem.ListPrice;
        isFirstMonth = false;
      }
    } else if (orderItem.Access_Type__c == 'Monthly') {
      for (Integer i = 0; i < numberOfMonths; i++) {
        monthIndex++;
        payments.add(
          createPayment(
            orderItem,
            listPrice,
            monthIndex,
            getDiscountFromCopy(paymentsToCopy, monthIndex)
          )
        );
        currentStart = currentStart.addMonths(1);
      }
    } else {
      payments.add(
        createPayment(
          orderItem,
          listPrice,
          1,
          paymentsToCopy != null ? paymentsToCopy[0].Discount__c : null
        )
      );
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
    return inputDate.toStartOfMonth().addMonths(1).addDays(-1);
  }

  /**
   * @description : Creates a MonthlyPayment__c record based on provided parameters.
   * @param startDate : Start date of the payment period.
   * @param endDate : End date of the payment period.
   * @param orderItem : Associated OrderItem record.
   * @param listPrice : List price for the payment period.
   * @return : A new MonthlyPayment__c record.
   **/
  private static MonthlyPayment__c createPayment(
    OrderItem orderItem,
    Decimal listPrice,
    Integer monthIndex,
    Decimal discount
  ) {
    MonthlyPayment__c payment = new MonthlyPayment__c();
    payment.monthIndex__c = monthIndex;
    payment.OrderItem__c = orderItem.Id;
    payment.Contract__c = orderItem.Contract__c;
    payment.Room__c = orderItem.Product2Id;
    payment.Location__c = orderItem.Contract__r.Location__c;
    payment.Discount__c = discount;
    return payment;
  }

  /**
   * @description : Deletes all MonthlyPayment__c records related to the provided OrderItems.
   * @param orderItemsToDelete : Map of OrderItem Ids to OrderItem records to delete payments for.
   **/
  public static void deleteAllMonthlyPaymentRelatedToOrderItem(
    Map<Id, OrderItem> orderItemsToDelete
  ) {
    delete [
      SELECT Id
      FROM MonthlyPayment__c
      WHERE OrderItem__c IN :orderItemsToDelete.keyset()
    ];
  }

  /**
   * @description : Deletes and re-generates monthly payments for updated OrderItems based on new and old data.
   * @param orderItemsUpdatedNew : Map of updated OrderItem Ids to new OrderItem records.
   * @param orderItemsUpdatedOld : Map of updated OrderItem Ids to old OrderItem records.
   **/
  public static void deleteAllMonthlyPaymentAndRecalculate(
    Map<Id, OrderItem> orderItemsUpdatedNew,
    Map<Id, OrderItem> orderItemsUpdatedOld
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
    deleteAllMonthlyPaymentRelatedToOrderItem(orderItemsUpdatedNew);

    for (OrderItem orderItem : orderItemsUpdatedNew.values()) {
      paymentsToInsert.addAll(
        generateMonthlyPaymentsForOrderItem(
          orderItem,
          orderItem.ServiceDate,
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

  /**
   * @description :
   * @author Batya Hudja | 2025-04-03
   * @param orderLineItemsUpdatedNew : Map of updated OrderItem Ids to new OrderItem records.
   * @param orderLineItemsUpdatedOld : Map of updated OrderItem Ids to old OrderItem records.
   **/
  public static void deleteAllMonthlyPaymentNotRelevant(
    Map<Id, OrderItem> orderLineItemsUpdatedNew,
    Map<Id, OrderItem> orderLineItemsUpdatedOld
  ) {
    Map<Id, OrderItem> relevantOrderItems = getRelevantOrderItems(
      orderLineItemsUpdatedNew.values(),
      orderLineItemsUpdatedOld
    );
    List<MonthlyPayment__c> paymentsToDelete = new List<MonthlyPayment__c>();
    List<MonthlyPayment__c> paymentsToInsert = new List<MonthlyPayment__c>();

    //orderItemId -> list of monthly payment ordered by Month Index
    Map<Id, List<MonthlyPayment__c>> orderItemsIdToPayments = new Map<Id, List<MonthlyPayment__c>>();

    if (relevantOrderItems.size() == 0) {
      return;
    }

    //get existing payments for each orderItem:
    for (MonthlyPayment__c payment : [
      SELECT Id, OrderItem__c, Start_date__c, End_date__c, MonthIndex__c
      FROM MonthlyPayment__c
      WHERE OrderItem__c IN :relevantOrderItems.keySet()
      ORDER BY OrderItem__c, MonthIndex__c
    ]) {
      if (!orderItemsIdToPayments.containsKey(payment.OrderItem__c)) {
        orderItemsIdToPayments.put(
          payment.OrderItem__c,
          new List<MonthlyPayment__c>()
        );
      }
      orderItemsIdToPayments.get(payment.OrderItem__c).add(payment);
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

    for (OrderItem lineItem : relevantOrderItems.values()) {
      OrderItem oldLineItem = orderLineItemsUpdatedOld.get(lineItem.Id);

      List<MonthlyPayment__c> existingMonthlyPayments = orderItemsIdToPayments.containsKey(
          lineItem.Id
        )
        ? orderItemsIdToPayments.get(lineItem.Id)
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

  private static Map<Id, OrderItem> getRelevantOrderItems(
    List<OrderItem> newItems,
    Map<Id, OrderItem> oldItems
  ) {
    Map<Id, OrderItem> relevantOrderItems = new Map<Id, OrderItem>();

    for (OrderItem lineItem : newItems) {
      OrderItem oldLineItem = oldItems != null
        ? oldItems.get(lineItem.Id)
        : null;

      Date newEntryDate = lineItem.ServiceDate;
      Date oldEntryDate = oldLineItem != null ? oldLineItem.ServiceDate : null;

      Date newEndDate = lineItem.EndDate;
      Date oldEndDate = oldLineItem != null ? oldLineItem.EndDate : null;

      String newAccessType = lineItem.Access_Type__c;
      String oldAccessType = oldLineItem != null
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
          relevantOrderItems.put(lineItem.Id, lineItem);
        }
      } else {
        if (
          newEntryDate != null &&
          newAccessType != null &&
          (oldLineItem == null ||
          newEntryDate != oldEntryDate ||
          newAccessType != oldLineItem.Access_Type__c)
        ) {
          relevantOrderItems.put(lineItem.Id, lineItem);
        }
      }
    }

    return relevantOrderItems;
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