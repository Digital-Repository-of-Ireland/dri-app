# -*- encoding : utf-8 -*-
require "#{Blacklight.root}/app/controllers/saved_searches_controller"
class SavedSearchesController < ApplicationController
  def index
    @searches = current_user.searches.order('created_at DESC')
    params[:per_page] = params[:per_page] || 9
    @searches = @searches.page(params[:page]).per(params[:per_page])
  end
end
