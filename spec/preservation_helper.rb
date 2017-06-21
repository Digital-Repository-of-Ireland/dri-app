module PreservationHelper

  def aip_dir(id)
    dir = ""
    index = 0
    4.times {
      dir = File.join(dir, id[index..index+1])
      index += 2
    }

    File.join(Settings.dri.files, dir, id)
  end

  def aip_valid?(id, version)
    storage_object = Moab::StorageObject.new(id, aip_dir(id))
    storage_object_version = Moab::StorageObjectVersion.new(storage_object, version_id=version)
    result = storage_object_version.verify_version_storage
    result.verified
  end

end