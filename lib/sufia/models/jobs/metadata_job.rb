# require 'fileutils'
# require 'mini_exiftool'

class MetadataJob < ActiveFedoraPidBasedJob
require 'fileutils'

  def queue_name
    :thumbnail
  end

  #
  # This method return the solr object with identifier obj_id
  #
  def retrieve_object(obj_id)
#    puts "[DEBUG][MetadataJob.retrieve_object(...)] - STARTING ..."    
    obj = ActiveFedora::Base.find(obj_id,{:cast => true})
#    puts "[DEBUG][MetadataJob.retrieve_object(...)] - ... DONE"    
    return obj
  end
  #
  # This method prints some generic information on the passed object
  #
  def print_generic_info(obj)
#    puts "[DEBUG][MetadataJob.print_generic_info(...)] - STARTING ..."    
    puts "[DEBUG][#{Time.now}][MetadataJob.print_generic_info(...)] obj is #{obj}"
    puts "[DEBUG][#{Time.now}][MetadataJob.print_generic_info(...)] obj class is #{obj.class}"
#    puts "[DEBUG][MetadataJob.print_generic_info(...)] - ... DONE"    
  end
  #
  # If the passed object is an array, this method returns its first element
  #
  def flatten_object(obj)
#    puts "[DEBUG][MetadataJob.flatten_object(...)] - STARTING ..."    
    if(obj!= nil)
      if obj.kind_of?(Array)  
 #        puts "[DEBUG][#{Time.now}][MetadataJob.flatten_array(...)] - Object is an #{obj.class}, returning only the first element"    
         obj = obj[0]
 #        puts "[DEBUG][#{Time.now}][MetadataJob.flatten_array(...)] - Object is now a #{obj.class}"    
      end      
    end
#    puts "[DEBUG][MetadataJob.flatten_(...)] - ... DONE"    
    return obj
  end
  #
  # This method prints all the solr data of the current object obj
  #
  def print_solr_data(obj)    
#    puts "[DEBUG][MetadataJob.print_solr_data(...)] - STARTING ..."    
    if(obj!= nil)        
      solr_data = obj.to_solr
      if(solr_data!= nil)           
         solr_data.each do |key, value|
         puts "-----------------------------------------------------------------"
         puts "obj[#{key}] = #{solr_data[key]}" 
         puts "-----------------------------------------------------------------"
      end
      else
         puts "[DEBUG][MetadataJob.print_solr_data] solr_data is nil"    
      end  
    else
      puts "[DEBUG][MetadataJob.print_solr_data] object is nil"      
    end
#    puts "[DEBUG][MetadataJob.print_solr_data(...)] - ... DONE"    
  end
  #
  # This method returns the id of the parent object obj.
  #
  def get_parent_id(obj)
#    puts "[DEBUG][MetadataJob.get_parent_id(...)] - STARTING ..."    
    obj_solr_data = obj.to_solr
    container_ssim = obj_solr_data["isPartOf_ssim"] 
#    puts "[DEBUG][MetadataJob.get_parent_id(...)] - ... DONE"    
    return container_ssim
  end
  #
  # This method returns the right statement of the object.
  #
  def get_rights_statement(obj)
#    puts "[DEBUG][MetadataJob.get_rights_statement(...)] - STARTING ..."    
    obj_solr_data = obj.to_solr
    rights = obj_solr_data["rights_eng_tesim"] 
#    puts "[DEBUG][MetadataJob.get_rights_statement(...)] - ... DONE"    
    return rights
  end
  #
  # This method returns the id of the parent object obj.
  #
  def retrieve_surrogates(obj, file)
#    puts "[DEBUG][#{Time.now}][MetadataJob.retrieve_surrogates(#{obj},#{file})] STARTING...."
    storage = Storage::S3Interface.new
    surrogates = storage.get_surrogates(obj, file)
#    puts "[DEBUG][#{Time.now}][MetadataJob.retrieve_surrogates(#{obj},#{file})] DONE."
    return surrogates
  end
  #
  # Checks if the download location exists, if it does not, then it creates it
  #    
  def validate_location(dir)
#    puts "[DEBUG][#{Time.now}][MetadataJob.validate_location(#{dir})] STARTING...."
    if Dir.exists?(dir)
#       puts "[DEBUG][#{Time.now}][MetadataJob.validate_location()] #{dir} exists"      
     else
       puts "[DEBUG][#{Time.now}][MetadataJob.validate_location()] #{dir} DOES NOT exist, creating it..."      
       FileUtils::mkdir_p dir
    end 
#    puts "[DEBUG][#{Time.now}][MetadataJob.validate_location(#{dir})] .... DONE"
  end
  #
  # This method defines the location and name of the file where the object must be stored locally.
  #
  def make_filename(url, dir)
