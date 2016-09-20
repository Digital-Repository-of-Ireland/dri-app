class SessionController < ApplicationController
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
    redirect_to params[:path]
  end
end
