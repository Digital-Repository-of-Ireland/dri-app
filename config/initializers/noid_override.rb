require 'active_fedora/noid.rb'

ActiveFedora::Noid.class_eval do

  def self.treeify(identifier)
    id = identifier.split('/').first
    (id.scan(/..?/).first(4) + [identifier]).join('/')
  end

end
