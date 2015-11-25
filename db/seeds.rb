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
  puts "Running seed licences"
  Licence.create(:name => 'All Rights Reserved', :description => 'Please see copyright statement')
  Licence.create(:name => 'CC-BY', :description => 'Creative Commons Attribution 4.0 International License', :url => 'http://creativecommons.org/licenses/by/4.0/', :logo => 'http://i.creativecommons.org/l/by/4.0/88x31.png')
  Licence.create(:name => 'CC-BY-SA', :description => 'Creative Commons Attribution-ShareAlike 4.0 International License', :url => 'http://creativecommons.org/licenses/by-sa/4.0/', :logo => 'http://i.creativecommons.org/l/by-sa/4.0/88x31.png')
  Licence.create(:name => 'CC-BY-ND', :description => 'Creative Commons Attribution-NoDerivatives 4.0 International License', :url => 'http://creativecommons.org/licenses/by-nd/4.0/', :logo => 'http://i.creativecommons.org/l/by-nd/4.0/88x31.png')
  Licence.create(:name => 'CC-BY-NC', :description => 'Creative Commons Attribution-NonCommercial 4.0 International License', :url => 'http://creativecommons.org/licenses/by-nc/4.0/', :logo => 'http://i.creativecommons.org/l/by-nc/4.0/88x31.png')
  Licence.create(:name => 'CC-BY-NC-SA', :description => 'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License', :url => 'http://creativecommons.org/licenses/by-nc-sa/4.0/', :logo => 'http://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png')
  Licence.create(:name => 'CC-BY-NC-ND', :description => 'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License', :url => 'http://creativecommons.org/licenses/by-nc-nd/4.0/', :logo => 'http://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png')
  Licence.create(:name => 'CC0', :description => 'Creative Commons Public Domain Attribution', :url => 'http://creativecommons.org/publicdomain/zero/1.0/', :logo => '')
  Licence.create(:name => 'ODC-ODbL', :description => 'Open Data Commons Open Database Licence 1.0', :url => 'http://opendatacommons.org/licenses/odbl/summary/', :logo => '')
  Licence.create(:name => 'ODC-BY', :description => 'Open Data Commons Attribution License 1.0', :url => 'http://opendatacommons.org/licenses/by/1.0/', :logo => '')
  Licence.create(:name => 'ODC-PPDL', :description => 'Open Data Commons Public Domain Dedication and Licence', :url => 'http://opendatacommons.org/licenses/pddl/summary/', :logo => '')
  Licence.create(:name => 'Orphan Work', :description => 'This asset has been registered in the OAMI EU Orphan Works Database', :url => 'https://oami.europa.eu/orphanworks/', :logo => '')
  puts "Ran seed licences"
end

licences()
