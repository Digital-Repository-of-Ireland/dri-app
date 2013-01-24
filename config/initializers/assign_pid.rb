module ActiveFedora
  class UnsavedDigitalObject
    def assign_pid
      @pid ||= PIDGenerator::IdService.mint
    end
  end
end
