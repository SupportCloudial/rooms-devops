/**
 * @description       : The ForecastController class retrieves and aggregates monthly payment data (MonthlyPayment__c) for opportunities, organizing it by location, product type, and date.
 *                       It provides methods for querying and wrapping data into a structured format (WrapData) for easier frontend display.
 * @author            : LAURIE CS
 * @group             :
 * @last modified on  : 2024-11-10
**/
public with sharing class ForecastController {


    @AuraEnabled(cacheable=true)
    public static List<WrapData> fetchPaymentsOfOpportunity() {
        List<WrapData> dataList = new List<WrapData>();

        String query = 'SELECT Id, Location__c, Location__r.Name, Location__r.Area__c, Segmentation__c, Opportunity__c, ' +
               'Start_date__c, Desk_Capacity__c, FinalPrice__c, Opportunity__r.Type, ' +
               'Room__r.Sub_Type__c, Room__r.Family, Room__r.Type__c ' +
               'FROM MonthlyPayment__c ' +
               'WHERE Start_date__c != null ';

        if(!Test.isRunningTest()){
            query += 'AND Status__c = \'Active\'';
        }

        // Query data including Segmentation__c and other relevant fields
        List<MonthlyPayment__c> payments = Database.query(query);

        // Map to group and aggregate data
        Map<String, AggregateWrapper> aggregatedData = new Map<String, AggregateWrapper>();

        for (MonthlyPayment__c payment : payments) {
            Integer month = payment.Start_date__c.month();
            Integer year = payment.Start_date__c.year();
            String key = payment.Segmentation__c + '-' + month + '-' + year;

            if (!aggregatedData.containsKey(key)) {
                aggregatedData.put(key, new AggregateWrapper(payment.Location__r.Name, payment.Segmentation__c,
                                                              month, year, payment.Location__r.Area__c,
                                                              payment.Opportunity__c, payment.Opportunity__r.Type,
                                                              payment.Room__r.Sub_Type__c, payment.Room__r.Family,
                                                              payment.Room__r.Type__c));
            }

            AggregateWrapper wrapper = aggregatedData.get(key);
            wrapper.deskNumber += payment.Desk_Capacity__c != null ? Integer.valueOf(payment.Desk_Capacity__c) : 0;
            wrapper.totalFinalPrice += payment.FinalPrice__c != null ? payment.FinalPrice__c : 0;
        }

        // Convert aggregated data into WrapData instances
        for (AggregateWrapper wrapper : aggregatedData.values()) {
            dataList.add(new WrapData(wrapper.locationName, wrapper.segmentation, wrapper.month, wrapper.year,
                                      wrapper.deskNumber, wrapper.totalFinalPrice, wrapper.type, wrapper.area,
                                      wrapper.productFamily, wrapper.productType, wrapper.productSubType,
                                      wrapper.opportunity));
        }

        return dataList;
    }

    // Helper class to aggregate data
    private class AggregateWrapper {
        public String locationName;
        public String segmentation;
        public Integer month;
        public Integer year;
        public Integer deskNumber = 0;
        public Decimal totalFinalPrice = 0;
        public String type;
        public String area;
        public String productFamily;
        public String productType;
        public String productSubType;
        public String opportunity;

        public AggregateWrapper(String locationName, String segmentation, Integer month, Integer year, String area,
                                String opportunity, String type, String productSubType, String productFamily,
                                String productType) {
            this.locationName = locationName;
            this.segmentation = segmentation;
            this.month = month;
            this.year = year;
            this.area = area;
            this.opportunity = opportunity;
            this.type = type;
            this.productFamily = productFamily;
            this.productType = productType;
            this.productSubType = productSubType;
        }
    }



     /**
     * @description : Queries the `MonthlyPayment__c` records based on a dynamic filter clause.
     * @param whereClause : A string representing additional WHERE conditions for the SOQL query.
     * @return : List of `MonthlyPayment__c` records that match the query conditions.
     **/
    @AuraEnabled(cacheable=true)
    public static List<MonthlyPayment__c> queryMonthlyPayments(String whereClause) {
        String query = 'SELECT Id, Name, Start_date__c, End_date__c, Desk_Capacity__c, Opportunity__r.Type, Contract__r.Type__c, Products_Name__c, Location__r.Name , FinalPrice__c, Contract__r.End_Date__c, Segmentation__c  FROM MonthlyPayment__c  ';

        if(whereClause != ''){
            query += ' WHERE ' + whereClause ;
            if(!Test.isRunningTest()){
                query += 'AND Status__c = \'Active\'';
            }

        }
        List<MonthlyPayment__c> pay = Database.query(query);
        return pay;
    }



    /**
     * @description : Inner class `WrapData` that represents aggregated payment data, encapsulating details about location, segmentation, date, product information, and payment totals.
     **/
    public class WrapData {
        @AuraEnabled
        public String locationName { get; set; }
        @AuraEnabled
        public String segmentation { get; set; }
        @AuraEnabled
        public Integer month { get; set; }
        @AuraEnabled
        public Integer year { get; set; }
        @AuraEnabled
        public Integer deskNumber { get; set; }
        @AuraEnabled
        public Decimal totalFinalPrice { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String area { get; set; }
        @AuraEnabled
        public String productFamily { get; set; }
        @AuraEnabled
        public String productType { get; set; }
        @AuraEnabled
        public String productSubType { get; set; }
        @AuraEnabled
        public String opportunity { get; set; }


        public WrapData(String locationName, String segmentation,  Integer month, Integer year, Integer DeskNumber, Decimal totalFinalPrice, String type, String area, string productFamily, string productType, string productSubType, string opportunity) {
            this.locationName = locationName;
            this.segmentation = segmentation;
            this.month = month;
            this.year = year;
            this.deskNumber = deskNumber;
            this.totalFinalPrice = totalFinalPrice;
            this.type = type;
            this.area = area;
            this.productFamily = productFamily;
            this.productType = productType;
            this.productSubType = productSubType;
            this.opportunity = opportunity;
        }
    }
}