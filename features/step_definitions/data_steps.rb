When /^I add (.*?) subject terms to the object with pid "(.*?)"$/ do |count, pid|
  object = DRI::Identifier.retrieve_object(pid)
  object.subject = object.subject << "Test subject 1"
  object.subject = object.subject << "Test subject 2"
  object.save
end
