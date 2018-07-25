class SessionController < ApplicationController
  rescue_from ActionController::RedirectBackError, with: :redirect_to_default

  def create
    cookies.delete :lang unless cookies[:lang].nil?

    cookies.permanent[:lang] = params[:id]
    cookies.permanent[:metadata_language] = params[:metadata_language]
    cookies.permanent[:creator] = 'session controller'
    if current_user && params[:id] != current_user.locale
      current_user.locale = params[:id]
      current_user.save
    end
    params.delete(:id)
    params.delete(:metadata_language)
    #TODO: change to redirect_back when we upgrade to Rails 5
    redirect_to(:back)
  end

  def redirect_to_default
    redirect_to main_app.root_path
  end
end
