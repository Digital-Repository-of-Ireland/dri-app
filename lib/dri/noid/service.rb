module DRI::Noid
  class Service

    def initialize
      if Settings.noid
        case Settings.noid.service
        when 'ndlib'
          @service = DRI::Noid::Ndlib.new
        when 'af'
          @service = Noid::Rails::Service.new
        end
      else
        @service = Noid::Rails::Service.new
      end
    end

    def mint
      @service.mint
    end
  end
end
