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
end