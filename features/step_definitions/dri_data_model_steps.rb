Given /^we have a "(.*?)" Model$/ do |model_name|
  eval("defined?(#{model_name}) && #{model_name}.is_a?(Class)")
end

When /^we test the "(.*?)" Model$/ do |model_name|
  @test_model = Object.recursive_const_get(model_name).new
  @test_model.should be_valid
end

Then /^the Test Model should have attribute "(.*?)"$/ do |attribute_name|
  pending # @test_model.has_attribute?(attribute_name).should == true
end
