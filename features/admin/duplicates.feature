@req-17 @duplicates @req-17.1.1 @done @javascript
Feature: Duplicates

When I ingest a digital object into a collection in the repository
As an authenticated and authorised depositor
I want to be warned of any possible duplicate objects already contained in the collection

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies

@random_pid
Scenario: Ingesting a duplicate Digital Object using metadata file upload
  Given a collection with title "Test Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection
  When I go to the "metadata" "upload" page
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to "ingest metadata"
  Then I should see a success message for ingestion
  And I should see the message "Possible duplicate objects found"

@random_pid
Scenario: Ingesting a duplicate Digital Object using form input
  Given a collection with title "Test Collection" created by "user1"
  And I have created an object with title "SAMPLE OBJECT A" in the collection
  When I go to the "collection" "show" page
  And I follow the link to add an object
  And I enter valid metadata with title "SAMPLE OBJECT A"
  And I press the button to "continue"
  Then I should see a success message for ingestion
  And I should see the message "Possible duplicate objects found"

@random_pid
Scenario: Creating a duplicate Digital Object by replacing the metadata file
  Given a collection with title "Test Collection" created by "user1"
  And I have created an object with metadata "SAMPLEA.xml" in the collection
  And a Digital Object created by "user1"
  And the object is in the collection
  When I go to the "object" "show" page
  And I click the link to edit
  And I attach the metadata file "SAMPLEB.xml"
  And I press the button to "upload metadata"
  Then I should not see the message "Possible duplicate objects found"
  When I go to the "object" "show" page
  And I click the link to edit
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to "upload metadata"
  Then I should see the message "Possible duplicate objects found"

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

