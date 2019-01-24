@cookies @javascript
Feature: IIIF
  As an new visitor to the DRI
  I should be able to view images in a iiif viewer

Background:
  Given I am logged in as "admin" in the group "admin" and accept cookies

Scenario: Collections with images should have a iiif link
  Given a collection with pid "col1" created by "admin"
  And a Digital Object with pid "object1" in collection "col1"
  And I add the asset "sample_image.tiff" to "object1"
  And I fake the update to solr to add the asset "sample_image.tiff" to "object1"
  And I have associated the institute "TestInstitute" with the collection with pid "col1"
  And the collection with pid "col1" is published
  When I am on the show Digital Object page for id col1
  Then I should see the image "Iiif logo"

Scenario: Objects with an image should have a iiif link
  Given a collection with pid "col1" created by "admin"
  And a Digital Object with pid "object1" in collection "col1"
  And I add the asset "sample_image.tiff" to "object1"
  And I fake the update to solr to add the asset "sample_image.tiff" to "object1"
  And I have associated the institute "TestInstitute" with the collection with pid "col1"
  And the collection with pid "col1" is published
  When I am on the show Digital Object page for id object1
  Then I should see the image "Iiif logo"

Scenario: Collections with no images should not have a iiif link
  Given a collection with pid "col2" created by "admin"
  When I am on the show Digital Object page for id col2
  Then I should not see the image "Iiif logo"

Scenario: Objects with no image should not have a iiif link
  Given a collection with pid "col2" created by "admin"
  And a Digital Object with pid "object1" in collection "col2"
  When I am on the show Digital Object page for id object2
  Then I should not see the image "Iiif logo"
