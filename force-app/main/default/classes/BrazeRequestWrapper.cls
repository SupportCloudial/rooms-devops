public class BrazeRequestWrapper {
    public List<Attribute> attributes;
    public List<Event> events;
    
    // Constructor — builds payload based on record type
    public BrazeRequestWrapper() {
        attributes = new List<Attribute>();
        events = new List<Event>();
    }

    public class Attribute {
        public String external_id;
        public String first_name;
        public String last_name;
        public String email;
        public String phone;
        public String time_zone;
        public String lead_status;
        public String lost_reason;
        public String desired_location;
        public String email_subscribe;
        public String sms_subscribe;
        public Datetime first_lead_date;
        
        public Attribute(
            Lead lead, String recordType, List<Opportunity> oppList
        ) {
            this.external_id = lead.MobilePhone;
            this.first_name = lead.FirstName;
            this.last_name = lead.LastName;
            this.email = lead.Email;
            this.phone = lead.MobilePhone;
            this.time_zone = UserInfo.getTimeZone().getID();
            this.first_lead_date = lead.CreatedDate;
            this.desired_location = lead.Desired_Location__c != null ? lead.Desired_Location__r.Name : '';
            this.lead_status = lead.Status;
            this.email_subscribe = lead.HasOptedOutOfEmail ? 'unsubscribed' : 'opted_in';
            this.sms_subscribe = lead.HasOptedOutOfFax ? 'unsubscribed' : 'opted_in';
            if(recordType == 'Opportunity' && oppList[0].StageName == 'Closed Lost') {
                this.lost_reason = oppList[0].Loss_Reason__c;
            }
        }
    }

    public class Event {
        public String external_id;
        public String name;
        public Datetime event_time;
        public Map<String, String> properties;
        
        public Event (
            Lead lead, String recordType, List<Opportunity> oppList
        ) {
            this.external_id = lead.MobilePhone;
            this.event_time = System.now();
            if(recordType == 'Opportunity' && !oppList.isEmpty()) {
                this.properties = new Map<String,String>{ 'opportunity_stage' => oppList[0].StageName };
                    
                if(oppList[0].StageName == 'Closed Won') {
                    this.name = 'opportunity_closed_won';
                }else if(oppList[0].StageName == 'Closed Lost') {
                    this.name = 'opportunity_closed_lost';
                }
            }else if(recordType == 'Lead') {
                this.name = 'lead_status_changed';
                this.properties = new Map<String,String>{ 'new_status' => lead.Status };
            }
        }
    }
}