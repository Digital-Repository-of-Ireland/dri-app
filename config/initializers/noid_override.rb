require 'active_fedora/noid.rb'

# Need to override this as otherwise it returns
# incorrect paths for short IDs
ActiveFedora::Noid.class_eval do

  def self.treeify(identifier)
    id = identifier.split('/').first
    (id.scan(/..?/).first(4) + [identifier]).join('/')
  end

end
