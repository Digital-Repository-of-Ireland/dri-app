Feature:
  In order to allow permissions based on user roles
  Users should be able to apply for and be granted different roles
  on a per-collection or -object basis

Scenario: Becoming a collection manager when I have created an account
  Given I am a member of a cultural institution or other target audience
  And I have a collection of cultural or social sciences data
  And I want to ingest the data into DRI
  And I have created an account on the DRI Repository
  When I visit the How to become a collection manager page
  And I use the contact form / email the designated address
  And I provide the email address which I used to create my account
  Then I will be sent a collection manager agreement
  When I sign the collection manager agreement
  And I send the signed collection manager agreement back to DRI Personnel
  Then DRI Personnel will add me to the collection manager group

Scenario: Becoming a collection manager when I don't have an account
  Given I am a member of a cultural institution or other target audience
  And I have a collection of cultural or social sciences data
  And I want to ingest the data into DRI
  And I have not created an account on the DRI Repository
  When I visit the How to become a collection manager page
  And I use the contact form / email the designated address
  And I provide my email address
  Then I will be sent a collection manager agreement
  When I sign the collection manager agreement
  And I send the signed collection manager agreement back to DRI Personnel
  Then DRI Personnel will create a user account for my email address
  And DRI Personnel will add me to the collection manager group
