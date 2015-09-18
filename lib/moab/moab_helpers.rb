module MoabHelpers

    def local_storage_dir
      Rails.root.join(Settings.dri.files)
    end


    # Return the hash dir and version dir part of the file path
    # if batch object id is passed in then it will use that
    # otherwise will use generic_file id
    # input (optional): batch string (fedora object id)
    # output: partial path string e.g. "1c/18/df/87/1c18df87m/v0001"
    def content_path(batch)
      File.join(build_hash_dir(batch), version_string(batch.object_version))
    end


    # Return formatted version number for the file path
    # versions start at 0, but MOAB expects v0001 as first version
    # output: incremented & formatted version number String of format vxxxx
    def version_string(version)
      'v%04d' % version.to_s
    end


    # Return the hash part of the file path
    # input (optional): batch String (fedora object id) 
    # output: partial path String e.g. "1c/18/df/87/1c18df87m"
    def build_hash_dir(batch)
      dir = ""
      index = 0
      pid = batch ? batch : self.fedora_id


      4.times {
        dir = File.join(dir, pid[index..index+1])
        index += 2
      }

      File.join(dir, pid)
    end


    # Return the version number
    # output: count Fixnum
    def version_number
      LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d", { :f => self.fedora_id, :d => self.ds_id }).count
    end

  end
