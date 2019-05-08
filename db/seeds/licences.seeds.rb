def licence_data
  [
    {
      name: 'All Rights Reserved',
      description: 'Please see copyright statement'
    },
    {
      name: 'CC-BY',
      description: 'Creative Commons Attribution 4.0 International License',
      url: 'http://creativecommons.org/licenses/by/4.0/',
      logo: 'http://i.creativecommons.org/l/by/4.0/88x31.png'
    },
    {
      name: 'CC-BY-SA',
      description: 'Creative Commons Attribution-ShareAlike 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-sa/4.0/',
      logo: 'http://i.creativecommons.org/l/by-sa/4.0/88x31.png'
    },
    {
      name: 'CC-BY-ND',
      description: 'Creative Commons Attribution-NoDerivatives 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-nd/4.0/',
      logo: 'http://i.creativecommons.org/l/by-nd/4.0/88x31.png'
    },
    {
      name: 'CC-BY-NC',
      description: 'Creative Commons Attribution-NonCommercial 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-nc/4.0/',
      logo: 'http://i.creativecommons.org/l/by-nc/4.0/88x31.png'
    },
    {
      name: 'CC-BY-NC-SA',
      description: 'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-nc-sa/4.0/',
      logo: 'http://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png'
    },
    {
      name: 'CC-BY-NC-ND',
      description: 'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-nc-nd/4.0/',
      logo: 'http://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png'
    },
    {
      name: 'CC0',
      description: 'Creative Commons Public Domain Attribution',
      url: 'http://creativecommons.org/publicdomain/zero/1.0/',
      logo: ''
    },
    {
      name: 'ODC-ODbL',
      description: 'Open Data Commons Open Database Licence 1.0',
      url: 'http://opendatacommons.org/licenses/odbl/summary/',
      logo: ''
    },
    {
      name: 'ODC-BY',
      description: 'Open Data Commons Attribution License 1.0',
      url: 'http://opendatacommons.org/licenses/by/1.0/',
      logo: ''
    },
    {
      name: 'ODC-PPDL',
      description: 'Open Data Commons Public Domain Dedication and Licence',
      url: 'http://opendatacommons.org/licenses/pddl/summary/',
      logo: ''
    },
    {
      name: 'Orphan Work',
      description: 'This asset has been registered in the OAMI EU Orphan Works Database',
      url: 'https://oami.europa.eu/orphanworks/',
      logo: ''
    }
  ]
end

# Load default licences
def add_licences
  licence_data.each do |args_hash|
    Licence.create(args_hash)
  end
end

def remove_licences
  licences.each do |args_hash|
    Licence.destroy_all(args_hash)
  end
end

puts "Seeding: #{__FILE__}"
add_licences
