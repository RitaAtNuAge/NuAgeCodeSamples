@isTest
private with sharing class AdjudicationsHierarchyControllerTest {
    static testMethod void testAdjudicationsHierarchy(){

        
        Group_Name__c topAdjudication  = new Group_Name__c (Name='Top', Type__c ='Group', Group_ID__c='1234');
        insert topAdjudication;
        
        Group_Name__c middleAdjudication  = new Group_Name__c (Name='Middle', Adjudication_Parent__c=topAdjudication.Id, Type__c ='Group', Group_ID__c='1234');
        insert middleAdjudication;
        
        Group_Name__c bottomAdjudication  = new Group_Name__c (Name='Bottom', Adjudication_Parent__c=middleAdjudication.Id, Type__c ='Group', Group_ID__c='1234');
        insert bottomAdjudication;
        
        Group_Name__c middleChildAdjudication  = new Group_Name__c (Name='MiddleChild', Adjudication_Parent__c=middleAdjudication.Id, Type__c ='Group', Group_ID__c='1234');
        insert middleChildAdjudication;
        
        Group_Name__c bottomChildAdjudication  = new Group_Name__c (Name='BottomChild', Adjudication_Parent__c=bottomAdjudication.Id, Type__c ='Group', Group_ID__c='1234');
        insert bottomChildAdjudication;
        test.startTest();
        List<Group_Name__c> gn = [select id, Adjudication_Parent__c from Group_Name__c];
        system.debug('gn is ' + gn);
        List<Group_Name__c> gn2 = [select Adjudication_Parent__c from Group_Name__c];
        system.debug('gn2 is ' + gn2);
        
        AdjudicationsHierarchyController controller = new AdjudicationsHierarchyController();
        
        // Call Methodes for top account
        controller.setcurrentId(middleAdjudication.Id);
        List<AdjudicationsHierarchyController.items> finalWrp = new List<AdjudicationsHierarchyController.items>();
        finalWrp = AdjudicationsHierarchyController.getAdjudicationsHierarchy(middleAdjudication.Id);
        
        test.stopTest();
    }
}