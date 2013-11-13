@req-17 @duplicates @req-17.1.1 @done @javascript
Feature: Duplicates

When I ingest a digital object into a collection in the repository
As an authenticated and authorised depositor
I want to be warned of any possible duplicate objects already contained in the collection

Background:
  Given I am logged in as "user1" in the group "cm"
  And I have created a collection with title "Test Collection"

Scenario: Ingesting a duplicate Digital Object using metadata file upload
  Given I have created an "audio" object with metadata "SAMPLEA.xml" in the collection "Test Collection"
  And I am on the new Digital Object page
  When I select the text "Test Collection" from the selectbox for ingest collection
  And I press the button to continue
  And I select "audio" from the selectbox for object type
  And I press the button to continue
  And I select "upload" from the selectbox for ingest methods
  And I press the button to continue
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to ingest metadata
  Then I should see a success message for ingestion
  And I should see the message "Possible duplicate objects found"

Scenario: Ingesting a duplicate Digital Object using form input
  Given I have created an "audio" object with title "SAMPLE OBJECT A" in the collection "Test Collection"  
  And I am on the new Digital Object page
  When I select the text "Test Collection" from the selectbox for ingest collection
  And I press the button to continue
  And I select "audio" from the selectbox for object type
  And I press the button to continue
  And I select "input" from the selectbox for ingest methods
  And I press the button to continue
  When I enter valid metadata with title "SAMPLE OBJECT A"
  And I press the button to continue
  Then I should see a success message for ingestion
  And I should see the message "Possible duplicate objects found"

Scenario: Creating a duplicate Digital Object by replacing the metadata file
  Given I have created an "audio" object with metadata "SAMPLEA.xml" in the collection "Test Collection"
  And I have created an "audio" object with metadata "SAMPLEB.xml" in the collection "Test Collection"
  Then I should not see the message "Possible duplicate objects found"
  And I should see a link to edit an object
  When I follow the link to edit an object
  And I attach the metadata file "SAMPLEA.xml"
  And I press the button to upload metadata
  Then I should see a success message for updating metadata
  And I should see the message "Possible duplicate objects found"

Scenario: Creating a duplicate Digital Object by editing with the metadata form
 Given I have created an "audio" object with title "SAMPLE OBJECT A" in the collection "Test Collection"
 And I have created an "audio" object with title "SAMPLE OBJECT B" in the collection "Test Collection"
 Then I should not see the message "Possible duplicate objects found"
 And I should see a link to edit an object
 When I follow the link to edit an object
 And I enter valid metadata with title "SAMPLE OBJECT A"
 And I press the button to save changes
 Then I should see a success message for updating metadata
 And I should see the message "Possible duplicate objects found"

