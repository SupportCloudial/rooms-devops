@isTest
global class BrazeHttpMock implements HttpCalloutMock {

    private Integer statusCode;
    private String status;
    private String responseBody;

    // Constructor to set dynamic values
    public BrazeHttpMock(Integer statusCode, String status, String responseBody){
        this.statusCode = statusCode;
        this.status = status;
        this.responseBody = responseBody;
    }

    // Implement the respond method
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        if(statusCode != 500) {
            res.setStatusCode(statusCode != null ? statusCode : 200);
            res.setStatus(status != null ? status : 'OK');
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody != null ? responseBody : '{"message":"success"}');
        }
        
        return res;
    }

    // Static helper method for convenience
    public static void setMock(Integer statusCode, String status, String responseBody){
        Test.setMock(HttpCalloutMock.class, new BrazeHttpMock(statusCode, status, responseBody));
    }
}