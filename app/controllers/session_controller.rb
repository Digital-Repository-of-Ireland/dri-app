class SessionController < ApplicationController

  def create
    unless cookies[:lang].nil?
      cookies.delete :lang
    end
    cookies.permanent[:lang] = params[:id]
    cookies.permanent[:creator] = "session controller"
    if !current_user.nil? && params[:id] != current_user.locale
      current_user.locale = params[:id]
      current_user.save
    end
    params.delete(:id)
    redirect_to root_path
  end

end