When /^I add (.*?) subject terms to the object with pid "(.*?)"$/ do |count, pid|
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.subject = object.subject << "Test subject 1"
  object.subject = object.subject << "Test subject 2"
  object.save
end
