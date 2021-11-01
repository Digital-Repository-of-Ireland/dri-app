# frozen_string_literal: true
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

    def path_for_type(type, object_id, version)
      if type == 'content'
        content_path(object_id, version)
      elsif type == 'metadata'
        metadata_path(object_id, version)
      end
    end

    # Return formatted version number for the file path
    # versions start at 0, but MOAB expects v0001 as first version
    # output: incremented & formatted version number String of format vxxxx
    def version_string(version)
      format('v%04d', version)
    end

    # Return the hash part of the file path
    # input (optional): object_id String (fedora object id)
    # output: partial path String e.g. "1c/18/df/87/1c18df87m"
    def build_hash_dir(object_id)
      dir = ""
      index = 0

      4.times do
        dir = File.join(dir, object_id[index..index + 1])
        index += 2
      end

      File.join(dir, object_id)
    end

    def make_dir(paths)
      FileUtils.mkdir_p(paths)
    rescue StandardError => e
      Rails.logger.error "Unable to create MOAB directory #{paths}. Error: #{e.message}"
      raise DRI::Exceptions::InternalError
    end

    def attached_file_match?(file, md5)
      (Checksum.md5_string(file.content) == md5) ||
        (Checksum.md5_string(file.to_xml) == md5)
    end
  end
end
