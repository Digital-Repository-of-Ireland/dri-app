module DRI::Noid
  class Ndlib

    def initialize
      @client ||= RestClient::Resource.new(Settings.noid.endpoint)
      @pool = Settings.noid.pool
    end

    def mint
      Mutex.new.synchronize do
        while true
          pid = next_id
          return pid unless ActiveFedora::Base.exists?(pid) || ActiveFedora::Base.gone?(pid)
        end
      end
    end

    protected

    def next_id
      response = @client["pools/#{@pool}/mint"].post({n: 1}, {accept: :json})
      JSON.parse(response).first
    end
  end
end