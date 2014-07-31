Given /^the object with (pid|title) "(.*?)" has "(.*?)" masterfile$/ do |type, pid, permission|
  pid = "dri:o" + @random_pid if (pid == "@random")

  if type == "title"
    query = "title_tesim:#{URI.encode(pid)}"
    pid = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  else
    pid = "dri:o" + @random_pid if (pid == "@random")
  end

  mapping = {}
  mapping['accessible'] = "1"
  mapping['inaccessible'] = "0"
  mapping['inherited'] = "-1"

  object = ActiveFedora::Base.find(pid, {:cast => true})

  GenericFile.any_instance.stub(:characterize_if_changed)

  gf = GenericFile.new
  gf.apply_depositor_metadata(object.depositor)
  gf.batch = object
  gf.save

  file = LocalFile.new
  uploaded = Rack::Test::UploadedFile.new(File.join(cc_fixture_path, "SAMPLEA.mp3"), "audio/mp3")
  file.add_file(uploaded, { :directory => Dir.tmpdir, :fedora_id => gf.id, :ds_id => "content", :version => "0" })
  file.save

  url = url_for :controller=>"assets", :action=>"download", :object_id=>object.id, :id=>gf.id
  gf.update_file_reference "content", :url=>url, :mimeType=>"audio/mpeg3"
  gf.save

  object.rightsMetadata.masterfile.machine.integer = mapping[permission].to_s
  object.save
end

Given /the masterfile for object with title "(.*?)" is "(.*?)"$/ do |title, permission|
  mapping = {}
  mapping['accessible'] = "1"
  mapping['inaccessible'] = "0"
  mapping['inherited'] = "-1"

  query = "title_tesim:#{URI.encode(title)}"
  id = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  object = ActiveFedora::Base.find(id, {:cast => true})
  object.master_file = mapping[permission].to_s
  object.save
end

Given /^the object with pid "(.*?)" is under embargo$/ do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.embargo = 2.weeks.from_now
  object.save
end

Given /^the object with (pid|title) "(.*?)" has no read access for my user$/ do |type,pid|
  if type == 'title'
    query = "title_tesim:#{URI.encode(pid)}"
    pid = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  end

  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.rightsMetadata.read_access.machine.person = ["another@user.com"]
  object.rightsMetadata.read_access.machine.group = []
  object.save
  object.reload
end

Given /^the object with pid "(.*?)" has no read access for my group$/ do |pid|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.rightsMetadata.read_access.machine.group = ["notmygroup"]
  object.save
end

Given /^the object with (pid|title) "(.*?)" is restricted to the reader group$/ do |type,pid|
  if type == "title"
    query = "title_tesim:#{URI.encode(pid)}"
    pid = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  else
    pid = "dri:o" + @random_pid if (pid == "@random")
  end


  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.rightsMetadata.read_access.machine.group = pid
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

Given /^the (collection|object) with pid "(.*?)" has status (.*?)$/ do |type,pid,status|
  pid = "dri:o" + @random_pid if (pid == "@random")
  object = ActiveFedora::Base.find(pid, {:cast => true})
  object.status = status
  object.save
end

Given /^the (collection|object) with title "(.*?)" has status (.*?)$/ do |type,title,status|
  query = "title_tesim:#{URI.encode(title)}"
  id = ActiveFedora::SolrService.query(query, :fl => "id").first['id']
  object = ActiveFedora::Base.find(id, {:cast => true})
  object.status = status
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
  generic_file = GenericFile.find(:is_part_of_ssim => "info:fedora/#{object.pid}").first
  storage = Storage::S3Interface.new
  storage.create_bucket(object.pid.sub('dri:', ''))
  case object.type.first
    when "Sound"
      storage.store_surrogate(object.pid, File.join(cc_fixture_path, 'SAMPLEA.mp3'), generic_file.pid + '_mp3.mp3')
    when "Text"
      storage.store_surrogate(object.pid, File.join(cc_fixture_path, 'SAMPLEA.pdf'), generic_file.pid + '_thumbnail.png')
    when "Image"
      storage.store_surrogate(object.pid, File.join(cc_fixture_path, 'sample_image.png'), "#{generic_file.pid}_thumbnail.png")
  end
end

