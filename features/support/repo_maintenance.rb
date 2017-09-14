module RepoMaintenance


  def clean_repo
    identifiers = DRI::Identifier.all
    begin
      identifiers.each do |ident|
        object = ident.identifiable
        object.delete if DRI::Identifier.object_exists?(object.noid)
      end
    rescue Exception => e
    end
  end

end
World(RepoMaintenance)
