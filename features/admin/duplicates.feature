@req-17 @duplicates @req-17.1.1 @done @javascript
Feature: Duplicates

When I ingest a digital object into a collection in the repository
As an authenticated and authorised depositor
I want to be warned of any possible duplicate objects already contained in the collection

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies

Scenario: Ingesting a duplicate Digital Object using metadata file upload
  When I create a collection and save the pid
  And I go to the "collection" "show" page for "the saved pid"
  And I follow the link to upload XML
  And I should wait for "1" seconds
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to "ingest metadata"
  Then I should see a success message for ingestion
  When I go to the "collection" "show" page for "the saved pid"
  And I follow the link to upload XML
  And I should wait for "1" seconds
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to "ingest metadata"
  Then I should see a success message for ingestion
  And I should see the message "Possible duplicate objects found"

Scenario: Ingesting a duplicate Digital Object using form input
  When I create a collection and save the pid
  When I go to the "collection" "new object" page for "the saved pid"
  And I enter valid metadata with title "SAMPLE OBJECT A"
  And I press the button to "continue"
  Then I should see a success message for ingestion
  When I go to the "collection" "new object" page for "the saved pid"
  And I enter valid metadata with title "SAMPLE OBJECT A"
  And I press the button to "continue"
  Then I should see a success message for ingestion
  And I should see the message "Possible duplicate objects found"

Scenario: Creating a duplicate Digital Object by replacing the metadata file
  When I create a collection and save the pid
  And I go to the "collection" "show" page for "the saved pid"
  And I follow the link to upload XML
  And I should wait for "1" seconds
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to "ingest metadata"
  Then I should see a success message for ingestion
  When I go to the "collection" "new object" page for "the saved pid"
  And I enter valid metadata with title "SAMPLE OBJECT B"
  And I press the button to "continue"
  Then I should see a success message for ingestion
  And I should not see the message "Possible duplicate objects found"
  When I click the link to edit
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to "upload metadata"
  Then I should see the message "Possible duplicate objects found"
  And I should see the message "Possible duplicate objects found"

Scenario: Creating a duplicate Digital Object by editing with the metadata form
  When I create a collection and save the pid
  When I go to the "collection" "new object" page for "the saved pid"
  And I enter valid metadata with title "SAMPLE OBJECT A"
  And I press the button to "continue"
  Then I should see a success message for ingestion
  When I go to the "collection" "new object" page for "the saved pid"
  And I enter valid metadata with title "SAMPLE OBJECT B"
  And I press the button to "continue"
  Then I should see a success message for ingestion
  And I should not see the message "Possible duplicate objects found"
  When I follow the link to edit
  And I follow the link to edit an object
  And I enter valid metadata with title "SAMPLE OBJECT A"
  And I press the button to "save changes"
  Then I should see a success message for updating metadata
  And I should see the message "Possible duplicate objects found"

