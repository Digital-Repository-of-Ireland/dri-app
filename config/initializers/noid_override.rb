require 'noid-rails'

# Need to override this as otherwise it returns
# incorrect paths for short IDs
Noid::Rails.class_eval do

  def self.treeify(identifier)
    id = identifier.split('/').first
    (id.scan(/..?/).first(4) + [identifier]).join('/') unless id.nil?
  end

end
