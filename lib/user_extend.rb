module UserGroup
    class User
        #Connects this user object to Hydra behaviors. 
        include Hydra::User
        #Connects this user object to Blacklights Bookmarks. 
        include Blacklight::User
        include HttpAcceptLanguage
        
        def to_s
            return self.email
        end   
    end
end