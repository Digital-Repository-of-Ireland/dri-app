@model
Feature: DRI Data Model

Scenario: We are defining our DRI Data Model for Audio
  Given we have a "DRI::Model::Audio" Model
  When we test the "DRI::Model::Audio" Model
  Then the Test Model should have attribute "title"
