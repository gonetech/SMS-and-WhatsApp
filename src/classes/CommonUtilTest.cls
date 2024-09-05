@IsTest
public class CommonUtilTest {
  @IsTest
    public static void testHasFLS() {
      connectsocial__Message__c master =new connectsocial__Message__c
          (connectsocial__Outgoing__c=true,connectsocial__Channel__c='WhatsApp');
       Test.startTest();
        CommonUtil.hasFLS(master);
        Test.stopTest();
        Boolean hasFLSResult = CommonUtil.hasFLS(master);
        Assert.areEqual(true, hasFLSResult, 'Expected value and Actual value are Same.');
    }
}