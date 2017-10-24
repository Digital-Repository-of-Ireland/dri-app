module PreservationHelpers

   def local_storage_dir
     Rails.root.join(Settings.dri.files)
   end

   def aip_dir
     File.join(local_storage_dir, build_hash_dir)
   end

   def version_path(version)
      File.join(aip_dir, version_string(version))
   end

    # data path
    def data_path(version)
      File.join(version_path(version), "data")
    end

    # output: partial path string e.g. "1c/18/df/87/1c18df87m/v0001"
    def content_path(version)
      File.join(data_path(version), "content")
    end

    # Return the metadata path
    def metadata_path(version)
      File.join(data_path(version), "metadata")
    end

    # Return the manifest path
    def manifest_path(version)
      File.join(version_path(version), "manifests")
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
    def build_hash_dir
      dir = ""
      index = 0
      id = object.id

      4.times {
        dir = File.join(dir, id[index..index+1])
        index += 2
      }

      File.join(dir, id)
    end

  end
