module PreservationHelpers

   def local_storage_dir
     Rails.root.join(Settings.dri.files)
   end

   def version_path(batch, version)
      File.join(local_storage_dir, build_hash_dir(batch), version_string(version))
    end

    # data path
    def data_path(batch, version)
      File.join(version_path(batch,version), "data")
    end

    # output: partial path string e.g. "1c/18/df/87/1c18df87m/v0001"
    def content_path(batch, version)
      File.join(data_path(batch, version), "content")
    end

    # Return the metadata path
    def metadata_path(batch, version)
      File.join(data_path(batch, version), "metadata")
    end

    # Return the manifest path
    def manifest_path(batch, version)
      File.join(version_path(batch,version), "manifests")
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

      4.times {
        dir = File.join(dir, batch[index..index+1])
        index += 2
      }

      File.join(dir, batch)

    end

  end
