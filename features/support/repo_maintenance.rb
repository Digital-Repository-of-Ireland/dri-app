module RepoMaintenance


  def clean_repo
    fedora_objects = ActiveFedora::Base.all
    fedora_objects.each do |object|
      object.delete if ActiveFedora::Base.exists?(object.id)
    end
  end

end
World(RepoMaintenance)
