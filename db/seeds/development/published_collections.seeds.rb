def add_published_collections
  create_collection('save')
end

def add_published_collections!
  create_collection('save!')
end

# @param func [String] the function collection calls to save itself
def create_collection(func)
  # only use email for associating object with user?
  admin = User.find(1).email
  collection = create_object(admin, 'test_collection', type: 'Collection')

  2.times do |n|
    collection.governed_items << create_object(admin, "test_object_#{n}")
  end
  collection.governed_items.map(&func.to_sym)
  collection.send(func)
  # refactor to use block and yield?
end

# @param owner [String]
# @param title [String]
# @param access [String]
# @param type [String]
# @return DRI::QualifiedDublicCore
def create_object(owner, title, access: 'public', type: 'Object')
  # institute = Institute.all.sample.name # random institute
  institute = Institute.where(depositing: true).sample.name
  object = DRI::DigitalObject.with_standard :qdc
  object.title = [title]
  object.description = ['this is a test']

  object.apply_depositor_metadata(owner)
  object.manager_users_string = owner
  object.creator = [owner]
  object.discover_groups_string = access
  object.read_groups_string = access
  object.status = 'published'
  object.master_file_access = access
  object.institute = [institute]
  object.depositing_institute = institute
  object.role_org = [institute]

  object.type = [type]

  # dates have to be string otherwise Error: undefined method `gsub' for 25:Integer
  object.creation_date = ["#{Time.now}"]
  object.published_date = ["#{Time.now}"]
  object.date = ["#{Time.now}"]
  object.rights = ['CC-BY']
  object.licence = 'CC-BY'
  object.copyright = 'In-Copyright'  
  object
end

puts "Seeding: #{__FILE__}"
add_published_collections
