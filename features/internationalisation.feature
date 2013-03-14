@language
Feature:

  In order to provide a bi-lingual repository
  As a user
  I should be able to see the website in English or Irish

Before do
  DatabaseCleaner.start
end

After do |scenario|
  DatabaseCleaner.clean
end

Scenario: Not logged in user with English browser
Given my browser language is "en"
And I am not logged in
Then I should see the en language

Scenario: Not logged in user with Irish browser
Given my browser language is "ga"
And I am not logged in
Then I should see the ga language

Scenario: Logged in user with English browser and English language setting
Given my browser language is "en"
And I am logged in as "englishuser" with language "en"
Then I should see the en language

Scenario: Logged in user with English browser but Irish language setting
Given my browser language is "en"
And I am logged in as "irishuser" with language "ga"
Then I should see the ga language

Scenario: Logged in user with Irish browser but English language setting
Given my browser language is "ga"
And I am logged in as "englishuser" with language "en"
Then I should see the en language

Scenario: Logged in user with Irish browser and Irish language setting
Given my browser language is "ga"
And I am logged in as "irishuser" with language "ga"
Then I should see the ga language

Scenario: Changing language from English to Irish
Given I am logged in as "englishuser" with language "en"
When I follow the link to view my account
And I follow the link to edit my account
Then I should see the edit page
When I change my language to ga
Then I should see the ga language

Scenario: Changing language from Irish to English
Given I am logged in as "irishuser" with language "ga"
When I follow the link to view my account
And I follow the link to edit my account
Then I should see the edit page
When I change my language to en
Then I should see the en language
