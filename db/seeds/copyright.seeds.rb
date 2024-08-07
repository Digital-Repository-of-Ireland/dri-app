def copyright_data
  [
    {
      name: 'In Copyright',
      description: 'In Copyright',
      url: 'https://rightsstatements.org/page/InC/1.0/',
      logo: 'dri/home/inCopyright.png',
      supported: true
    },
    {
      name: 'Educational Use',
      description: 'In Copyright - Educational Use Permitted',
      url: 'https://rightsstatements.org/page/InC-EDU/1.0/',
      logo: 'dri/home/educationalUse.png',
      supported: true
    },
    {
      name: 'EU Orphan work',
      description: 'In Copyright - EU Orphan work',
      url: 'https://rightsstatements.org/page/InC-OW-EU/1.0/',
      logo: 'dri/home/orphanWork.png',
      supported: true
    },
    {
      name: 'No Copyright',
      description: 'No Copyright',
      url: 'https://creativecommons.org/publicdomain/mark/1.0/',
      logo: 'dri/home/publicdomain.png',
      supported: true
    }
  ]
end
  
def add_copyrights
  copyright_data.each do |args_hash|
    Copyright.create(args_hash)
  end
end
  
def remove_copyrights
  copyright_data.each do |args_hash|
    Copyright.destroy_all(args_hash)
  end
end
  
puts "Seeding: #{__FILE__}"
add_copyrights