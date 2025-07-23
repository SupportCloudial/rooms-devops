public without sharing class OpportunityProductController {
  private static String standardOppRecTypeName = 'Standard Opportunity';
  private static String onDemandOppRecTypeName = 'On demand Opportunity';

  private static String standardPrd_ProductType = 'Standard Products';
  private static String onDemandPrd_ProductType = 'On demand Products';
  private static String extraForAllPrd_ProductType = 'Extra for all products';
  private static String extraForMeterPrd_ProductType = 'Extra for meter Products';

  public static final Map<String, Map<String, List<String>>> productTypeAccessTypeByRecordType;

  // Static block to initialize the map when the class is loaded
  //move to cmdt!!
  static {
    productTypeAccessTypeByRecordType = new Map<String, Map<String, List<String>>>();

    // Standard record type
    productTypeAccessTypeByRecordType.put(
      standardOppRecTypeName,
      new Map<String, List<String>>{
        standardPrd_ProductType => new List<String>{ 'Periodic', 'Monthly' },
        onDemandPrd_ProductType => new List<String>{ 'Periodic', 'Monthly' },
        extraForAllPrd_ProductType => new List<String>{ 'Periodic', 'Monthly' },
        extraForMeterPrd_ProductType => new List<String>{
          'Periodic',
          'Monthly'
        }
      }
    );

    // On-demand record type
    productTypeAccessTypeByRecordType.put(
      onDemandOppRecTypeName,
      new Map<String, List<String>>{
        standardPrd_ProductType => new List<String>{},
        onDemandPrd_ProductType => new List<String>{
          'Daily',
          'Hourly',
          'Hourly Multi-Pass',
          'Daily Multi-Pass'
        },
        extraForAllPrd_ProductType => new List<String>{ 'One-Time' },
        'Extra for all products : Parking' => new List<String>{
          'Daily',
          'One-Time'
        }
      }
    );
  }

  @AuraEnabled(cacheable=true)
  public static List<OpportunityProductData> getOppProducts(String oppId) {
    List<OpportunityLineItem> olis = getOpportunityLineItems(oppId);
    Map<Id, List<OrderItem>> existingContractsByProduct = getExistingContracts(
      olis
    );

    List<OpportunityProductData> oppsProductsData = new List<OpportunityProductData>();

    for (OpportunityLineItem oli : olis) {
      OpportunityProductData prdData = new OpportunityProductData(oli);
      if (
        oli.Products_Type__c == 'Standard Products' &&
        oli.Product_Sub_Type__c != 'Hot Desk'
      ) {
        prdData.Availability = getProductAvailabilityForOli(
          oli,
          existingContractsByProduct
        );
      }

      oppsProductsData.add(prdData);
    }

    return oppsProductsData;
  }

  // @AuraEnabled(cacheable=true)
  // public static List<OpportunityProductData> totalTableNotAvailable(String oppId) {
  //     List<OpportunityLineItem> totalNotAvailable = [
  //             SELECT id,
  //             FROM OpportunityLineItem
  //             WHERE Product2.Type__c = 'Standard Products' and Product2.Track_Availability__c = false
  //         ];
  //     return list totalNotAvailable;
  // }

  @AuraEnabled(cacheable=false)
  public static List<OpportunityProductData> getContracts(String oppId) {
    List<OpportunityLineItem> olis = getOpportunityLineItems(oppId);
    Map<Id, List<OrderItem>> existingContractsByProduct = getExistingContracts(
      olis
    );

    Map<Id, List<OpportunityLineItem>> olisByPrdId = new Map<Id, List<OpportunityLineItem>>();
    for (OpportunityLineItem oli : olis) {
      if (!olisByPrdId.containsKey(oli.Product2Id)) {
        olisByPrdId.put(oli.Product2Id, new List<OpportunityLineItem>());
      }
      olisByPrdId.get(oli.Product2Id).add(oli);
    }

    List<OpportunityProductData> oppsProductsData = new List<OpportunityProductData>();

    for (string prdId : existingContractsByProduct.keyset()) {
      for (OrderItem item : existingContractsByProduct.get(prdId)) {
        OpportunityProductData prdData = new OpportunityProductData(item);
        if (olisByPrdId.containsKey(item.Product2Id)) {
          prdData.Availability = getProductAvailabilityForContract(
            item,
            olisByPrdId.get(item.Product2Id)
          );
        }
        oppsProductsData.add(prdData);
      }
    }

    return oppsProductsData;
  }

  private static List<OpportunityLineItem> getOpportunityLineItems(
    string oppId
  ) {
    List<OpportunityLineItem> olis = [
      SELECT
        Id,
        Opportunity.RecordTypeId,
        Opportunity.RecordType.Name,
        Product2Id,
        Product2.Name,
        Product2.Window__c,
        UnitPrice,
        Desk_Count__c,
        Access_Type__c,
        Entry_Date__c,
        End_date__c,
        Products_Type__c,
        Product_Sub_Type__c,
        Quantity,
        TotalPrice,
        Temporary__c,
        Description,
        ListPrice,
        Opportunity.Average_Desk_Price__c,
        Opportunity.Desk_Count_For_Deposit__c,
        Opportunity.Total_List_Amount_For_Standard__c,
        Opportunity.Monthly_Price__c,
        Opportunity.Quantity_Sum__c,
        Opportunity.Total_Price_Non_Standard__c,
        Opportunity.Temporary_Product_Check__c,
        Opportunity.List_Price_Adjustment__c
      FROM OpportunityLineItem
      WHERE OpportunityId = :oppId
    ];
    return olis;
  }

  private static Map<Id, List<OrderItem>> getExistingContracts(
    List<OpportunityLineItem> olis
  ) {
    Id standardOppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get('Standard Opportunity')
      .getRecordTypeId();
    Map<Id, List<OrderItem>> existingContractsByProduct = new Map<Id, List<OrderItem>>();
    List<string> productsIds = new List<string>();

    //get existing contracts for opp products:
    if (
      olis.size() > 0 &&
      olis[0].Opportunity.RecordTypeId == standardOppRecTypeId
    ) {
      for (OpportunityLineItem oli : olis) {
        if (
          oli.Products_Type__c == 'Standard Products' &&
          oli.Product_Sub_Type__c != 'Hot Desk'
        ) {
          productsIds.add(oli.Product2Id);
        }
      }

      if (productsIds.size() > 0) {
        List<OrderItem> orderItems = [
          SELECT
            Id,
            Product2Id,
            Product2.Name,
            Access_Type__c,
            ServiceDate,
            EndDate,
            Contract__r.Account.Name,
            Contract__c,
            Contract__r.ContractNumber,
            Contract__r.Status
          FROM OrderItem
          WHERE Contract__r.Status = 'Activated' AND Product2Id IN :productsIds
        ];

        for (OrderItem item : orderItems) {
          if (!existingContractsByProduct.containsKey(item.Product2Id)) {
            existingContractsByProduct.put(
              item.Product2Id,
              new List<OrderItem>()
            );
          }
          existingContractsByProduct.get(item.Product2Id).add(item);
        }
      }
    }

    return existingContractsByProduct;
  }

  private static string getProductAvailabilityForOli(
    OpportunityLineItem oli,
    Map<Id, List<OrderItem>> existingContractsByProduct
  ) {
    if (!existingContractsByProduct.containsKey(oli.Product2Id)) {
      return Label.PackageBuilder_AvailableStatus;
    }

    //check if there is an other contract for this product between the same dates
    List<OrderItem> existingContracts = existingContractsByProduct.get(
      oli.Product2Id
    );

    for (OrderItem item : existingContracts) {
      if (oli.Entry_Date__c != null && oli.End_date__c != null) {
        if (item.ServiceDate != null && item.EndDate != null) {
          if (
            oli.Entry_Date__c <= item.EndDate &&
            item.ServiceDate <= oli.End_date__c
          ) {
            //overlap
            return Label.PackageBuilder_NotAvailableStatus;
          }
        } else if (item.ServiceDate != null) {
          if (oli.Entry_Date__c >= item.ServiceDate) {
            //overlap
            return Label.PackageBuilder_NotAvailableStatus;
          }
        }
      } else if (oli.Entry_Date__c != null) {
        if (item.ServiceDate != null && item.EndDate != null) {
          if (
            oli.Entry_Date__c >= item.ServiceDate &&
            oli.Entry_Date__c <= item.EndDate
          ) {
            //overlap
            return Label.PackageBuilder_NotAvailableStatus;
          }
        } else if (item.ServiceDate != null) {
          if (oli.Entry_Date__c >= item.ServiceDate) {
            //overlap
            return Label.PackageBuilder_NotAvailableStatus;
          }
        }
      }
    }

    //no overlaping product was found, check if there are contracts but not overlaping
    if (existingContractsByProduct.containsKey(oli.Product2Id)) {
      return Label.PackageBuilder_PartlyAvailableStatus;
    }

    return Label.PackageBuilder_AvailableStatus;

    /*Available:
        'action:approval' / 'utility:success'

        Partly Available:
        'action:priority' / 'utility:warning'

        Not Available:
        'action:close' / 'utility:error' */

    //return 'utility:success';

    //return 'action:approval';
  }

  private static string getProductAvailabilityForContract(
    OrderItem item,
    List<OpportunityLineItem> oppLineItems
  ) {
    for (OpportunityLineItem oli : oppLineItems) {
      if (item.ServiceDate != null && item.EndDate != null) {
        if (oli.Entry_Date__c != null && oli.End_date__c != null) {
          if (
            oli.Entry_Date__c <= item.EndDate &&
            item.ServiceDate <= oli.End_date__c
          ) {
            //overlap
            return Label.PackageBuilder_NotAvailableStatus;
          }
        } else if (oli.Entry_Date__c != null) {
          if (
            oli.Entry_Date__c >= item.ServiceDate &&
            oli.Entry_Date__c <= item.EndDate
          ) {
            //overlap
            return Label.PackageBuilder_NotAvailableStatus;
          }
        }
      } else if (item.ServiceDate != null) {
        if (oli.Entry_Date__c != null && oli.End_date__c != null) {
          if (
            oli.Entry_Date__c >= item.ServiceDate ||
            oli.End_date__c >= item.ServiceDate
          ) {
            //overlap
            return Label.PackageBuilder_NotAvailableStatus;
          }
        } else if (oli.Entry_Date__c != null) {
          if (oli.Entry_Date__c >= item.ServiceDate) {
            //overlap
            return Label.PackageBuilder_NotAvailableStatus;
          }
        }
      }
    }
    return Label.PackageBuilder_PartlyAvailableStatus;
  }

  @AuraEnabled
  public static UpdateRecordResult saveLineItems(
    string recordTypeName,
    List<string> oliIds,
    List<OpportunityLineItem> lineItems
  ) {
    Map<String, Map<String, String>> recordFieldErrors = new Map<String, Map<String, String>>();

    UpdateRecordResult result = new UpdateRecordResult();

    //select relevant data for validation:
    Map<Id, OpportunityLineItem> lineItemsBeforeUpdate = new Map<Id, OpportunityLineItem>(
      [
        SELECT
          Id,
          Access_Type__c,
          Product_Type__c,
          Product_Sub_Type__c,
          End_date__c,
          Quantity,
          UnitPrice,
          Temporary__c
        FROM OpportunityLineItem
        WHERE Id IN :oliIds
      ]
    );

    //validate records:
    for (OpportunityLineItem lineItem : lineItems) {
      OpportunityLineItem oliFromDB = lineItemsBeforeUpdate.get(lineItem.Id);

      Map<String, String> recordErrors = recordValidations(
        recordTypeName,
        lineItem,
        oliFromDB
      );

      if (!recordErrors.isEmpty()) {
        recordFieldErrors.put(lineItem.Id, recordErrors);
      } else {
        //fix this bug: https://help.salesforce.com/s/articleView?id=000381172&type=1
        Map<String, Object> populatedFields = lineItem.getPopulatedFieldsAsMap();

        if (
          populatedFields.containsKey('Quantity') &&
          !populatedFields.containsKey('UnitPrice')
        ) {
          lineItem.UnitPrice = oliFromDB.UnitPrice;
        }
      }
    }

    try {
      //update only if there are no errors
      if (recordFieldErrors.isEmpty()) {
        update lineItems;
        result.hasErrors = false;

        publishEvent();
      } else {
        result.hasErrors = true;
        result.recordErrors = recordFieldErrors;
        result.errorType = 'recordError';
      }
    } catch (DmlException e) {
      recordFieldErrors.put(
        'table',
        new Map<String, String>{ 'Error' => e.getDmlMessage(0) }
      );
      result.hasErrors = true;
      result.recordErrors = recordFieldErrors;
      result.errorType = 'tableError';
    }

    return result;
  }

  private static Map<String, String> recordValidations(
    String recordTypeName,
    OpportunityLineItem lineItem,
    OpportunityLineItem oliFromDB
  ) {
    Map<String, String> recordFieldErrors = new Map<String, String>(); //recordId -> fieldName -> error

    Map<String, Object> populatedFields = lineItem.getPopulatedFieldsAsMap();

    String accessType = oliFromDB.Access_Type__c;

    if (populatedFields.containsKey('Access_Type__c')) {
      //get access type:
      accessType = lineItem.Access_Type__c;

      //access type validation - check if new access type is allowed for record type:
      if (
        !String.isBlank(lineItem.Access_Type__c) &&
        !isValidAccessType(
          productTypeAccessTypeByRecordType,
          recordTypeName,
          oliFromDB.Product_Type__c,
          oliFromDB.Product_Sub_Type__c,
          lineItem.Access_Type__c
        )
      ) {
        recordFieldErrors.put(
          'AccessType',
          System.Label.PackageBuilder_AccessTypeError
        );
      }
    }

    //validations for for standard record type
    if (recordTypeName == standardOppRecTypeName) {
      if (populatedFields.containsKey('End_date__c')) {
        if (
          lineItem.End_date__c != oliFromDB.End_date__c &&
          lineItem.End_date__c != null &&
          accessType != 'Periodic'
        ) {
          recordFieldErrors.put(
            'EndDate',
            System.Label.PackageBuilder_EndDateError
          );
        }
      }

      if (populatedFields.containsKey('Quantity')) {
        if (
          lineItem.Quantity != oliFromDB.Quantity &&
          lineItem.Quantity != null &&
          oliFromDB.Product_Type__c == 'Standard Products'
        ) {
          recordFieldErrors.put(
            'Quantity',
            System.Label.PackageBuilder_QuantityError1
          );
        }
      }

      if (populatedFields.containsKey('Temporary__c')) {
        if (
          lineItem.Temporary__c != oliFromDB.Temporary__c &&
          (oliFromDB.Product_Type__c != 'Standard Products' ||
          accessType != 'Periodic')
        ) {
          recordFieldErrors.put(
            'Temporary',
            System.Label.PackageBuilder_TemporaryError
          );
        }
      }
    } else if (recordTypeName == onDemandOppRecTypeName) {
      if (populatedFields.containsKey('Quantity')) {
        if (lineItem.Quantity != oliFromDB.Quantity && accessType == 'Daily') {
          recordFieldErrors.put(
            'Quantity',
            System.Label.PackageBuilder_QuantityError2
          );
        }
      }
    }

    return recordFieldErrors;
  }

  private static Boolean isValidAccessType(
    Map<String, Map<String, List<String>>> productTypeAccessTypeByRecordType,
    string recordTypeName,
    string productType,
    string subProductType,
    string accessType
  ) {
    //check for both - record type -> product type -> list of allowed access type
    //and - if there is an additional access type fpr a specific product sub type

    Boolean isValidAccessType = false;
    isValidAccessType = (productTypeAccessTypeByRecordType.containsKey(
      recordTypeName
    ) &&
    productTypeAccessTypeByRecordType.get(recordTypeName)
      .containsKey(productType) &&
    productTypeAccessTypeByRecordType.get(recordTypeName)
      .get(productType)
      .contains(accessType));

    if (!isValidAccessType) {
      //check for additional access types for product sub type:

      string productTypeAndSub = productType + ' : ' + subProductType;
      isValidAccessType = (productTypeAccessTypeByRecordType.containsKey(
        recordTypeName
      ) &&
      productTypeAccessTypeByRecordType.get(recordTypeName)
        .containsKey(productTypeAndSub) &&
      productTypeAccessTypeByRecordType.get(recordTypeName)
        .get(productTypeAndSub)
        .contains(productTypeAndSub));
    }

    return isValidAccessType;
  }

  @AuraEnabled
  public static string deleteLineItems(List<Id> itemIds) {
    try {
      if (itemIds == null || itemIds.isEmpty()) {
        return 'No items to delete';
      }

      // Query OpportunityLineItems to ensure they exist before deleting
      List<OpportunityLineItem> itemsToDelete = [
        SELECT Id
        FROM OpportunityLineItem
        WHERE Id IN :itemIds
      ];

      if (!itemsToDelete.isEmpty()) {
        delete itemsToDelete;
        publishEvent();
        return 'Success';
      }
      return 'No items to delete';
    } catch (DmlException e) {
      System.debug('Error deleting OpportunityLineItems: ' + e.getMessage());
      return e.getMessage();
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

  public class OpportunityProductData {
    @AuraEnabled
    public string oppRecordTypeId { get; set; }
    @AuraEnabled
    public string oppRecordTypeName { get; set; }
    @AuraEnabled
    public string LineItemId { get; set; }
    @AuraEnabled
    public string Name { get; set; }
    @AuraEnabled
    public Decimal UnitPrice { get; set; }
    @AuraEnabled
    public Decimal DeskCount { get; set; }
    @AuraEnabled
    public string AccessType { get; set; }
    @AuraEnabled
    public Date EntryDate { get; set; }
    @AuraEnabled
    public Date EndDate { get; set; }
    @AuraEnabled
    public Decimal Quantity { get; set; }
    @AuraEnabled
    public Decimal TotalPrice { get; set; }
    @AuraEnabled
    public Decimal ListPrice { get; set; }
    @AuraEnabled
    public Boolean ExternalRoom { get; set; }
    @AuraEnabled
    public Boolean Temporary { get; set; }
    @AuraEnabled
    public string Description { get; set; }
    @AuraEnabled
    public string Availability { get; set; }
    @AuraEnabled
    public string ContractId { get; set; }
    @AuraEnabled
    public string ContractName { get; set; }
    @AuraEnabled
    public Decimal oppAverageDeskPrice { get; set; }
    @AuraEnabled
    public Decimal oppDesks { get; set; }
    @AuraEnabled
    public Decimal oppListPriceSum { get; set; }
    @AuraEnabled
    public Decimal oppMonthlyPrice { get; set; }
    @AuraEnabled
    public Decimal oppQuantitySum { get; set; }
    @AuraEnabled
    public Decimal oppTotalPriceNonStandard { get; set; }
    @AuraEnabled
    public Decimal oppListPriceAdjustment { get; set; }
    @AuraEnabled
    public string oppTemporaryProductCheck { get; set; }

    public OpportunityProductData(OpportunityLineItem prod) {
      this.oppRecordTypeId = prod.Opportunity.RecordTypeId;
      this.oppRecordTypeName = prod.Opportunity.RecordType.Name;
      this.oppAverageDeskPrice = prod.Opportunity.Average_Desk_Price__c;
      this.oppDesks = prod.Opportunity.Desk_Count_For_Deposit__c;
      this.oppListPriceSum = prod.Opportunity.Total_List_Amount_For_Standard__c;
      this.oppMonthlyPrice = prod.Opportunity.Monthly_Price__c;
      this.oppQuantitySum = prod.Opportunity.Quantity_Sum__c;
      this.oppTotalPriceNonStandard = prod.Opportunity.Total_Price_Non_Standard__c;
      this.oppListPriceAdjustment = prod.Opportunity.List_Price_Adjustment__c;
      this.oppTemporaryProductCheck = prod.Opportunity.Temporary_Product_Check__c;
      this.LineItemId = prod.Id;
      this.Name = prod.Product2.Name;
      this.UnitPrice = prod.UnitPrice;
      this.DeskCount = prod.Desk_Count__c;
      this.AccessType = prod.Access_Type__c;
      this.EntryDate = prod.Entry_Date__c;
      this.EndDate = prod.End_date__c;
      this.Quantity = prod.Quantity;
      this.TotalPrice = prod.TotalPrice;
      this.ListPrice = prod.ListPrice;
      this.ExternalRoom = prod.Product2.Window__c;
      this.Temporary = prod.Temporary__c;
      this.Description = prod.Description;
      this.Availability = 'Not Relevant';
    }

    public OpportunityProductData(OrderItem prod) {
      this.LineItemId = prod.Id;
      this.Name = prod.Product2.Name;
      this.AccessType = prod.Access_Type__c;
      this.EntryDate = prod.ServiceDate;
      this.EndDate = prod.EndDate;
      this.Availability = 'Not Relevant';
      this.ContractId = prod.Contract__c;
      this.ContractName =
        prod.Contract__r.ContractNumber +
        ' - ' +
        prod.Contract__r.Account.Name;
    }
  }

  public class UpdateRecordResult {
    @AuraEnabled
    public Boolean hasErrors { get; set; }

    @AuraEnabled
    public String errorType { get; set; } //tableError / recordError

    @AuraEnabled
    public Map<String, Map<String, String>> recordErrors { get; set; }
  }
}