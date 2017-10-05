module DRI::Noid
  class Service

    def initialize
      @service = if Settings.noid
                   case Settings.noid.service
                   when 'ndlib'
                     DRI::Noid::Ndlib.new
                   when 'af'
                     ActiveFedora::Noid::Service.new
                   end
                 else
                   ActiveFedora::Noid::Service.new
                 end
    end
    
    def mint
      Mutex.new.synchronize do
        loop do
          pid = next_id
                    
          return pid unless DRI::Identifier.exists?(alternate_id: pid)
        end
      end
    end

    def next_id
      @service.respond_to?(:minter) ? @service.minter.send(:next_id) : @service.send(:next_id)
    end

  end
end
