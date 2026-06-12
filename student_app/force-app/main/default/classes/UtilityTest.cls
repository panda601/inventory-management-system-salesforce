@isTest
public class UtilityTest {
    @isTest
    static void testAccessChecks() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Boolean objAccess = Utility.checkObjectAccess('Account', 'read');
            Boolean fieldAccess = Utility.checkFieldAccess('Account', 'Name', 'read');
            
            // Check other access modes
            Utility.checkObjectAccess('Account', 'create');
            Utility.checkObjectAccess('Account', 'edit');
            Utility.checkObjectAccess('Account', 'delete');
            Utility.checkFieldAccess('Account', 'Name', 'edit');
            
            // Check some non-existent values
            Boolean badObj = Utility.checkObjectAccess('NonExistent__c', 'read');
            Boolean badField = Utility.checkFieldAccess('Account', 'NonExistent__c', 'read');
            
            // Check invalid access types to hit fallback return statements
            Boolean invalidObjAccess = Utility.checkObjectAccess('Account', 'invalid_access');
            Boolean invalidFieldAccess = Utility.checkFieldAccess('Account', 'Name', 'invalid_access');
            Boolean nonExistentFieldObj = Utility.checkFieldAccess('NonExistent__c', 'Name', 'read');
            
            Assert.isFalse(badObj, 'Non existent object should return false');
            Assert.isFalse(badField, 'Non existent field should return false');
            Assert.isFalse(invalidObjAccess, 'Invalid object access type should return false');
            Assert.isFalse(invalidFieldAccess, 'Invalid field access type should return false');
            Assert.isFalse(nonExistentFieldObj, 'Non existent object for field check should return false');
        }
    }
}
