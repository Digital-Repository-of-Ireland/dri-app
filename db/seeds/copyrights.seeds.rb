def copyright_data
  [
    {
      name: 'In-Copyright',
      description: 'In Copyright',
      url: 'https://rightsstatements.org/page/InC/1.0/',
      logo: 'https://rightsstatements.org/files/buttons/InC.dark-white-interior.png'
    },
    {
      name: 'Educational-Use',
      description: 'In Copyright Educational Use Permitted',
      url: 'https://rightsstatements.org/page/InC-EDU/1.0/',
      logo: 'https://rightsstatements.org/files/buttons/InC-EDU.dark-white-interior.png'
    },
    {
      name: 'EU-Orphan-work ',
      description: 'In Copyright - EU Orphan work',
      url: 'https://rightsstatements.org/page/InC-OW-EU/1.0/',
      logo: 'https://rightsstatements.org/files/buttons/InC-OW-EU.dark-white-interior.png'
    },
    {
      name: 'No-Copyright',
      description: 'No Copyright',
      url: 'https://creativecommons.org/publicdomain/mark/1.0/',
      logo: 'https://mirrors.creativecommons.org/presskit/buttons/88x31/png/publicdomain.png'
    }
  ]
end
  
  # Load default Copyright
  def add_copyrights
    copyright_data.each do |args_hash|
      Copyright.create(args_hash)
    end
  end
  
  def remove_copyrights
    copyrights.each do |args_hash|
      Copyright.destroy_all(args_hash)
    end
  end
  
  puts "Seeding: #{__FILE__}"
  add_copyrights