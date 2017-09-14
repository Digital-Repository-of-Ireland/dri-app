Given /^the object with (pid|title) "(.*?)" has "(.*?)" masterfile$/ do |type, pid, permission|
  pid = "o" + @random_pid if (pid == "@random")

  if type == "title"
    query = "title_tesim:#{URI.encode(pid)}"
    pid = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  else
    pid = "o" + @random_pid if (pid == "@random")
  end

  mapping = {}
  mapping['accessible'] = "public"
  mapping['inaccessible'] = "private"
  mapping['inherited'] = "inherit"

  object = DRI::Identifier.retrieve_object(pid)

  DRI::GenericFile.any_instance.stub(:characterize_if_changed)

  gf = DRI::GenericFile.new
  gf.apply_depositor_metadata(object.depositor)
  gf.digital_object = object
  gf.save

  file = LocalFile.new(fedora_id: gf.id, ds_id: "content")
  uploaded = Rack::Test::UploadedFile.new(File.join(cc_fixture_path, "SAMPLEA.mp3"), "audio/mp3")
  file.add_file(uploaded, { :directory => Dir.tmpdir })
  file.save

  actor = DRI::Asset::Actor.new(gf, current_user)  
  actor.create_content(uploaded, uploaded.original_filename, "content", uploaded.content_type)
  gf.save

  object.master_file_access = mapping[permission].to_s
  object.save
end

Given /the masterfile for object with title "(.*?)" is "(.*?)"$/ do |title, permission|
  mapping = {}
  mapping['accessible'] = "public"
  mapping['inaccessible'] = "private"
  mapping['inherited'] = "inherit"

  query = "title_tesim:#{URI.encode(title)}"
  id = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  object = DRI::Identifier.retrieve_object(id)
  object.master_file_access = mapping[permission].to_s
  object.save
end

Given /^the object with pid "(.*?)" is under embargo$/ do |pid|
  pid = "o" + @random_pid if (pid == "@random")
  object = DRI::Identifier.retrieve_object(pid)
  object.embargo = 2.weeks.from_now
  object.save
end

Given /^the object with (pid|title) "(.*?)" has no read access for my user$/ do |type,pid|
  if type == 'title'
    query = "title_tesim:#{URI.encode(pid)}"
    pid = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  end

  pid = "o" + @random_pid if (pid == "@random")
  object = DRI::Identifier.retrieve_object(pid)
  object.read_users_string = "another@user.com"
  object.read_groups_string = ""
  object.save
  object.reload
end

Given /^the object with pid "(.*?)" has no read access for my group$/ do |pid|
  pid = "o" + @random_pid if (pid == "@random")
  object = DRI::Identifier.retrieve_object(pid)
  object.read_groups_string = "notmygroup"
  object.save
end

Given /^the object with (pid|title) "(.*?)" is restricted to the reader group$/ do |type,pid|
  if type == "title"
    query = "title_tesim:#{URI.encode(pid)}"
    pid = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  else
    pid = "o" + @random_pid if (pid == "@random")
  end

  object = DRI::Identifier.retrieve_object(pid)
  object.read_groups_string = pid
  object.save
end

Given /^the object with pid "(.*?)" has public discover access and metadata$/ do |pid|
  pid = "o" + @random_pid if (pid == "@random")
  object = DRI::Identifier.retrieve_object(pid)
  object.discover_groups_string = "public"
  object.save
end

Given /^the object with pid "(.*?)" has permission "(.*?)" for "(.*?)" "(.*?)"$/ do |pid, permission, entity, id|
  pid = "o" + @random_pid if (pid == "@random")
  if permission == 'inherited access'
    object = DRI::Identifier.retrieve_object(pid)
    fedora_document = DRI::Identifier.retrieve_object(object.governing_collection.noid)
  elsif permission == 'read access'
    fedora_document = DRI::Identifier.retrieve_object(pid)
  else
    fedora_document = nil
  end

  case entity
    when 'user'
      email = "#{id}@#{id}.com"
        fedora_document.read_users_string = email
    when 'group'
        fedora_document.read_groups_string = id
  end
  fedora_document.save
end

Given(/^the object with pid "(.*?)" is governed by the collection with pid "(.*?)"$/) do |obj, coll|
  coll = "c" + @random_pid if (coll == "@random")
  obj = "o" + @random_pid if (obj == "@random")
  object = DRI::Identifier.retrieve_object(obj)
  collection = DRI::Identifier.retrieve_object(coll)
  collection.governed_items << object
  collection.save
end

Given /^the (collection|object) with pid "(.*?)" has status (.*?)$/ do |type,pid,status|
  pid = "o" + @random_pid if (pid == "@random")
  object = DRI::Identifier.retrieve_object(pid)
  object.status = status
  object.save
end

Given /^the (collection|object) with title "(.*?)" has status (.*?)$/ do |type,title,status|
  query = "title_tesim:#{URI.encode(title)}"
  id = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  object = DRI::Identifier.retrieve_object(id)
  object.status = status
  object.save
end

Given /^the object with pid "(.*?)" is publicly readable$/ do |pid|
  pid = "o" + @random_pid if (pid == "@random")
  object = DRI::Identifier.retrieve_object(pid)
  object.read_groups_string = "public"
  object.save
end

Given(/^the object with pid "(.*?)" has a deliverable surrogate file$/) do |pid|
  pid = "" + @random_pid if (pid == "@random")
  object = DRI::Identifier.retrieve_object(pid)
  generic_file = object.generic_files.first
  storage = StorageService.new
  storage.create_bucket(object.noid)
  case object.type.first
    when "Sound"
      storage.store_surrogate(object.noid, File.join(cc_fixture_path, 'SAMPLEA.mp3'), generic_file.noid + '_mp3.mp3')
    when "Text"
      storage.store_surrogate(object.noid, File.join(cc_fixture_path, 'SAMPLEA.pdf'), generic_file.noid + '_thumbnail.png')
    when "Image"
      storage.store_surrogate(object.noid, File.join(cc_fixture_path, 'sample_image.png'), "#{generic_file.noid}_thumbnail.png")
  end
end

