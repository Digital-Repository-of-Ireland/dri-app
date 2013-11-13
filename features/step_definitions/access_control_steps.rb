Given /^the object with pid "(.*?)" has "(.*?)" masterfile$/ do |pid, permission|
  pid = "dri:o" + @random_pid if (pid == "@random")
  mapping = {}
  mapping['accessible'] = "1"
  mapping['inaccessible'] = "0"
  mapping['inherited'] = "-1"

  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.add_file_reference("masterContent", {:url => "http://johndadlez.com/MP3/BTAS2_D1_45_Gotham.mp3", :mimeType => "audio/mpeg3"})
  object.master_file = mapping[permission].to_s
  object.save
end

Given /^the object with pid "(.*?)" is under embargo$/ do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.embargo = 2.weeks.from_now
  object.save
end

Given /^the object with pid "(.*?)" has no read access for my user$/ do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.rightsMetadata.read_access.machine.person = ["another@user.com"]
  object.save
end

Given /^the object with pid "(.*?)" has no read access for my group$/ do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.rightsMetadata.read_access.machine.group = ["notmygroup"]
  object.save
end

Given /^the object with pid "(.*?)" has public discover access and metadata$/ do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.rightsMetadata.discover_access.machine.group = ["public"]
  object.rightsMetadata.metadata.machine.integer = "0"
  object.save
end

Given /^the object with pid "(.*?)" has permission "(.*?)" for "(.*?)" "(.*?)"$/ do |pid, permission, entity, id|
  pid = "dri:o" + @random_pid if (pid == "@random")
  if permission == 'inherited access'
    object = ActiveFedora::Base.find(pid, {:cast => true})
    fedora_document = ActiveFedora::Base.find(object.governing_collection.pid, {:cast => true})
  elsif permission == 'read access'
    fedora_document = ActiveFedora::Base.find(pid, {:cast => true})
  else
    fedora_document = nil
  end

  case entity
    when 'user'
      email = "#{id}@#{id}.com"
        fedora_document.rightsMetadata.read_access.machine.person = [email]
    when 'group'
        fedora_document.rightsMetadata.read_access.machine.group = id
  end
  fedora_document.save
end

Given(/^the object with pid "(.*?)" is governed by the collection with pid "(.*?)"$/) do |obj, coll|
  coll = "dri:c" + @random_pid if (coll == "@random")
  obj = "dri:o" + @random_pid if (obj == "@random")
  object = ActiveFedora::Base.find(obj, {:cast => true})
  collection = ActiveFedora::Base.find(coll, {:cast => true})
  collection.governed_items << object
  collection.save
end

Given /^the object with pid "(.*?)" is published$/ do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.status = "published"
  object.save
end

Given /^the object with pid "(.*?)" is publicly readable$/ do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.rightsMetadata.read_access.machine.group = ["public"]
  object.save
end

Given(/^the object with pid "(.*?)" has a deliverable surrogate file$/) do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  Storage::S3Interface.create_bucket(object.pid.sub('dri:', ''))
  case object.type
    when "Sound"
      Storage::S3Interface.store_surrogate(object.pid,  File.join(cc_fixture_path, 'SAMPLEA.mp3'), object.pid + '_mp3_web_quality.mp3')
    when "Article"
      Storage::S3Interface.store_surrogate(object.pid,  File.join(cc_fixture_path, 'SAMPLEA.pdf'), object.pid + '_pdf_web_quality.pdf')
  end
end
