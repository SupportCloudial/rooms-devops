@isTest
public with sharing class OpportunityMembersController_Test {
    @TestSetup
    static void createData(){ 

        Date testDate = System.now().date().addDays(-10);

        Account acc = new Account(Name = 'test');
        insert acc;

        Contact con = new Contact(lastName = 'test',Email='alex@test.com', AccountId = acc.Id);
        insert con;

        Contract contract = new Contract(AccountId = acc.Id, Type__c = 'New Business', StartDate = testDate, Members_Registred__c = false, Main_contact__c=con.id);
        insert contract;

        Contract contract2 = new Contract(AccountId = acc.Id, Type__c = 'New Business', StartDate = testDate, Members_Registred__c = false);
        insert contract2;

        Locations__c loc = new Locations__c(City__c='Tel Aviv', Name = 'TLV - Migdal Shalom - ST1');
        insert loc;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', Number_of_members__c = 10, ContractId = contract.Id, Contract_language__c = 'Hebrew', Interested_in__c = 'Open Space',  AccountId = acc.Id, StageName = 'New', CloseDate = testDate, Amount = 10000, Location__c = loc.Id, main_contact__c = con.Id);
        insert opp;

        ContentVersion cv = new ContentVersion(title = opp.Id, PathOnClient ='test',versiondata = EncodingUtil.base64Decode('This is version data'));
        insert cv;
    }

    @isTest
    static void testGetNumberOfMembers() {

        Contract testContract = [SELECT Id FROM Contract WHERE Id IN (SELECT ContractId FROM Opportunity) LIMIT 1];
        Contract testContract2 = [SELECT Id FROM Contract WHERE Id NOT IN (SELECT ContractId FROM Opportunity) LIMIT 1];

        Test.startTest();
        Contract result = OpportunityMembersController.getNumberOfMembers(testContract.Id);
        Contract result2 = OpportunityMembersController.getNumberOfMembers(testContract2.Id);
        Test.stopTest();

        System.assertEquals(testContract.Id, result.Id);
        System.assertEquals(null, result2);
    }

    @isTest
    static void testCheckContactNotExists() {
    
        // Créez des e-mails pour tester la méthode
        List<String> testEmailsNo = new List<String>{
            'test3333@example.com'
        };
        List<String> testEmailsNot = new List<String>{
            'test222@example.com'  
        };
        List<String> testEmailsDoesnt = new List<String>{
            'test111@example.com'  
        };

        Test.startTest();
        // Appeler la méthode à tester
       // OpportunityController.checkContactExists(idExist, testEmailsDoesnt, emailCounter, testEmailsNot,testEmailsNo);
        Test.stopTest();

        // Vérifier les résultats attendus
        //System.assertEquals('success' , result);
    }

    @isTest
    static void testCheck() {
        // Créer des contacts fictifs pour les tests
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact c = new Contact(LastName = 'ExistingLastName1' + i, Email = 'test' + i + '@example.com');
            testContacts.add(c);
        }
        insert testContacts;

        // Préparer des données de test pour la méthode
        List<Id> idExist = new List<Id>();
        Map<String, Integer> emailCounter = new Map<String, Integer>();
        List<String> emails = new List<String> { 'test0@example.com', 'test1@example.com', 'test2@example.com', 'test6@example.com' };
        List<String> existingEmails = new List<String>();
        List<String> notExistingEmail = new List<String>();

        // Appeler la méthode que vous souhaitez tester
        OpportunityMembersController.checkContactExists(idExist, emailCounter, emails, existingEmails, notExistingEmail);

        // Vérifier les résultats
        System.assertEquals(3, idExist.size(), 'Le nombre d\'ID existants doit être de 3');
        System.assertEquals(3, existingEmails.size(), 'Le nombre d\'e-mails existants doit être de 3');
        System.assertEquals(1, notExistingEmail.size(), 'Le nombre d\'e-mails non existants doit être de 1');
        System.assertEquals(1, emailCounter.get('test0@example.com'), 'Le compteur pour test0@example.com doit être 1');
        System.assertEquals(1, emailCounter.get('test1@example.com'), 'Le compteur pour test1@example.com doit être 1');
        System.assertEquals(1, emailCounter.get('test2@example.com'), 'Le compteur pour test2@example.com doit être 1');
        System.assertEquals(null, emailCounter.get('test6@example.com'), 'Le compteur pour test6@example.com doit être null');
    }


    @isTest
    static void testCheckContactExists() {
    
        List<Contact> existingContacts = new List<Contact>{
            new Contact(FirstName = 'ExistingFirstName1', LastName = 'ExistingLastName1', Email = 'test1@example.com'),
            new Contact(FirstName = 'ExistingFirstName2', LastName = 'ExistingLastName2', Email = 'test2@example.com')
        };
        insert existingContacts;


        // Créez des e-mails pour tester la méthode
        List<String> testEmailsExist = new List<String>{
            'test1@example.com'    
        };

        List<String> testEmailsExisting = new List<String>{
            'test2@example.com'  
        };
        List<String> testEmailsNotExist = new List<String>{
            'test2@example.com'  
        };

        Test.startTest();
        // Appeler la méthode à tester
        //OpportunityController.checkContactExists(testEmailsExist,testEmailsExisting,testEmailsNotExist);
        Test.stopTest();

        //System.debug(result);
        //System.assertEquals(' test1@example.com , test2@example.com , ' , result);
    }

    @isTest
    static void testSaveContacts_Success() {
        List<Contact> testContacts2 = new List<Contact>();
        for (Integer i = 3; i < 6; i++) {
            Contact testContact = new Contact(
                LastName = 'Teseurt' + i,
                FirstName = 'TesteurFirst' + i,
                MobilePhone = '78946512311' + i,
                Email = 'testeur' + i + '@example.com'
            );
            testContacts2.add(testContact);
        }

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];

        Test.startTest();
        OpportunityMembersController.saveContacts(testContacts2, testContract.Id);
        Test.stopTest();

        //System.assertEquals('success', result2);
    }

     @isTest
     static void testSaveContacts_ContactExists() {
        //Créez des données de test pour les contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            Contact testContact = new Contact(
                LastName = 'Test' + i,
                FirstName = 'TestFirst' + i,
                MobilePhone = '98745612365' + i,
                Email = 'test' + i + '@example.com'
            );
            testContacts.add(testContact);
        }
        insert testContacts;

        // Récupérer un contrat pour l'utiliser comme argument pour la méthode à tester
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];

        Test.startTest();
        // Appeler la méthode à tester
        OpportunityMembersController.saveContacts(testContacts, testContract.Id);
        Test.stopTest();

        //System.debug(result);
        // Vérifier les résultats attendus
       // System.assertEquals(' test0@example.com , test1@example.com , test2@example.com , ', result);
    }

    @isTest
    public static void testSendTableMembersEmail() {
        Test.startTest();

        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            Contact testContact = new Contact(
                LastName = 'Test' + i,
                FirstName = 'TestFirst' + i,
                MobilePhone = '98745612365' + i,
                Email = 'test' + i + '@example.com'
            );
            testContacts.add(testContact);
        }
        insert testContacts;

        List<Contact> testContacts2 = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            Contact testContact = new Contact(
                LastName = 'Contact' + i,
                FirstName = 'Emily' + i,
                MobilePhone = '056698845' + i,
                Email = 'Emily' + i + '@test.com'
            );
            testContacts2.add(testContact);
        }

        insert testContacts2;

        // Récupérer un contrat pour l'utiliser comme argument pour la méthode à tester
        list<Contract> testContract = [SELECT Id, Locations__r.Name, StartDate, EndDate, Main_contact__r.Name, Main_contact__r.Email
                                       FROM Contract limit 1];
        
        //OpportunityController.SendTableMembersEmail(List <Id> idExist,  Map<String,Integer> emailCounter, testContacts, testContacts2, testContract[0].Id);

        Test.stopTest();
    }
}