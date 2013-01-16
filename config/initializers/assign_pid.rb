module ActiveFedora
  class UnsavedDigitalObject
    def assign_pid
      @pid ||= NuigRnag::IdService.mint
    end
  end
end
