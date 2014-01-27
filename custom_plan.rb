require 'zeus/rails'

class CustomPlan < Zeus::Rails

    def rspec(argv=ARGV)
        # disable autorun in case the user left it in spec_helper.rb
        RSpec::Core::Runner.disable_autorun!
        exit RSpec::Core::Runner.run(argv)
    end

    def test
        require 'simplecov'
        SimpleCov.start 
        # SimpleCov.start 'rails' if using RoR

        # require all ruby files
        Dir["#{Rails.root}/app/**/*.rb"].each { |f| load f }

        # run the tests
        super
    end

end

Zeus.plan = CustomPlan.new
