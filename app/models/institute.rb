class Institute < ActiveRecord::Base
  attr_accessible :name, :url

  def add_institute(upload,opts={})
    self.name = opts[:name]
    self.url = opts[:url]
    begin
      raise Exceptions::InternalError unless self.save
    rescue ActiveRecordError => e
      logger.error "Could not save institute: #{e.message}"
      raise Exceptions::InternalError
    end

    count = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE 'instituteLogo'", { :f => self.name } ]).count
    dir = local_storage_dir.join(self.name).join("instituteLogo"+count.to_s)

    file = LocalFile.new
    file.add_file upload, {:fedora_id => self.name, :ds_id => "instituteLogo", :directory => dir.to_s, :version => count}

    begin
      raise Exceptions::InternalError unless file.save!
    rescue ActiveRecordError => e
      logger.error "Could not save the institute logo #{file.path} for #{object_id} : #{e.message}"
      raise Exceptions::InternalError
    end
  end

  def local_storage_dir
    Rails.root.join(Settings.dri.logos)
  end
end
