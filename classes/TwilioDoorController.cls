/* 
 * Controller to return the following TwiML (XML) upon call from intercom system
 * --> call is forwarded if there isn't a valid Door Authorization Request
 * --> door is auto-opened if there is a valid request
 *
 * @author jbrock
 * @date 10/10/2016
 *
    <?xml version="1.0" encoding="UTF-8"?>
    <Response>
        <Sms to="+15554443333">Call from JB's front door.</Sms>
        <Dial timeout="20">+15554443333</Dial>
        OR
        <Play digits="ww6"/>
    </Response>
 *
 */
public class TwilioDoorController {

    private static final String CONFIG_DEV_NAME = 'JB_Loft';
    
    private final Door_Authorization_Request__c authRequest;
    private final String secretAuthCode;
    private final String alertText;
    private final String doorOpenedText;
    private final String targetCell;
    private final String digitsToOpen;
    
    public TwilioDoorController() {
        Twilio_Door_Config__mdt config = getConfigSettings();
        secretAuthCode = config.Secret_Auth_Code__c;
        alertText = config.Sms_Alert_Text__c;
        doorOpenedText = config.Door_Opened_Text__c;
        targetCell = config.Target_Phone_Number__c;
        digitsToOpen = config.Digits_to_Open__c;
        
        authRequest = getAuthRequest();
    }
    
    /*
     * Returns a Twilio_Door_Config__mdt with Dev Name matching CONFIG_DEV_NAME.
     */
    private Twilio_Door_Config__mdt getConfigSettings() {
        Twilio_Door_Config__mdt config = [
            SELECT Digits_to_Open__c, Secret_Auth_Code__c, Door_Opened_Text__c, Sms_Alert_Text__c, Target_Phone_Number__c 
             FROM Twilio_Door_Config__mdt
             WHERE DeveloperName =: CONFIG_DEV_NAME
        ];
        return config;
    }
    
    /*
     * Returns a Door_Authorization_Request__c if a valid request is found.
     * If no valid requests are found, null is returned.
     */
    private Door_Authorization_Request__c getAuthRequest() {
        // Find request that hasn't been used, within time range, and with correct auth code
        List<Door_Authorization_Request__c> requests = [
            SELECT Id, Auth_Code__c, Has_Been_Used__c
             FROM Door_Authorization_Request__c
             WHERE Within_Time_Range__c = True 
                    AND Has_Been_Used__c = FALSE
                    AND Auth_Code__c =: secretAuthCode
             LIMIT 1
        ];
        // Return the request if one is found, otherwise return null
        if (requests.size() == 1) {
            return requests.get(0);
        }
        return null;
    }
    
    /*
     * Builds the TwiML which is returned to Twilio for execution
     */
    public String getTwiml() {
        TwilioTwiML.Response res = new TwilioTwiML.Response();
        buildAndAddSmsTwiml(res, alertText);
        buildAndAddActionTwiml(res);
        return res.toXML();
    }
    
    /*
     * Marks the Door Authorization Request as used if it was used to build an auto-auth TwiML.
     * Ensures the requests are use-once and only once.
     * This should be called from the constructor when request is found, but no DML in constructors,
     * thus, this is called via a VF action method.
     */
    public PageReference markAuthRequestUsed() {
        if (null != authRequest) {
            authRequest.Has_Been_Used__c = True;
            try {
                update authRequest;            
            } catch (Exception e) {
                System.debug(e);
            }
        }
        return null;
    }
    
    private void buildAndAddSmsTwiml(TwilioTwiML.Response res, String smsText) {
        TwilioTwiML.Sms sms = new TwilioTwiML.Sms(smsText);
        sms.setTo(targetCell);
        res.append(sms);
    }
    
    private void buildAndAddActionTwiml(TwilioTwiML.Response res) {
        if (null != authRequest) {
            res.append(buildOpenTwiml());
            buildAndAddSmsTwiml(res, doorOpenedText);
        } else {
            res.append(buildCallForwardTwiml());            
        }
    }
    
    private TwilioTwiML.Play buildOpenTwiml() {
        TwilioTwiML.Play play = new TwilioTwiML.Play('');
        play.setDigits(digitsToOpen);
        return play;
    }
    
    private TwilioTwiML.Dial buildCallForwardTwiml() {
        TwilioTwiML.Dial dial = new TwilioTwiML.Dial(targetCell);
        dial.setTimeout(20);
        return dial;
    }
}