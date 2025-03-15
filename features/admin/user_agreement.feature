@enforce_cookies @javascript
Feature: End User Agreement
Background:
    Given I have no cookies
    And I am logged in as "user1" in the group "cm"
    When I create an object and save the pid
    And I go to the "asset" "new" page for "the saved pid"
    And I attach the asset file "sample_audio.mp3"
    And I press the button to "Upload 1 file"
    Then I should see "Asset has been successfully uploaded."

Scenario: download without accepted end user agreement
    When I go to the "object" "show" page for "the saved pid"
    Then I should see a href link to "#dri_download_modal_id" with text "Download asset"
    When I follow "Download asset"
    And I wait for "2" second
    Then I should see a window about cookies

Scenario: download with accepted end user agreement
    When I go to the "object" "show" page for "the saved pid"
    Then I should see a href link to "#dri_download_modal_id" with text "Download asset"
    When I follow "Download asset"
    And I wait for "2" second
    When I accept cookies terms
    When I go to the "object" "show" page for "the saved pid"
    Then I should see a href link to "#dri_download_modal_id" with text "Download asset"
    When I follow "Download asset"
    And I wait for "2" second
    Then I should not see a window about cookies
