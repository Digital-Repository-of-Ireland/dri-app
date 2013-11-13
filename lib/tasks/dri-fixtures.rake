require 'active_fedora'

namespace :dri do
  
  desc "Init Hydra configuration" 
  task :init => [:environment] do
    # We need to just start rails so that all the models are loaded
  end

  namespace :fixtures do
    @fixtureDir = 'spec/fixtures'

    desc "Generate default Hydra fixtures"
    task :generate do
      ENV["dir"] = File.join(Rails.root, @fixtureDir) 
      fixtures = find_fixtures_erb
      fixtures.each do |fixture|
        outFile = fixture.sub('foxml.erb','foxml.xml')
        File.open(outFile, "w+") do |f|
          f.write(ERB.new(get_erb_template fixture).result())
        end
      end
    end
   
    desc "Load default Hydra fixtures"
    task :load do
      dir = File.join(Rails.root, @fixtureDir) 
      loader = ActiveFedora::FixtureLoader.new(dir)

      fixtures = find_fixtures
      fixtures.each do |fixture|
        loader.import_and_index(fixture)
        puts "Loaded '#{fixture}'"
      end
      raise "No fixtures found; you may need to generate from erb, use: rake dri:fixtures:generate" if fixtures.empty?
    end

    desc "Remove default Hydra fixtures"
    task :delete do
      ENV["dir"] = File.join(Rails.root, @fixtureDir)
      fixtures = find_fixtures
      fixtures.each do |fixture|
        ENV["pid"] = fixture
        Rake::Task["repo:delete"].reenable
        Rake::Task["repo:delete"].invoke
      end
    end

    desc "Refresh default Hydra fixtures"
    task :refresh => [:delete, :load]

    private

    def run_erb_stub(inputFile, outputFile)
      File.open(outputFile, "w+") do |f|
        f.write(ERB.new(get_erb_template inputFile).result())
      end
    end

    def find_fixtures
      Dir.glob(File.join(Rails.root, @fixtureDir, '*.foxml.xml')).map do |fixture_file|
        File.basename(fixture_file, '.foxml.xml').gsub('_',':')
      end
    end

    def find_fixtures_erb
      Dir.glob(File.join(Rails.root, @fixtureDir, '*.foxml.erb'))
    end

    def get_erb_template(file)
      File.read(file)
    end
  end
end
