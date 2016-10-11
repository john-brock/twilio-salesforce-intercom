/* 
 * API which creates Door Authorization Request upon text message to Twilio number
 * Body param of message holds actual text content. Secret is checked in TwilioDoorController.
 *
 * @author jbrock
 * @date 10/10/2016 
 */
@RestResource(urlMapping='/DoorAuth')
global class TwilioTextApi {

    private static final String FROM_PARAM = 'From';
    private static final String BODY_PARAM = 'Body';
    
    @HttpPost
    global static String doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Map<String, String> params = req.params;
        try {
            Door_Authorization_Request__c authRequest = new Door_Authorization_Request__c(
                Requesting_Phone_Number__c = params.get(FROM_PARAM),
                Auth_Code__c = params.get(BODY_PARAM)
            );
            insert authRequest;
            return 'Success';
        } catch (Exception e) {
            return '500';
        }
    }
    
    @HttpGet
    global static String doGet() {
        // no GET, only POST
        return '500';
    }
}