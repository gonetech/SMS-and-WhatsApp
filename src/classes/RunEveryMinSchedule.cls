/**
 * @description This class is responsible for scheduling and rescheduling a job that runs every minute to process scheduled messages.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class RunEveryMinSchedule implements Schedulable{
	/**
     * @description This method is invoked by the system scheduler and is responsible for rescheduling itself
     *              and processing any scheduled messages that need to be updated.
     * @param sc The context in which the job is being executed.
     */
    global void execute(SchedulableContext sc){
        RescheduleJob();
        if (!Schema.sObjectType.connectsocial__Message__c.isAccessible()) {
            throw new AuraHandledException('You do not have access to connectsocial__Message__c objects.');
        }
        if (!Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Delivery_Status__c.isAccessible() ||
            !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Scheduled_Date_Time__c.isAccessible() ||
            !Schema.sObjectType.connectsocial__Message__c.fields.connectsocial__Channel__c.isAccessible()) {
            throw new AuraHandledException('You do not have access to the required fields.');
        }
        List<connectsocial__Message__c> scheduledMessages = [SELECT Id, connectsocial__Delivery_Status__c FROM connectsocial__Message__c WHERE connectsocial__Delivery_Status__c = 'Scheduled' AND connectsocial__Scheduled_Date_Time__c <= :DateTime.now() AND connectsocial__Channel__c = 'SMS'];
        if (!Schema.sObjectType.connectsocial__Message__c.isUpdateable()) {
                	throw new AuraHandledException('You do not have permission to update this message.');
         }
        if (!scheduledMessages.isEmpty()) {
            for (connectsocial__Message__c message : scheduledMessages) {
                message.connectsocial__Delivery_Status__c = 'Sent';
            }
            if (!CommonUtil.hasFLS(scheduledMessages[0])) {
        			throw new AuraHandledException('You do not have the necessary field permissions to create connectsocial__Message_Template__c records.');
    			}
            update scheduledMessages;
        }
        System.enqueueJob(new UpdateScheduledWhatsAppMessages());
    }
    /**
     * @description This method is responsible for rescheduling the job to run every minute.
     */
    public static void rescheduleJob(){
        List<CronTrigger> schJobs = [SELECT Id FROM CronTrigger where CronJobDetail.Name like '%RunEveryMinSchedule%' With SECURITY_ENFORCED];
        String myJobID;
        if (schJobs.size() > 0){
            myJobID = schJobs[0].Id;
            System.abortjob(myJobID);
        }
        DateTime cDateTime = DateTime.now();  
        DateTime newDateTime = cDateTime.addMinutes(1);      
        Integer min = newDateTime.minute();
        String cronExp = '0 ' + string.valueOf(min) + ' * * * ? ';
        System.schedule('RunEveryMinSchedule', cronExp, new RunEveryMinSchedule());        
    }
}