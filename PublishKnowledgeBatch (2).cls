global class PublishKnowledgeBatch implements Database.Batchable<SObject>, Schedulable {

// Start: Query for relevant Knowledge__kav records

    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator([

            SELECT Id, KnowledgeArticleId

            FROM Knowledge__kav

            WHERE Request_Publication_Date__c = :System.today()

            AND PublishStatus != 'Online'
            AND Approval_Status__c = 'Approved - Pending Publish'

            // AND IsLatestVersion = true

            ]);

        }

 

// Execute: Publish each matching article

global void execute(Database.BatchableContext BC, List<SObject> scope) {
List<Knowledge__kav> kavToUpdate = new List<Knowledge__kav>();


    for (SObject obj : scope) {
        Knowledge__kav kav = (Knowledge__kav)obj;

        // Update Approval_Status__c before publishing
        kav.Approval_Status__c = 'Approved - Publish';
        kavToUpdate.add(kav);
    }

    // Perform DML update
    try {
        update kavToUpdate;
    } catch (Exception e) {
        System.debug('Failed to update Approval_Status__c: ' + e.getMessage());
        // Optionally log or handle error
    }

for (Knowledge__kav kav : kavToUpdate) {
        try {
            KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, false);
        } catch (Exception e) {
            System.debug('Failed to publish article Id: ' + kav.KnowledgeArticleId + ' due to: ' + e.getMessage());
            // Optionally log or handle error
        }



}

}

 

global void finish(Database.BatchableContext BC) {

// Optionally: post-processing or notifications if needed

}

 

// Make batch schedulable

global void execute(SchedulableContext sc) {

// Adjust batch size as needed (default 200, e.g. set to 50 for large volume orgs)

Database.executeBatch(new PublishKnowledgeBatch(), 50);

}

}
