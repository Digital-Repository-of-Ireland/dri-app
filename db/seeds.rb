require 'ffaker'

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
UserGroup::Engine.load_seed


# Load default licences
def licences()
  Licence.create(name: 'All Rights Reserved', description: 'Please see copyright statement')
  Licence.create(name: 'CC-BY', description: 'Creative Commons Attribution 4.0 International License', url: 'http://creativecommons.org/licenses/by/4.0/', logo: 'http://i.creativecommons.org/l/by/4.0/88x31.png')
  Licence.create(name: 'CC-BY-SA', description: 'Creative Commons Attribution-ShareAlike 4.0 International License', url: 'http://creativecommons.org/licenses/by-sa/4.0/', logo: 'http://i.creativecommons.org/l/by-sa/4.0/88x31.png')
  Licence.create(name: 'CC-BY-ND', description: 'Creative Commons Attribution-NoDerivatives 4.0 International License', url: 'http://creativecommons.org/licenses/by-nd/4.0/', logo: 'http://i.creativecommons.org/l/by-nd/4.0/88x31.png')
  Licence.create(name: 'CC-BY-NC', description: 'Creative Commons Attribution-NonCommercial 4.0 International License', url: 'http://creativecommons.org/licenses/by-nc/4.0/', logo: 'http://i.creativecommons.org/l/by-nc/4.0/88x31.png')
  Licence.create(name: 'CC-BY-NC-SA', description: 'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License', url: 'http://creativecommons.org/licenses/by-nc-sa/4.0/', logo: 'http://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png')
  Licence.create(name: 'CC-BY-NC-ND', description: 'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License', url: 'http://creativecommons.org/licenses/by-nc-nd/4.0/', logo: 'http://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png')
  Licence.create(name: 'CC0', description: 'Creative Commons Public Domain Attribution', url: 'http://creativecommons.org/publicdomain/zero/1.0/', logo: '')
  Licence.create(name: 'ODC-ODbL', description: 'Open Data Commons Open Database Licence 1.0', url: 'http://opendatacommons.org/licenses/odbl/summary/', logo: '')
  Licence.create(name: 'ODC-BY', description: 'Open Data Commons Attribution License 1.0', url: 'http://opendatacommons.org/licenses/by/1.0/', logo: '')
  Licence.create(name: 'ODC-PPDL', description: 'Open Data Commons Public Domain Dedication and Licence', url: 'http://opendatacommons.org/licenses/pddl/summary/', logo: '')
  Licence.create(name: 'Orphan Work', description: 'This asset has been registered in the OAMI EU Orphan Works Database', url:'https://oami.europa.eu/orphanworks/', logo: '')
end

def organisations()
  %w(test_institute other_test_institute last_test_institute).each do |institute_name|
    test_institute = Institute.new(
      name: institute_name,
      url: FFaker::Internet.domain_name,
      logo: 'fake_logo.png',
      depositing: true
    )
    test_institute.save
  end
end


def public_collections()
  # only use email for associating object with user?
  admin = User.find(1).email
  collection = create_object(admin, 'test_collection', type: 'Collection')

  2.times do |n|
    collection.governed_items << create_object(admin, "test_object_#{n}")
  end

  collection.governed_items.map(&:save)
  collection.save
end

private

# @param [String] owner
# @param [String] title
# @param [String] access
# @param [String] type
# @return DRI::QualifiedDublicCore
def create_object(owner, title, access: 'public', type: 'Object')
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
  object.role_org = institute

  object.object_type = [type]
  object.type = [type]

  # has to be a string
  # otherwise Error: undefined method `gsub' for 25:Integer
  object.creation_date = ["#{Time.now}"]
  object.rights = ['CC-BY']
  object.licence = 'CC-BY'
  object
end

# must run licences and organistations before collections
%w(licences organisations public_collections).each do |func|
  puts "running seed #{func}"
  send(func)
  puts "ran seed #{func}"
end
