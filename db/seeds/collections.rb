module Seeds
  def self.add_collections
    create_collection('save')
  end

  def self.add_collections!
    create_collection('save!')
  end

  def self.remove_collections
    DRI::QualifiedDublinCore.find(title: 'test_collection').each do |collection|
      collection.destroy
    end
  end

  def self.remove_collections!
    DRI::QualifiedDublinCore.find(title: 'test_collection').each do |collection|
      collection.destroy!
    end
  end

  private

  def self.create_collection(func)
    # only use email for associating object with user?
    admin = User.find(1).email
    collection = create_object(admin, 'test_collection', type: 'Collection')

    2.times do |n|
      collection.governed_items << create_object(admin, "test_object_#{n}")
    end
    collection.governed_items.map(&func.to_sym)
    collection.send(func)
  end

  # @param [String] owner
  # @param [String] title
  # @param [String] access
  # @param [String] type
  # @return DRI::QualifiedDublicCore
  def self.create_object(owner, title, access: 'public', type: 'Object')
    # institute = Institute.all.sample.name # random institute
    institute = Institute.first.name
    object = DRI::Batch.with_standard :qdc
    object.title = [title]
    object.description = ['this is a test']

    object.apply_depositor_metadata(owner)
    object.manager_users_string = owner
    object.creator = [owner]
    object.discover_groups_string = access
    object.read_groups_string = access
    object.master_file_access = access
    object.depositing_institute = institute
    object.role_org = [institute]

    object.object_type = [type]
    object.type = [type]

    # has to be a string
    # otherwise Error: undefined method `gsub' for 25:Integer
    object.creation_date = ["#{Time.now}"]
    object.rights = ['CC-BY']
    object.licence = 'CC-BY'
    object
  end
end
