def licence_data
  [
    {
      name: 'Not licensed for re-use',
      description: 'See Additional Licence and Rights Information.',
      url: '',
      logo: ''
    },
    {
      name: 'CC-BY',
      description: 'Creative Commons Attribution 4.0 International License',
      url: 'http://creativecommons.org/licenses/by/4.0/',
      logo: 'dri/home/by.png'
    },
    {
      name: 'CC-BY-SA',
      description: 'Creative Commons Attribution-ShareAlike 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-sa/4.0/',
      logo: 'dri/home/by-sa.png'
    },
    {
      name: 'CC-BY-ND',
      description: 'Creative Commons Attribution-NoDerivatives 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-nd/4.0/',
      logo: 'dri/home/by-nd.png'
    },
    {
      name: 'CC-BY-NC',
      description: 'Creative Commons Attribution-NonCommercial 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-nc/4.0/',
      logo: 'dri/home/by-nc.png'
    },
    {
      name: 'CC-BY-NC-SA',
      description: 'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-nc-sa/4.0/',
      logo: 'dri/home/by-nc-sa.png'
    },
    {
      name: 'CC-BY-NC-ND',
      description: 'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License',
      url: 'http://creativecommons.org/licenses/by-nc-nd/4.0/',
      logo: 'dri/home/by-nc-nd.png'
    },
    {
      name: 'CC0',
      description: 'Creative Commons Public Domain Attribution',
      url: 'http://creativecommons.org/publicdomain/zero/1.0/',
      logo: 'dri/home/cc-zero.png'
    },
    {
      name: 'ODC-ODbL',
      description: 'Open Data Commons Open Database Licence 1.0',
      url: 'https://opendatacommons.org/licenses/odbl/1-0/',
      logo: ''
    },
    {
      name: 'ODC-BY',
      description: 'Open Data Commons Attribution License 1.0',
      url: 'http://opendatacommons.org/licenses/by/1.0/',
      logo: ''
    },
    {
      name: 'ODC-PDDL',
      description: 'Open Data Commons Public Domain Dedication and Licence',
      url: 'https://opendatacommons.org/licenses/pddl/1-0/',
      logo: ''
    },
    {
      name: 'Public Domain Mark',
      description: 'This asset has been registered in the OAMI EU Orphan Works Database',
      url: 'https://creativecommons.org/publicdomain/mark/1.0/',
      logo: 'dri/home/publicdomain.png'
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
          