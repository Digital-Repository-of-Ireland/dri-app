# Code for [CANCAN] access to Hydra models
require 'cancan'
module Hydra
  module Ability
    extend ActiveSupport::Concern
    
    # once you include Hydra::Ability you can add custom permission methods by appending to ability_logic like so:
    #
    # self.ability_logic +=[:setup_my_permissions]
    
    included do
      include CanCan::Ability
      include Hydra::PermissionsQuery
      include Blacklight::SolrHelper
      include UserGroup::InheritanceMethods
      class_attribute :ability_logic
      self.ability_logic = [:create_permissions, :edit_permissions, :read_permissions, :custom_permissions]
      #383 Addition
      self.ability_logic +=[:manager_permissions, :search_permissions, :master_file_permissions]
    end

    def self.user_class
      Hydra.config[:user_model] ?  Hydra.config[:user_model].constantize : ::User
    end

    attr_reader :current_user, :session, :cache

    def initialize(user, session=nil)
      @current_user = user || Hydra::Ability.user_class.new # guest user (not logged in)
      @user = @current_user # just in case someone was using this in an override. Just don't.
      @session = session
      @cache = Hydra::PermissionsCache.new
      #Default: Giving same level as edit
      alias_action :edit, :update, :destroy, :to => :manage_collection
      hydra_default_permissions()
    end

    #383 Modified
    ## You can override this method if you are using a different AuthZ (such as LDAP)
    def user_groups
      return @user_groups if @user_groups
      @user_groups = default_user_groups
      @user_groups |=  UserGroup::Group.find(current_user.full_memberships.pluck(:group_id)).map(&:name) if current_user and current_user.respond_to? :full_memberships
      @user_groups
    end

    def default_user_groups
      # # everyone is automatically a member of the group 'public'
      [SETTING_GROUP_PUBLIC]
    end
    

    def hydra_default_permissions
      logger.debug("Usergroups are " + user_groups.inspect)
      self.ability_logic.each do |method|
        send(method)
      end
    end

    def create_permissions
      #can :create, :all if user_groups.include? 'registered'
    end

    #TEMP:: Removed some permissions, must find out what an edit user can do
    def edit_permissions
      can [:edit, :update], String do |pid|
        logger.debug("[EDITPERM] Checking from STRING")
        test_edit(pid)
      end 

      can [:edit, :update, :destroy], DRI::Model::DigitalObject do |obj|
        logger.debug("[EDITPERM] Checking from DRI::Model::DO")
        test_edit(obj.pid)
      end

      #No destroy?
      can [:edit,:update], DRI::Model::Collection do |obj|
        logger.debug("[EDITPERM] Checking from DRI::Model::Collection")
        test_edit(obj.pid)
      end
      
      can :edit, SolrDocument do |obj|
        logger.debug("[EDITPERM] Checking from SOLRDOC")
        cache.put(obj.id, obj)
        test_edit(obj.id)
      end       
    end

    #383 - Now means access to assets
    def read_permissions
      can :read, String do |pid|
        logger.debug("[READPERM] Checking from STRING")
        test_read(pid)
      end

      can :read, [DRI::Model::DigitalObject, DRI::Model::Collection] do |obj|
        logger.debug("[READPERM] Checking from Object")
        test_read(obj.pid)
      end

      
      can :read, SolrDocument do |obj|
        logger.debug("[READPERM] Checking from SolrDoc")
        cache.put(obj.id, obj)
        test_read(obj.id)
      end 
    end

    #383 Additions

    #This is for when the metadata is private and users specifically have
    #Search access which allows them to view the DO but NOT the assets
    def search_permissions
      can :search, String do |pid|
        logger.debug("[SEARCHPERM] Checking from STRING")
        test_search(pid)
      end

      can :search, [DRI::Model::DigitalObject, DRI::Model::Collection] do |obj|
        logger.debug("[SEARCHPERM] Checking from Object")
        test_search(obj.pid)
      end 
      
      can :search, SolrDocument do |obj|
        logger.debug("[SEARCHPERM] Checking from SolrDoc")
        cache.put(obj.id, obj)
        test_search(obj.id)
      end
    end

    def master_file_permissions
      can :read_master, String do |pid|
        logger.debug("[master_file_permissions] Checking from STRING")
        test_read_master(pid)
      end

      can :read_master, [DRI::Model::DigitalObject, DRI::Model::Collection] do |obj|
        logger.debug("[master_file_permissions] Checking from Object")
        test_read_master(obj.pid)
      end 
      
      can :read_master, SolrDocument do |obj|
        logger.debug("[master_file_permissions] Checking from SolrDoc")
        cache.put(obj.id, obj)
        test_read_master(obj.id)
      end
    end

    #These are manager_permissions on a DO level
    #NOT the permissions a user gets if they are a collection manager
    def manager_permissions
      can :manage_collection, String do |pid|
        logger.debug("[MANPERM] Checking from STRING")
        test_manager(pid)
      end

      can :manage_collection, [DRI::Model::DigitalObject, DRI::Model::Collection] do |obj|
        logger.debug("[MANPERM] Checking from Object")
        test_manager(obj.pid)
      end 
      
      can :manage_collection, SolrDocument do |obj|
        logger.debug("[MANPERM] Checking from SolrDoc")
        cache.put(obj.id, obj)
        test_manager(obj.id)
      end
    end

    ## Override custom permissions in your own app to add more permissions beyond what is defined by default.
    def custom_permissions
      #Collection Manager Permissions
      #Higher power than edit user...[Dont want edit users to be able to DELETE a COLLECTION??, (Delete a DO?)]
      if current_user.applicable_policy?(SETTING_POLICY_COLLECTION_MANAGER)
        #Marked as being able to :manage_collection
        can :manage_collection_flag, :all
        can :create, DRI::Model::Collection
      end


      #Admin Permissions
      if current_user.applicable_policy?(SETTING_POLICY_ADMIN)
        can :admin_flag, :all
        #Disabled for now..
        #can :manage, :all
      end

      #Create_do flag (alias for :edit collection)
      can :create_do, String do |pid|
        test_create(pid)
      end

      can :create_do, DRI::Model::Collection do |collection|
        test_create(collection)
      end
    end
    
    protected
    def test_create(collection)
      return can? :edit, collection
    end

    def test_edit(pid)
      logger.debug("[CANCAN] Checking edit permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
      group_intersection = user_groups & edit_groups(pid)
      result = !group_intersection.empty? || edit_persons(pid).include?(current_user.user_key)
      logger.debug("[CANCAN] decision: #{result}")
      result
    end   
    
    def test_read(pid)
      logger.debug("[CANCAN] Checking read permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
      group_intersection = user_groups & read_groups(pid)
      result = !group_intersection.empty? || read_persons(pid).include?(current_user.user_key)
      result
    end

    def test_search(pid)
      logger.debug("[CANCAN] Checking search permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
      group_intersection = user_groups & search_groups(pid)
      result = !group_intersection.empty? || search_persons(pid).include?(current_user.user_key)
    end

    def test_read_master(pid)
      #show master true -> test_read, if false, test_edit permission
      return get_permission_method(pid,"show_master_file?") ? test_read(pid) : test_edit(pid)
    end 

    def test_manager(pid)
      logger.debug("[CANCAN] Checking manager permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")
      group_intersection = user_groups & manager_groups(pid)
      result = !group_intersection.empty? || manager_persons(pid).include?(current_user.user_key)
    end
    
    #383 Modified. manager implies edit, so edit_groups is the union of manager and edit groups    
    def edit_groups(pid)
      eg = manager_groups(pid) | ( get_permission_key(pid,self.class.edit_group_field) || [])
      logger.debug("[CANCAN] edit_groups: #{eg.inspect}")
      return eg
    end

    #edit implies read, so read_groups is the union of edit and read groups
    def read_groups(pid)
      rg = edit_groups(pid) | ( get_permission_key(pid,self.class.read_group_field) || [])
      logger.debug("[CANCAN] read_groups: #{rg.inspect}")
      return rg
    end

    #383 Modified. manager implies edit, so edit_persons is the union of manager and edit persons
    def edit_persons(pid)
      ep = manager_persons(pid) | ( get_permission_key(pid,self.class.edit_person_field) ||  [])
      logger.debug("[CANCAN] edit_persons: #{ep.inspect}")
      return ep
    end

    # edit implies read, so read_persons is the union of edit and read persons
    def read_persons(pid)
      rp = edit_persons(pid) | ( get_permission_key(pid,self.class.read_person_field) || [])
      logger.debug("[CANCAN] read_persons: #{rp.inspect}")
      return rp
    end

    #383 Addition. Managers are at the top level
    def manager_groups(pid)
      mg = get_permission_key(pid,self.class.manager_group_field) ||  []
      logger.debug("[CANCAN] manager_groups: #{mg.inspect}")
      return mg
    end

    #383 Addition
    def manager_persons(pid)
      mp = get_permission_key(pid,self.class.manager_person_field) ||  []
      logger.debug("[CANCAN] manager_persons: #{mp.inspect}")
      return mp
    end

    #383 Addition. A search group/person has access to a DO (but not the assets)
    def search_groups(pid)
      sg = read_groups(pid) | (get_permission_key(pid,self.class.search_group_field) ||  [])
      logger.debug("[CANCAN] search_groups: #{sg.inspect}")
      return sg
    end
    
    #383 Addition
    def search_persons(pid)
      sp = read_persons(pid) | (get_permission_key(pid,self.class.search_person_field) ||  [])
      logger.debug("[CANCAN] manager_persons: #{sp.inspect}")
      return sp
    end

    module ClassMethods
      def read_group_field 
        Hydra.config[:permissions][:read][:group]
      end

      def edit_person_field 
        Hydra.config[:permissions][:edit][:individual]
      end

      def read_person_field 
        Hydra.config[:permissions][:read][:individual]
      end

      def edit_group_field
        Hydra.config[:permissions][:edit][:group]
      end

      #383 Addition
      def manager_group_field
        Hydra.config[:permissions][:manager][:group]
      end

      #383 Addition
      def manager_person_field
        Hydra.config[:permissions][:manager][:individual]
      end

      #383 Addition
      def search_group_field
        Hydra.config[:permissions][:discover][:group]
      end
      
      #383 Addition
      def search_person_field
        Hydra.config[:permissions][:discover][:individual]
      end
    end

  end
end
