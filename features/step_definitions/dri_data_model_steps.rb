Given /^we have a "(.*?)" Model$/ do |model_name|
  eval("defined?(#{model_name}) && #{model_name}.is_a?(Class)")
end

When /^we test the "(.*?)" Model$/ do |model_name|
  @test_model = FactoryGirl.build(:audio)
  @test_mode.should be_valid
end

Then /^it should have attribute "(.*?)"$/ do |attribute_name|
  pending # @test_model.has_attribute?(attribute_name).should == true
  @test_model.should respond_to(attribute_name)
end

Then /^it should validate presence of attribute "(.*?)"$/ do |attribute_name|
  @test_model.should validate_presence_of(attribute_name)
end

