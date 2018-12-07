module RepoMaintenance
  require 'net/http'

  def clean_repo
    ActiveFedora::Cleaner.clean!

    url = URI(ActiveFedora::Fedora.instance.host)

    code = "0"
    while(code != "200") do
      Net::HTTP.start(url.host, url.port){|http|
        code = http.head('/rest/test').code
      }
    
      create_base_path
    end
  end

  def create_base_path
    #ActiveFedora::Base.find('test')
    ActiveFedora::Fedora.instance.connection.send(:init_base_path)
  rescue Exception
  end

end
World(RepoMaintenance)
