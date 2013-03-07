Given /^the group "([^\"]*)" exists$/ do |name|
  group = Group.create(name: name, description: "sample group")
end