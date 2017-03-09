module RepoMaintenance


  def clean_repo
    fedora_objects = ActiveFedora::Base.all
    begin
      fedora_objects.each do |object|
        object.delete if ActiveFedora::Base.exists?(object.id)
      end
    rescue Exception => e
    end
  end

end
World(RepoMaintenance)
