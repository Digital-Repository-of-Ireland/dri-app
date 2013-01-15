@model
Feature: DRI Data Model

Scenario: We are defining our DRI Data Model for Audio
  Given we have a "DRI::Model::Audio" Model
  When we test the "DRI::Model::Audio" Model
  Then it should validate presence of attribute "title"
#  And it should validate presence of attribute "rights"
  And it should validate presence of attribute "language"
  And it should have attribute "description"
  And it should have attribute "presenter"
  And it should have attribute "guest"
  And it should have attribute "broadcast_date"
  And it should have attribute "creation_date"
  And it should have attribute "subject"
  And it should have attribute "source"
  And it should have attribute "geographical_coverage"
  And it should have attribute "temporal_coverage"
  And it should have attribute "person"
