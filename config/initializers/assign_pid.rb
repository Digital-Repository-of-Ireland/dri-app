module ActiveFedora
  class UnsavedDigitalObject
    def assign_pid
      @pid ||= ActiveFedora::Noid::Service.new.mint
    end
  end
end
