@api
Feature: API Testing

  Background:
    Given I am logged in as "user1" in the group "cm"
    And a collection with pid "dri:apitest" and title "API Test Collection" created by "user1"
    And a Digital Object with pid "dri:apitest1", title "API Test 1", type "Image" created by "user1"
    And a Digital Object with pid "dri:apitest2", title "API Test 2", type "Image" created by "user1"
    And the object with pid "dri:apitest1" is governed by the collection with pid "dri:apitest"
    And the object with pid "dri:apitest2" is governed by the collection with pid "dri:apitest"
    And the object with pid "dri:apitest1" is publicly readable
    And the object with pid "dri:apitest2" is publicly readable
    And the object with pid "dri:apitest1" is published
    And the object with pid "dri:apitest2" is published
    And the object with pid "dri:apitest1" has "accessible" masterfile
    And the object with pid "dri:apitest2" has "inaccessible" masterfile
    And the object with pid "dri:apitest1" has a deliverable surrogate file
    And the object with pid "dri:apitest2" has a deliverable surrogate file
    When I add 2 subject terms to the object with pid "dri:apitest1"

  Scenario: I should be able to get a list of asset files for an object
    When I send and accept JSON
    When I send a POST request to "/files/list_assets" with the following:
    """
    {"objects": [ { "pid":"dri:apitest1"} ]}
    """
    Then the response status should be "200"
    And the JSON response should have "$..pid" with a length of 1
    And the JSON response should have "$..pid" with the text "dri:apitest1"
    And the JSON response should have "$..masterfile" with a length of 1
    And the JSON response should have "$..thumbnail" with a length of 1

  Scenario: I should be able to get a list of metadata and asset files for an object
    When I send and accept JSON
    When I send a POST request to "/get_objects" with the following:
    """
    {"objects": [ { "pid":"dri:apitest1"} ], "metadata": ["title", "description", "subject"]}
    """
    Then the response status should be "200"
    And the JSON response should have "$..pid" with a length of 1
    And the JSON response should have "$..pid" with the text "dri:apitest1"
    And the JSON response should have "$..masterfile" with a length of 1
    And the JSON response should have "$..thumbnail" with a length of 1
    And the JSON response should have "$..metadata" with a length of 1
    And the JSON response should have "$..title" with a length of 1
    And the JSON response should have "$..description" with a length of 1
    And the JSON response should have "$..subject" with a length of 1

  Scenario: I should be able to get a list of asset files for several objects
    When I send and accept JSON
    When I send a POST request to "/files/list_assets" with the following:
      """
      {"objects": [ { "pid":"dri:apitest1"}, {"pid":"dri:apitest2" } ]}
      """
    Then the response status should be "200"
    And the JSON response should have "$..pid" with a length of 2
    And the JSON response should have "$..pid" with the text "dri:apitest1"
    And the JSON response should have "$..pid" with the text "dri:apitest2"
    And the JSON response should have "$..masterfile" with a length of 1
    And the JSON response should have "$..thumbnail" with a length of 2

  Scenario: I should be able to get a list of metadata and asset files for several objects
    When I send and accept JSON
    When I send a POST request to "/get_objects" with the following:
      """
      {"objects": [ { "pid":"dri:apitest1"}, {"pid":"dri:apitest2" } ]}
      """
    Then the response status should be "200"
    #And the JSON response should have "$..pid" with a length of 2
    #And the JSON response should have "$..pid" with the text "dri:apitest1"
    #And the JSON response should have "$..pid" with the text "dri:apitest2"
    #And the JSON response should have "$..masterfile" with a length of 1
    #And the JSON response should have "$..thumbnail" with a length of 2
    #And the JSON response should have "$..metadata" with a length of 2
    #And the JSON response should have "$..title" with a length of 2
    #And the JSON response should have "$..description" with a length of 2
    #And the JSON response should have "$..subject" with a length of 1

  Scenario: Invalid object id
    When I send and accept JSON
    When I send a POST request to "/files/list_assets" with the following:
    """
    {"objects": [ { "pid":"dri:unknown"} ]}
    """
    Then the response status should be "404"

  Scenario: Empty input
    When I send and accept JSON
    When I send a POST request to "/files/list_assets" with the following:
    """
    {}
    """
    Then the response status should be "400"

  Scenario: Invalid input
    When I send and accept JSON
    When I send a POST request to "/files/list_assets" with the following:
    """
    {"test":"invalid input"}
    """
    Then the response status should be "400"


