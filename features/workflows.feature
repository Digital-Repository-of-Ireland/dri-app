Feature:
  As a member of the public
  I should be able to interact with the DRI public repository

  Scenario: Anonymous user access
    Given I do not have an account on DRI
    When I go to the home page
    Then I should see facets
    And I should see social media
    And I should see a Search button

  Scenario: Anonymous user search
    Given I do not have an account on DRI
    And a collection with public permissions exists
    And an object with public permissions exists within the collection
    When I go to the home page
    And I enter a search term
    And I click on Search
    Then I should see one search result
    When I click on one of the search results
    Then I should see the record for that object

  Scenario: Anonymous user wants to create an account
    Given I do not have an account on DRI
    When I go to the home page
    And I click on the link to Register
    And I enter my details
    And I click on Register
    Then I should be logged in

Scenario: Logged in user search
    Given I am logged in
    And a collection with public permissions exists
    And an object with public permissions exists within the collection
    And an object with logged-in permissions exists within the collection
    When I go to the home page
    And I enter a search term
    And I click on Search
    Then I should see 2 search results

Scenario: Accessing restricted content by joining a group
    Given I am logged in
    And a collection with restricted permissions exists
    And an object with inherit or restricted permissions exists within the collection
    When I go to the show page for the object
    Then I should see the object metadta
    And I should not see a link to download asset
    When I go to the Groups page
    And I click on Apply button for the group
    Then My membership of the group should be pending
    When the group manager approves my membership
    And I go to the show page for the object
    Then I should see the object metadata
    And I should see a link to download asset

  Scenario: Accessing restricted contact by contacting the collection manager
    Given I am logged in
    And a collection with restricted permissions exists
    And an object with inherit or restricted permissions exists within the collection
    When I go to the show page for the object
    Then I should see the object metadata
    And I should not see a link to download asset
    When I email the collection manager to request membership
    And the collection manager adds me to the list of authorised users
    And I go to the show page for the object
    Then I should see the object metadata
    And I should see a link to download asset

  Scenario: ingest for non-collection manager
    Given I am logged in
    And I am not a collection manager
    When I go to the ingest page
    Then I should see the message "You do not have permission to access this page"

  Scenario: Becoming a collection manager
    Given I am logged in
    And I am not a collection manager
    When I go to the Groups page
    And I apply for membership of the CM group
    And the group manager approves my membership
    And I go to the ingest page
    Then I should see the ingest form

