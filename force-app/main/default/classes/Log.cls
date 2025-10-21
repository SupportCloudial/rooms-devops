public without sharing class Log {

    private static Log__c log = new Log__c(Body__c = '');
    public static Id insertedLoadId = null;

    public static void add(String message) {
        add(LoggingLevel.DEBUG, message);
    }

    public static void add(LoggingLevel logLevel, String message) {
        log.Body__c += logLevel + ' | ' + message + '\r\n';
        System.debug(logLevel, message);
        if(logLevel == LoggingLevel.ERROR){
            log.Has_Error__c = true;
            log.Error_Message__c = message;
            log.Status__c = 'Error';
        }
    }

    public static void add(Database.Error err) {
        String errorMessage = err.getStatusCode() + ': ' + err.getMessage() + '\r\n';
        errorMessage += 'Fields : ' + err.getFields();
        log.Has_Error__c = true;
        add(LoggingLevel.ERROR, errorMessage);
    }

    public static void add(Exception ex) {
        String errorMessage = ex.getMessage() + '\r\n';
        errorMessage += ex.getStackTraceString();
        log.Has_Error__c = true;
        add(LoggingLevel.ERROR, errorMessage);
    }

    public static void setRelatedOpportunity(String opportunityId) {
        log.Opportunity__c = opportunityId;
    }
    
    public static void setRelatedLead(String leadId) {
        log.Lead__c = leadId;
    }

    public static void setLogName(String logName) {
        log.Name = logName;
    }

    public static void setLogDescription(String description) {
        log.Description__c = description;
    }
    
    public static void setErrorInfo(String errorInfo) {
        log.Error_Info__c = errorInfo;
    }
    
    public static void setStatus(String status) {
        log.Status__c = status;
    }
    
    public static void setObject(String obj) {
        log.Object__c = obj;
    }
    
    public static void insertLog() {
        insert log;
        insertedLoadId = log.Id;
        log = new Log__c(Body__c = '');
    }
}