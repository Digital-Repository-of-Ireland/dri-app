module Preservation
  module PreservationHelpers

    def local_storage_dir
      Rails.root.join(Settings.dri.files)
    end

    def aip_dir(object_id)
      File.join(local_storage_dir, build_hash_dir(object_id))
    end

    def version_path(object_id, version)
      File.join(local_storage_dir, build_hash_dir(object_id), version_string(version))
    end

    # data path
    def data_path(object_id, version)
      File.join(version_path(object_id, version), "data")
    end

    # output: partial path string e.g. "1c/18/df/87/1c18df87m/v0001"
    def content_path(object_id, version)
      File.join(data_path(object_id, version), "content")
    end

    # Return the metadata path
    def metadata_path(object_id, version)
      File.join(data_path(object_id, version), "metadata")
    end

    # Return the manifest path
    def manifest_path(object_id, version)
      File.join(version_path(object_id, version), "manifests")
    end

    # Return formatted version number for the file path
    # versions start at 0, but MOAB expects v0001 as first version
    # output: incremented & formatted version number String of format vxxxx
    def version_string(version)
      'v%04d' % version.to_s
    end

    def verify(object_id)
      storage_object = ::Moab::StorageObject.new(object_id, aip_dir(object_id))
      storage_object_version = storage_object.current_version
      storage_object_version.verify_version_storage
    end

    # Return the hash part of the file path
    # input (optional): object_id String (fedora object id) 
    # output: partial path String e.g. "1c/18/df/87/1c18df87m"
    def build_hash_dir(object_id)
      dir = ""
      index = 0

      4.times {
        dir = File.join(dir, object_id[index..index+1])
        index += 2
      }

      File.join(dir, object_id)
    end

  end
end
