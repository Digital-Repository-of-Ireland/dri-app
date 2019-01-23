@cookies @javascript
Feature: IIIF
  As an new visitor to the DRI
  I should be able to view images in a iiif viewer

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And a collection with pid "col1" and title "Parent" created by "user1"
  And I attach the asset file "sample_image.jpeg"
  And a collection with pid "col2" and title "Parent" created by "user1"
  And a Digital Object with pid "object1" and title "object1" in collection "col1"
  And a Digital Object with pid "object2" and title "object2" in collection "col1"
  And the collection with pid "col1" is published
  And the collection with pid "col2" is published

Scenario: Collections with images should have a iiif link
  When I am on the show Digital Object page for id col1
  Then I should see the image "Iiif logo"

Scenario: Objects with an image should have a iiif link
  When I am on the show Digital Object page for id object1
  Then I should see the image "Iiif logo"

Scenario: Collections with no images should not have a iiif link
  When I am on the show Digital Object page for id col2
  Then I should not see the image "Iiif logo"

Scenario: Objects with no image should not have a iif link
  When I am on the show Digital Object page for id object2
  Then I should not see the image "Iiif logo"
