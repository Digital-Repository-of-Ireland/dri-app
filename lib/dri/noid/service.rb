module DRI::Noid
  class Service

    def initialize
      if Settings.noid
        case Settings.noid.service
        when 'ndlib'
          @service = DRI::Noid::Ndlib.new
        when 'af'
          @service = ActiveFedora::Noid::Service.new
        end
      else
        @service = ActiveFedora::Noid::Service.new
      end
    end

    def mint
      @service.mint
    end
  end
end
