module PIDGenerator

  # Generates a Nice Opaque Identifier (NOID).

  class IdService
    # Template for the NOID. Generates a random 8 character number with 
    # extended digits at chars 3,4 and 7,8, and a final computed check character
    @@minter = Noid::Minter.new(:template => '.reeddeeddk')

    # Prefix used in the ID (defined in the application.rb configuration)
    @@namespace = NuigRnag::Application.config.id_namespace

    # Tests that identifier conforms to the template
    def self.valid?(identifier)
      # remove the namespace since it's not part of the noid
      noid = identifier.split(":").last
      return @@minter.valid? noid
    end

    # Generate the next NOID. Will cycle until an unused ID is found.
    def self.mint
      while true
        pid = self.next_id
        break unless ActiveFedora::Base.exists?(pid)
      end
      return pid
    end

    protected
    def self.next_id
      # seed with process id so that if two processes are running they do not come up with the same id.
      @@minter.seed($$)
      return  "#{@@namespace}:#{@@minter.mint}"
    end

  end

end
