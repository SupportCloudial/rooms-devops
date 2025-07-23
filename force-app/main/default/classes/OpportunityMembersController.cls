public without sharing class OpportunityMembersController {
    @AuraEnabled
    public static Contract getNumberOfMembers(Id contractsId) {
        Contract cont = [SELECT Id, Name, Members_Registred__c, 
                                (SELECT Number_of_members__c, AccountId, main_contact__c, Contract_language__c FROM Opportunities) 
                                 FROM Contract WHERE Id = :contractsId Limit 1]; 
      
        if (cont.Opportunities != null && !cont.Opportunities.isEmpty()) {
            System.debug('@@@cont.Opportunities: '+cont.Opportunities);
            return cont; // return the object Contract
        } else {
            return null; // don't have opp ratached with contracts
        }    
    }


    @AuraEnabled 
    public static String saveContacts(List<Contact> contacts, String idContract) {
        List<Contact> newContacts = new List<Contact>();

        List<String> contactEmails = new List<String>();
        List<Contact> contactsExist = new List<Contact>();
        List<Contact> contactsNotExist = new List<Contact>();

        for (Contact contact : contacts) {
            // check if contact exist
            contactEmails.add(contact.Email);
        }

        List<String> existingEmails = new List<String>();
        List<String> notExistingEmail = new List<String>();
        List<Id> idExist = new List<Id>();
        Map <String,Integer> emailCounter = new Map<String, Integer>();

        checkContactExists(idExist, emailCounter, contactEmails , existingEmails , notExistingEmail );
 
        
        // System.debug(existingEmails);
        // System.debug(notExistingEmail);
        // System.debug(idExist);

        for (Contact contact : contacts) {
            if (existingEmails.contains(contact.Email)) {
                contactsExist.add(contact);
            } else {
                contactsNotExist.add(contact);
            }
        }

        if (!contactsNotExist.isEmpty() || !contactsExist.isEmpty() ) {    
            try {            
               // System.debug(idContract + 'show id');
                for (Contact contact : contactsNotExist) {
                    contact.Contact_from_member_registration_page__c = true;
                }
                insert contactsNotExist;
               
                Contract contract = new Contract(
                    Id = idContract,
                    Members_Registred__c = true 
                );      
                update contract;

              //  System.debug('idExist: ' + idExist);

                SendTableMembersEmail(idExist, emailCounter, contactsNotExist, contactsExist, idContract);

                return 'Success';
            } catch (Exception e) {
                return 'Error' ;
            }
        } else {
            return 'Success';
        }
    }   


    public static void checkContactExists(List <id> idExist, Map<String,Integer> emailCounter, List<String> emails, List<String> existingEmails, List<String> notExistingEmail) {
        List<Contact> existingContacts = [SELECT Id, Email FROM Contact WHERE Email IN :emails Order by Email ];
        String previousEmail = null;
        for (Contact contact : existingContacts) {
            if (!emailCounter.containsKey(contact.Email)) {
                emailCounter.put(contact.Email, 1);
            } else {
                emailCounter.put(contact.Email, emailCounter.get(contact.Email) +1 );
            }
            String currentEmail = contact.Email;
            if (currentEmail == previousEmail) {
                continue;
            }
            existingEmails.add(contact.Email);
            idExist.add(contact.Id);
            previousEmail = currentEmail;
        }
      
      //  System.debug(emailCounter);
        for (String email : emails) {
            if (!existingEmails.contains(email)) {
                notExistingEmail.add(email);
            }
        }
    }


    public static void SendTableMembersEmail(List <Id> idExist,  Map<String,Integer> emailCounter, List<Contact> contactsNotExist, List<Contact> contactsExist, String idContract) {
        Contract con = [SELECT Id, Locations__r.Name, StartDate, EndDate, Main_contact__r.Name, Main_contact__r.Email, Account.Name, Account.Phone FROM Contract WHERE Id = :idContract ];

        List<String> recipientEmails = new List<String>();
        String convertStartDate = String.valueOf(con.StartDate);
        String convertEndDate = String.valueOf(con.EndDate);

        if(convertEndDate == null){
            convertEndDate = 'N/A';
        }
        if(convertStartDate == null){
            convertEndDate = 'N/A';
        }
        if(con.Account.Phone == null){
            con.Account.Phone = 'N/A';
        }

        String locationName = con.Locations__r.Name;

        // get mail from metadata to send the email
        for (Rooms_recipient_for_members_registered__mdt recipient : [SELECT Recipient__c, Active__c FROM Rooms_recipient_for_members_registered__mdt WHERE Active__c = true AND (Location__c = :locationName OR Location__c = null)]) {
            recipientEmails.add(recipient.Recipient__c);
        }
    
        if (recipientEmails.isEmpty()) {
            return;
        }
    
        //  System.debug(idExist);
        String tableHtml = '<table style="border-collapse: collapse;">' +
                            '<thead><tr>' +
                            '<th style="border: 1px solid black; padding: 2px;">N° Members</th>' +
                            '<th style="border: 1px solid black; padding: 6px;">Last Name</th>' +
                            '<th style="border: 1px solid black; padding: 6px;">First Name</th>' +
                            '<th style="border: 1px solid black; padding: 6px;">Phone</th>' +
                            '<th style="border: 1px solid black; padding: 7px;">Email</th>' +
                            '<th style="border: 1px solid black; padding: 5px;">Birthdate</th>' +
                            '<th style="border: 1px solid black; padding: 5px;">Link to contact on SF</th>' +
                            '</tr></thead><tbody>';
    
        Integer memberCountContactExist = 1;
        //String orgUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String fullFileURL = URL.getOrgDomainURL().toExternalForm();
        String textContact = 'Multiple contacts found';
        //  System.debug(contactsExist);
        List< string>  emaille = new list<string> ();
        for (Contact contactExist : contactsExist) {
            emaille.add(contactExist.Email); // Accès au champ Email de l'objet Contact
        //   System.debug('Email: ' + emaille); // Afficher l'email dans les logs de débogage
        }
        List<Contact> existingContacts2 = [SELECT Id, Email FROM Contact WHERE Email IN :emaille ];
        String previousEmail = null;
        for (Contact contact : existingContacts2) {
            String currentEmail = contact.Email;
            if (currentEmail == previousEmail) {
                continue;
            }
            contactsExist.add(contact);
            previousEmail = currentEmail;
        }
        // System.debug(existingContacts2);
        // System.debug(System.Label.Phone);
        // System.debug(label.Phone);

        String lienHtml = null;
        for (Integer i = 0; i < contactsExist.size() && i < idExist.size(); i++) {
            Contact contactExist = contactsExist[i];

            //  System.debug('before:' + contactExist.Email);
            String memberNumber = String.valueOf(memberCountContactExist++);
            String lastName = contactExist.LastName != null ? contactExist.LastName : '';
            String firstName = contactExist.FirstName != null ? contactExist.FirstName : '';
            String phone = contactExist.MobilePhone != null ? contactExist.MobilePhone : '';
            String email = contactExist.Email != null ? contactExist.Email : '';
            String birthdate = contactExist.Birthdate != null ? String.valueOf(contactExist.Birthdate) : 'N/A';

            if (emailCounter.get(contactExist.Email) > 1) {
                lienHtml = label.MultipleContact;
            } else {
                String idTest = idExist[i];
                String urlAvecChemin = fullFileURL + '/' + idTest;
                lienHtml = '<a href="' + urlAvecChemin + '">Click here</a>'; 
            }  
            //  System.debug('after: ' + contactExist.Email); 
            tableHtml += '<tr>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + memberNumber + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + lastName + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + firstName + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + phone + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + email + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + birthdate + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + lienHtml + '</td>' +
                        '</tr>';
        }
  
        tableHtml += '</tbody></table>';

        String tableHtmlContactNotExist = '<table style="border-collapse: collapse;">' +
                                            '<thead><tr>' +
                                            '<th style="border: 1px solid black; padding: 2px;">N° Members</th>' +
                                            '<th style="border: 1px solid black; padding: 6px;">Last Name</th>' +
                                            '<th style="border: 1px solid black; padding: 6px;">First Name</th>' +
                                            '<th style="border: 1px solid black; padding: 6px;">Phone</th>' +
                                            '<th style="border: 1px solid black; padding: 7px;">Email</th>' +
                                            '<th style="border: 1px solid black; padding: 5px;">Birthdate</th>' +
                                            '<th style="border: 1px solid black; padding: 5px;">Link to contact on SF</th>' +
                                            '</tr></thead><tbody>';

        Integer memberCountContactNotExist = 1;

        for (Contact contactNotExist : contactsNotExist) {

            String memberNumber = String.valueOf(memberCountContactNotExist++);
            String lastName = contactNotExist.LastName != null ? contactNotExist.LastName : '';
            String firstName = contactNotExist.FirstName != null ? contactNotExist.FirstName : '';
            String phone = contactNotExist.MobilePhone != null ? contactNotExist.MobilePhone : '';
            String email = contactNotExist.Email != null ? contactNotExist.Email : '';
            String birthdate = contactNotExist.Birthdate != null ? String.valueOf(contactNotExist.Birthdate) : 'N/A';
            String idSexistCRM = contactNotExist.Id != null ? contactNotExist.Id : 'N/A';
            String urlAvecChemin1 = fullFileURL + '/' + idSexistCRM;
            String lienHtml1 = '<a href="' + urlAvecChemin1 + '">Click here</a>';   

            tableHtmlContactNotExist += '<tr>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + memberNumber + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + lastName + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + firstName + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + phone + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + email + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + birthdate + '</td>' +
                        '<td style="border: 1px solid black; padding: 5px;">' + lienHtml1 + '</td>' +
                        '</tr>';
        }


        tableHtmlContactNotExist += '</tbody></table>';

        OrgWideEmailAddress  Orgwid =[SELECT Id, Address, DisplayName, IsAllowAllProfiles FROM  OrgWideEmailAddress  LIMIT 1];

        EmailTemplate theTemplate = [SELECT Id, DeveloperName, Body, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = 'Send_member_registered_to_CM_1722837394040'];

        String mailBody = String.valueOf(theTemplate.HtmlValue.replace('[company name]',con.Account.Name).replace('[Contract_start_date]', convertStartDate).replace('[End_date]', convertEndDate).replace('[main_contact__r.Name]', con.Main_contact__r.Name).replace('[main_contact__r.MobilePhone]', con.Account.Phone).replace('[Email]',con.Main_contact__r.Email).replace('[TableauMembers]', tableHtmlContactNotExist).replace('[TableauMembersNotExist]', tableHtml ));

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(recipientEmails);
        email.setTemplateId(theTemplate.Id);
        email.setSubject(theTemplate.Subject);
        email.setHtmlBody(tableHtml);
        email.setHTMLBody(mailBody);  
        email.setReplyTo(Orgwid.Address);
        email.setOrgWideEmailAddressId(Orgwid.Id); //sender
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
   }
}