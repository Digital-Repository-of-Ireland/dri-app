@users
Feature:
  
  In order for the digital repository to control access to digital objects
  As a user
  I want to be able to create and manage an account

Scenario: Navigate to the Sign in page
  Given I am not logged in
  When I go to the home page
  Then I should see a link to "/users/sign_in" with text "Login"
  And I should not see a link to "Log Out"
  When I follow "Login"
  Then I should be on the User Signin page

Scenario: Navigate to the Sign up page
  Given I am not logged in
  When I go to the home page
  Then I should see a link to "/users/sign_in" with text "Login"
  When I follow "Login"
  Then I should be on the User Signin page
  When I follow "Sign up"
  Then I should be on the User Sign up page

Scenario: Creating a new valid user account
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email, password and password confirmation
  Then I should see the message "Welcome! You have signed up successfully." 
  And I should see a link to "/users/sign_out" with text "Log Out"

Scenario: Creating an invalid user account with duplicate email
  Given an account for "user@domain.com" already exists
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit the User Sign up page with email "user@domain.com"
  Then I should see the error "Email has already been taken"

Scenario: Creating an invalid user account with non-matching password confirmation
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email address and non-matching password and password confirmation
  Then I should see the error "Password doesn't match confirmation" 

Scenario: Creating an invalid user account with too short password
  Given I am not logged in
  Given I am on the User Sign up page
  When I submit a valid email address and too short password and password confirmation
  And I should see the error "Password is too short" 

Scenario: User signs in with valid credentials
  Given an account for "user@domain.com" already exists
  Given I am not logged in
  Given I am on the User Signin page
  When I submit the User Sign in page with email "user@domain.com"
  Then I should see a link to "/users/sign_out" with text "Log Out"
  
Scenario: User signs in with invalid credentials 
  Given I am not logged in
  Given I am on the User Signin page
  When I submit the login form with invalid credentials
  Then I should be logged out
  And I should see the error ""

Scenario: Logging out
  Given I am logged in as "user1"
  When I go to the home page
  Then I should see a link to "/users/sign_out" with text "Log Out"
  When I follow "Log Out"
  Then I should be logged out

Scenario: A user should be able to edit their details
  Given I am logged in as "user1"
  Then I should see an edit link for "user1"
  When I follow the edit link for "user1"
  Then I should see the "user1" edit page
  When I submit a new email and password
  Then my details should be updated

Scenario: A user should be able to cancel their account
  Given I am logged in as "user1"
  Then I should see an edit link for "user1"
  When I follow the edit link
  Then I should see a link with text "Cancel my account"
  When I follow "Cancel my account"
  Then I should see a confirmation popup
  When I confirm account cancellation
  Then my account should be deleted
  And I should be logged out

Scenario: A user should be able to recover their password

