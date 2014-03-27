class SessionController < ApplicationController

  def create
    cookies.permanent[:lang] = params[:id]
    if !current_user.nil? && params[:id] != current_user.locale
      current_user.locale = params[:id]
      current_user.save
    end
    redirect_to root_path
  end

end