#    puts "[DEBUG][#{Time.now}][MetadataJob.make_filename(#{url})] STARTING...."
    # puts "[DEBUG][#{Time.now}][MetadataJob.make_filename url is #{url}]"
#    download_location = "/tmp/dri-downloads/"
    # puts "[DEBUG][#{Time.now}][MetadataJob.make_filename download_location is #{download_location}]"
    filename = dir + url.split(/\?/).first.split(/\//).last
    # puts "[DEBUG][#{Time.now}][MetadataJob.make_filename Filename for #{url} is #{filename}]"
#    puts "[DEBUG][#{Time.now}][MetadataJob.make_filename(#{url})] DONE."
    return filename
  end
  #
  # This method downloads an url.
  #
  def download_file(url, filename)  
    #
    # TODO : This variable should be global to the system
    #
#    puts "[DEBUG][#{Time.now}][MetadataJob.download_file(#{url})to #{filename}] STARTING..."

#    puts filename
#    puts "[DEBUG][#{Time.now}][MetadataJob.download_file] download_location is #{download_location}"
#    puts "[DEBUG][#{Time.now}][MetadataJob.download_file] Filename is #{filename}"
#    puts system("ls -la #{download_location}")
#    puts system("pwd #{download_location}")
#    puts system("ls -la #{download_location}")
#    Curl::Easy.download(url)
    Curl::Easy.download(url, filename)
#    puts system("ls -la #{download_location}")
#    puts system( "ls -la #{location}" )

#    puts "[DEBUG][#{Time.now}][MetadataJob.download_file(#{url}) to #{filename}] DONE."
  end
  #
  # This method edits the exif fields.
  #
  def edit_file(filename, rights)  
#    puts "[DEBUG][#{Time.now}][MetadataJob.edit_file()] STARTING..."
    if(File.exists?(filename))
#        puts "[DEBUG][#{Time.now}][MetadataJob.edit_file()] #{filename} exists..."
#        puts system("ls -la")
        cmd = "exiftool -a -u -g1 #{filename} | grep Rights"
#        puts cmd
#        puts system(cmd)
        system(cmd)
        cmd = "exiftool -Rights=#{rights} #{filename}"
#        puts cmd
#        puts system(cmd)
        system(cmd)
        cmd = "exiftool -a -u -g1 #{filename} | grep Rights"
#        puts cmd
#        puts system(cmd)
        system(cmd)
    else
        puts "[DEBUG][#{Time.now}][MetadataJob.edit_file()] #{filename} DOES NOT exist..."
    end  
  end
  #
  # This method substitutes the file.
  #
  def substitute_surrogate(key, file, id)
#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(#{key}, #{file}, #{id})] STARTING...."
#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(...) Key is #{key}"
#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(...) file is #{file}"
#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(...) id is #{id}"

#    filelist = storage.list_files(id)
#    puts filelist

    storage = Storage::S3Interface.new
    fname = File.basename file
#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(...)] Removing remote file #{fname}, STARTING...."
#    filelist = storage.list_files(id)
#    puts filelist
    storage.delete_surrogates(id, fname)
#    filelist = storage.list_files(id)
#    puts filelist
#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(...)] Removing remote file #{fname}, .... DONE"

#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(...)] Adding edited file #{fname}, STARTING...."
#    filelist = storage.list_files(id)
#    puts filelist
    storage.store_surrogate(id, file, fname)
#    filelist = storage.list_files(id)
#    puts filelist
#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(...)] Adding edited file #{fname}, .... DONE"

#    storage.delete_surrogates()

#    puts "[DEBUG][#{Time.now}][MetadataJob.upload_surrogate(...)] Removing remote file #{fname}, .... DONE"
#    filelist = storage.list_files(id)
#    puts filelist
#    puts "[DEBUG][#{Time.now}][MetadataJob.upload_surrogate(...)] Uploading local file #{file}, STARTING...."
#    storage.store_file(key, file, id)
#    puts "[DEBUG][#{Time.now}][MetadataJob.upload_surrogate(...)] Uploading local file #{file}, ....DONE"
#    filelist = storage.list_files(id)
#    puts filelist
#    puts "[DEBUG][#{Time.now}][MetadataJob.substitute_surrogate(#{key}, #{file}, #{id})] DONE...."
  end

  def test_surrogates(obj, file, rights, location)    
#    puts "-------------------------------------------------------------------"
#    puts "[DEBUG][#{Time.now}][MetadataJob.test_surrogates(...)] STARTING...."
#    puts "-------------------------------------------------------------------"

    tmp_surrogates = retrieve_surrogates(obj, file)  
#    puts "[DEBUG][#{Time.now}][MetadataJob.run] -> surrogates are #{surrogates}"
    #
    # Checks if there are surrogates for this asset ! 
    #    
    if tmp_surrogates.nil?      
      puts "[DEBUG][#{Time.now}][MetadataJob.run] -> surrogates is null; there are no surrogates for #{obj} !"
    else
      if tmp_surrogates.empty?
        puts "[DEBUG][#{Time.now}][MetadataJob.run] -> surrogates is empty; there are no surrogates for #{obj} !"
      else
#        puts "[DEBUG][#{Time.now}][MetadataJob.run] -> There are #{tmp_surrogates.length} surrogates for #{obj} !"
        #
        # Checks if the download location exists, if it does not, then it creates it
        #    
#        tmp_download_location = create_download_location()
#        tmp_download_location = "/tmp/dri-downloads/id_tmp/"
#        validate_location(tmp_download_location)
        #
        # Downloading all the surrogates to the local storage
        #        
        tmp_surrogates.each do |tmp_key, tmp_value|
           tmp_current_url =  tmp_surrogates[tmp_key]
#           puts "[DEBUG][#{Time.now}][MetadataJob.run] -> current_url is #{tmp_current_url}]"
           tmp_current_filename = make_filename(tmp_current_url, location)
#           puts "[DEBUG][#{Time.now}][MetadataJob.run] -> current_filename is #{tmp_current_filename}]"
           download_file(tmp_current_url, tmp_current_filename)
           puts "[DEBUG][#{Time.now}][MetadataJob.run] -> Printing right statement of (#{tmp_current_filename})]"
           puts "-----------------------------------------------------------------------------------------------"
           cmd = "exiftool -a -u -g1 #{tmp_current_filename} | grep Rights"
           puts system(cmd)
           puts "-----------------------------------------------------------------------------------------------"
        end
      end
    end
  end

  #
  # This method reads a file and returns its content
  #  
  def read_file(file_name)
    puts "[DEBUG][#{Time.now}][MetadataJob.read_file(#{file_name})] STARTING ..."   
    file = File.open(file_name, "r")
    data = file.read
    print_generic_info(data)
    puts "[DEBUG][#{Time.now}][MetadataJob.read_file(#{file_name})] File content is #{data}"   
    file.close
    puts "[DEBUG][#{Time.now}][MetadataJob.read_file(#{file_name})] ... DONE"   
    return data
  end
  #
  # This method creates a unique name (timestamped) for the download location
  #
#  def create_download_location_new()
#    tmpdir = Dir.mktmpdir
#    puts "---------------------------------------------------------------------------------------------"
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> **** tmpdir is #{tmpdir}"
#    puts "---------------------------------------------------------------------------------------------"
    # Read root from configuration file
    # Looks for it in the running directory
#    conffile = "dri.metadatajob.conf"
    #
    # If the file is not present, use default value
    #
#    if(File.exist?(conffile))
#      puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> #{conffile} exists !"   
#      root_loc = read_file(conffile).to_s
#      root_loc.chop()
#    else
#      puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> #{conffile} DOES NOT exists !"   
#      root_loc = "/tmp/dri-downloads/"
#    end
#    root_loc = "/tmp/dri-downloads/"
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> root_loc is #{root_loc}"   
#    print_generic_info(root_loc)
#    uid = Time.now.to_i.to_s
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> uid is #{uid}"   
#    print_generic_info(uid)
#    puts "#{root_loc}#{uid}"
#    loc = "#{root_loc}#{uid}"
#    loc = root_loc + uid
#    loc = File.join(root_loc, uid)
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> #{loc} will be used for downloading !"
#    print_generic_info(loc)
#    return File.join(root_loc, uid)
#    return loc
#  end

  def create_download_location()
#    puts "---------------------------------------------------------------------------------------------"
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> Starting..."
#    puts "---------------------------------------------------------------------------------------------"
    tmpdir = Dir.mktmpdir
    tmpdir = tmpdir+"/"
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> download locations is #{tmpdir}"   

    # Read root from configuration file
    # Looks for it in the running directory
#    conffile = "dri.metadatajob.conf"
    #
    # If the file is not present, use default value
    #
#    if(File.exist?(conffile))
#      puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> #{conffile} exists !"   
#      root_loc = read_file(conffile).to_s
#      root_loc.chop()
#    else
#      puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> #{conffile} DOES NOT exists !"   
#      root_loc = "/tmp/dri-downloads/"
#    end
#    root_loc = "/tmp/dri-downloads/"
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> root_loc is #{root_loc}"   
#    print_generic_info(root_loc)
#    uid = Time.now.to_i.to_s
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> uid is #{uid}"   
#    print_generic_info(uid)
#    puts "#{root_loc}#{uid}"
#    loc = "#{root_loc}#{uid}"
#    loc = root_loc + uid
#    loc = File.join(root_loc, uid)
#    puts "[DEBUG][#{Time.now}][MetadataJob.create_download_location(...)] -> #{loc} will be used for downloading !"
#    print_generic_info(loc)
#    return File.join(root_loc, uid)
#    return "/tmp/dri-downloads/"+Time.now.to_i
    return tmpdir
  end
  
  #
  # This method deletes the download location and all the files inside
  #
  def delete_download_location(location)
#      puts system("ls -la /tmp/dri-downloads/")     
      FileUtils.rm_r location
#      puts system("ls -la /tmp/dri-downloads/")     
  end  
  #
  # This method executes the job.
  #
  def run
    puts "----------------------------------------------------------------"
    puts "[DEBUG][#{Time.now}][MetadataJob.run] STARTING...."
    puts "----------------------------------------------------------------"
    #
    # Retrieve the object defined by the current id
    #
#    print_generic_info(generic_file)
#    print_generic_info(generic_file.id)
    current_file = retrieve_object(generic_file.id)
#    print_generic_info(current_file)
    current_file = flatten_object(current_file)
#    print_generic_info(current_file)
#    print_solr_data(current_file)
    #
    # Getting Parent Object ID
    current_object_id = get_parent_id(current_file)
#    print_generic_info(current_object_id)
    puts "[DEBUG][#{Time.now}][MetadataJob.run] -> The parent of #{generic_file.id} is #{current_object_id}"
    #
    # Getting the Parent Object
    #
#    print_generic_info(current_object_id)
    current_object_id = flatten_object(current_object_id)
#    print_generic_info(current_object_id)

    current_object = retrieve_object(current_object_id)    
#    print_generic_info(current_object)
    current_object = flatten_object(current_object)    
#    print_generic_info(current_object)

#    print_solr_data(current_object)
#    puts current_object
#    print_solr_data(current_object)
#    print_short_information_with_id(current_object, current_object_id)
    #
    # Storing right statement for writing into exif metadata
    #    
    current_object_rights = get_rights_statement(current_object)
    puts "[DEBUG][#{Time.now}][MetadataJob.run] -> The right statement of #{current_object} is #{current_object_rights}"
    #
    # Retrieving all the surrogates of the current object
    #    
    surrogates = retrieve_surrogates(current_object, current_file)  
#    puts "[DEBUG][#{Time.now}][MetadataJob.run] -> surrogates are #{surrogates}"
    #
    # Checks if there are surrogates for this asset ! 
    #    
    if surrogates.nil?      
      puts "[DEBUG][#{Time.now}][MetadataJob.run] -> surrogates is null; there are no surrogates for #{current_object} !"
    else
      if surrogates.empty?
        puts "[DEBUG][#{Time.now}][MetadataJob.run] -> surrogates is empty; there are no surrogates for #{current_object} !"
      else
        puts "[DEBUG][#{Time.now}][MetadataJob.run] -> There are #{surrogates.length} surrogates for #{current_object} !"
        #
        # Checks if the download location exists, if it does not, then it creates it
        #    
#        puts "[DEBUG][#{Time.now}][MetadataJob.run] -> Create Download Location, starting.... !"
        download_location = create_download_location()
#        puts "[DEBUG][#{Time.now}][MetadataJob.run] -> download_location is #{download_location}"
        validate_location(download_location)
        #
        # Downloading all the surrogates to the local storage
        #        
        surrogates.each do |key, value|
           current_url =  surrogates[key]
#           puts "[DEBUG][#{Time.now}][MetadataJob.run] -> current_url is #{current_url}]"
           current_filename = make_filename(current_url, download_location)
#          puts "[DEBUG][#{Time.now}][MetadataJob.run] -> current_filename is #{current_filename}]"
           download_file(current_url, current_filename)
           edit_file(current_filename, current_object_rights)
           substitute_surrogate(key, current_filename, current_object_id)
        end
        delete_download_location(download_location)
        test_download_location = create_download_location()
        puts "[DEBUG][#{Time.now}][MetadataJob.run] -> Test download_location is #{test_download_location}"
        validate_location(test_download_location)
        test_surrogates(current_object, current_file, current_object_rights, test_download_location)    
        delete_download_location(test_download_location)
      end
    end
    puts "---------------------------------------------------------"
    puts "[DEBUG][#{Time.now}][MetadataJob.run] DONE."
    puts "---------------------------------------------------------"
  end  
end