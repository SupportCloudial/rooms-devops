public without sharing class AddOppProductController {

    @AuraEnabled(cacheable=true)
    public static List<ProductData> getProductsByOppLocation(string oppId){
        Opportunity opp = [SELECT Id, RecordTypeId, RecordType.Name, Location__c FROM Opportunity WHERE Id = :oppId];

        String location = opp.Location__c;

        String baseQuery = 'SELECT Id, Name, Product2Id, Capacity_Desks__c, UnitPrice, Floor__c, Window__c, Calculated_Price__c, Product2.Type__c, Product2.Sub_Type__c, Product2.State__c ' +
                           'FROM PricebookEntry ' +
                           'WHERE Product2.Location__c = :location';

        if (opp.RecordType.Name == 'Series Opportunity' || opp.RecordType.Name == 'On demand Opportunity') {
            baseQuery += ' AND (Product2.Type__c = \'On demand Products\' OR Product2.Type__c = \'Extra for all products\')';
        } 
            
        List<PricebookEntry> pricebookEntries = Database.query(baseQuery);
        
        Set<Id> existingContractsByProduct = getExistingContracts(pricebookEntries);

        List<ProductData> productsData = new List<ProductData>();

        for(PricebookEntry pbe : pricebookEntries){
            ProductData prdData = new ProductData(pbe);
            
            if(pbe.Product2.Type__c == 'Standard Products' && pbe.Product2.Sub_Type__c != 'Hot Desk'){
                if(existingContractsByProduct.contains(pbe.Product2Id)){
                    prdData.Availability = '⚠️';
                }else{
                    prdData.Availability = '🟢';
                }
            }
            productsData.add(prdData);
        }

        return productsData;
    }

    private static Set<Id> getExistingContracts(List<PricebookEntry> pbes){
        Set<Id> existingContractsByProduct = new Set<Id>();
        List<string> productsIds = new List<string>();

        //get existing contracts for products:
        for(PricebookEntry pbe : pbes){
            if(pbe.Product2.Type__c == 'Standard Products' && pbe.Product2.Sub_Type__c != 'Hot Desk'){
                productsIds.add(pbe.Product2Id);
            }
        }

        if(productsIds.size() > 0){
            List<OrderItem> orderItems = [  SELECT Id, Product2Id, Product2.Name, Access_Type__c, ServiceDate, EndDate, Contract__r.Account.Name, Contract__c, Contract__r.ContractNumber,Contract__r.Status 
                                            FROM OrderItem 
                                            WHERE Contract__r.Status = 'Activated' AND Product2Id in :productsIds];

            for(OrderItem item : orderItems){
                existingContractsByProduct.add(item.Product2Id);
            }
        }

        return existingContractsByProduct;
    }

    @AuraEnabled
    public static String addProductsToOpp(List<String> productEntryIds, string opportunityId){
        //call flow - Prepare input variables
        Map<String, Object> inputVariables = new Map<String, Object>();
        inputVariables.put('InputVarProductEntryIds', productEntryIds);
        inputVariables.put('InputVarOportuntiyId', opportunityId);

        // The flow interview class should exist for your flow name
        Flow.Interview.Opportunity_Package_Builder_Manage_Opportunity_Products_2_0 flowInterview = new Flow.Interview.Opportunity_Package_Builder_Manage_Opportunity_Products_2_0(inputVariables);

        // Start the flow
        flowInterview.start();

        if(flowInterview.AddErrorMessage != null){
            return flowInterview.AddErrorMessage;
        }
        return '';
    }

    public class ProductData {
        @AuraEnabled
        public string Id {get; set;}
        @AuraEnabled
        public string Name {get; set;}
        @AuraEnabled
        public Decimal CapacityDesks {get; set;}
        @AuraEnabled
        public Decimal UnitPrice {get; set;}
        @AuraEnabled
        public Decimal Floor {get; set;}
        @AuraEnabled
        public Boolean Window {get; set;}
        @AuraEnabled
        public Decimal CalculatedPrice {get; set;}
        @AuraEnabled
        public string ProductType {get; set;}
        @AuraEnabled
        public string ProductSubType {get; set;}
        @AuraEnabled
        public string ProductState {get; set;}
        @AuraEnabled
        public string Availability {get; set;}
        
        public ProductData(PricebookEntry prod){
            this.Id = prod.Id;
            this.Name = prod.Name;
            this.CapacityDesks = prod.Capacity_Desks__c;
            this.UnitPrice = prod.UnitPrice;
            this.Floor = prod.Floor__c;
            this.Window = prod.Window__c;
            this.CalculatedPrice = prod.Calculated_Price__c;
            this.ProductType = prod.Product2.Type__c;
            this.ProductSubType = prod.Product2.Sub_Type__c;
            this.ProductState = prod.Product2.State__c;
            this.Availability = '';
        }
    }
}