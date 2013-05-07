# Base controller for the asset managing controllers.
#
class AssetsController < ApplicationController
  include Hydra::AccessControlsEnforcement
  include DRI::Metadata
  include DRI::Model
  #Moved from application controller due to routing issues with devise
  include Blacklight::Catalog

  # Retrieves a Fedora Digital Object by ID
  def retrieve_object(id)
    enforce_permissions!
    return objs = ActiveFedora::Base.find(id,{:cast => true})
  end

  private
  #This might have to be moved/updated. Currently only checking upon retrieve object,
  #might want to change so each controller specifys when to check & what methods to check.
  def enforce_permissions!
    debugger
    action = params[:action]
    if action.nil? or action=="edit" or action=="update"
      unless can? :edit, params[:id]
          raise Hydra::AccessDenied.new(t('dri.flash.alert.edit_permission'), :edit, params[:id])
      end
    elsif action=="show"
      unless can? :read ,params[:id]
        raise Hydra::AccessDenied.new(t('dri.flash.alert.read_permission'), :read, params[:id])
      end
    elsif action=="create"
      #NOTE: create given to all users in registered by default
      unless can? :create ,params[:id]
        raise Hydra::AccessDenied.new(t('dri.flash.alert.create_permission'), :create, params[:id])
      end
    else
      raise Hydra::AccessDenied.new(t('Unsupported Permission Level'), :read, params[:id])
    end
  end
  
end