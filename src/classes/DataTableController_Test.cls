@isTest
private class DataTableController_Test {
    
    @testSetup static void setup() {
        System.runAs(createUser('batman@darkknightrises.com')) {
            List<sObject> accounts = Test.loadData(Account.sObjectType, 'Datatable_TestData_Account_V1');
            System.assert(accounts.size() > 0);
            List<sObject> contacts = Test.loadData(Contact.sObjectType, 'Datatable_TestData_Contact_V1');
            System.assert(contacts.size() > 0);
        }
    }
    
	@isTest static void testAccountRecords() {
         System.runAs(createUser('batman@darkknightrises.com')) {
            String fields = 'Name, Title, LeadSource, Account.Name, Description, LastModifiedDate';
            DataTableController.ResultSet results = DataTableController.getSobjects(fields, 'Contact', 0, 10, 'Name', 'asc', '');
            System.assert(results != null);
            System.assert(results.columnHeader.size() > 0);
            System.assert(results.rows.size() > 0);
         }
    }
    
    @isTest static void testBulkSave() {
    	System.runAs(createUser('batman@darkknightrises.com')) {
            String fields = 'Id, Name, Title, Account.Name, Firstname,LastModifiedDate';
            DataTableController.ResultSet results = DataTableController.getSobjects(fields, 'Contact', 0, 10, 'Name', 'asc', '');
            System.assert(results != null);
            for (DataTableController.Row re :  results.rows) {
                for (DataTableController.Cell ce :  re.fields) {
                    if (ce.fieldApi.equalsIgnoreCase('Firstname')) ce.fieldValue = 'Test'+ce.fieldValue; 	
                }
            }
            String jsonData = JSON.serialize(results.rows);
            System.debug(logginglevel.info, 'jsonData === '+jsonData);
            String response = DataTableController.bulkSaveRecords(jsonData, 'Contact');
            System.debug(logginglevel.info, 'response === '+response);
            Database.SaveResult[] saveResults = (List<Database.SaveResult>) JSON.deserializeStrict(response, List<Database.SaveResult>.class);
            for (Database.SaveResult r : saveResults) {
                System.assert(r.isSuccess());
            }
        }
    }
    
    static User createUser(String email) {
    	List<User> usrs = new List<User>();
        usrs = [Select Id From User where Email =:email];
        User usr;
        if (usrs.isEmpty()) {
        	Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        	usr = new User(Alias = 'usr123', Email = email, EmailEncodingKey='UTF-8', FirstName ='Test1', LastName='Testing', 
                            LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, 
                            TimeZoneSidKey='America/Los_Angeles', UserName = email+'.test.qa123');    
        } else {
            usr = usrs[0];
        }
        return usr;    
    }
}