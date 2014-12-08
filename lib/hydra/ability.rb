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
      include UserGroup::SharedAbility

      class_attribute :ability_logic
      self.ability_logic = [:create_permissions, :edit_permissions, :read_permissions, :custom_permissions]
      #383 Addition
      self.ability_logic +=[:manager_permissions, :search_permissions, :master_file_permissions]
    end

    def self.user_class
      Hydra.config[:user_model] ?  Hydra.config[:user_model].constantize : ::User
    end

    def create_permissions
      #can :create, :all if user_groups.include? 'registered'
    end

    #TEMP:: Removed some permissions, must find out what an edit user can do
    def edit_permissions
      can [:edit, :update], String do |pid|
        Rails.logger.debug("[EDITPERM] Checking from STRING")
        test_edit(pid)
      end

      can [:edit, :update, :destroy], Batch do |obj|
        Rails.logger.debug("[EDITPERM] Checking from Batch")
        test_edit(obj.pid)
      end

      can [:edit, :update, :destroy], GenericFile do |obj|
        Rails.logger.debug("[EDITPERM] Checking from GenericFile")
        test_edit(obj.pid)
      end

      can :edit, SolrDocument do |obj|
        Rails.logger.debug("[EDITPERM] Checking from SOLRDOC")
        cache.put(obj.id, obj)
        test_edit(obj.id)
      end
    end

    #383 - Now means access to assets
    def read_permissions
      can :read, String do |pid|
        Rails.logger.debug("[READPERM] Checking from STRING")
        test_read(pid)
      end

      can :read, [Batch] do |obj|
        Rails.logger.debug("[READPERM] Checking from Object")
        test_read(obj.pid)
      end


      can :read, SolrDocument do |obj|
        Rails.logger.debug("[READPERM] Checking from SolrDoc")
        cache.put(obj.id, obj)
        test_read(obj.id)
      end
    end

    #383 Additions

    #This is for when the metadata is private and users specifically have
    #Search access which allows them to view the DO but NOT the assets
    def search_permissions
      can :search, String do |pid|
        Rails.logger.debug("[SEARCHPERM] Checking from STRING")
        test_search(pid)
      end

      can :search, [Batch] do |obj|
        Rails.logger.debug("[SEARCHPERM] Checking from Object")
        test_search(obj.pid)
      end

      can :search, SolrDocument do |obj|
        Rails.logger.debug("[SEARCHPERM] Checking from SolrDoc")
        cache.put(obj.id, obj)
        test_search(obj.id)
      end
    end

    def master_file_permissions
      can :read_master, String do |pid|
        Rails.logger.debug("[master_file_permissions] Checking from STRING")
        test_read_master(pid)
      end

      can :read_master, Batch do |obj|
        Rails.logger.debug("[master_file_permissions] Checking from Object")
        test_read_master(obj.pid)
      end

      can :read_master, SolrDocument do |obj|
        Rails.logger.debug("[master_file_permissions] Checking from SolrDoc")
        cache.put(obj.id, obj)
        test_read_master(obj.id)
      end
    end

    #These are manager_permissions on a DO level
    #NOT the permissions a user gets if they are a collection manager
    def manager_permissions
      can :manage_collection, String do |pid|
        Rails.logger.debug("[MANPERM] Checking from STRING")
        test_manager(pid)
      end

      can :manage_collection, Batch do |obj|
        Rails.logger.debug("[MANPERM] Checking from Object")
        test_manager(obj.pid)
      end

      can :manage_collection, SolrDocument do |obj|
        Rails.logger.debug("[MANPERM] Checking from SolrDoc")
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
        can :create, [Batch, GenericFile]
      end


      #Admin Permissions
      if current_user.applicable_policy?(SETTING_POLICY_ADMIN)
        can :admin_flag, :all
        #Disabled for now..
        can :manage, :all
      end

      #Create_do flag (alias for :edit collection)
      can :create_do, String do |pid|
        test_create(pid)
      end

      can :create_do, Batch do |collection|
        test_create(collection)
      end
    end

  end
end
