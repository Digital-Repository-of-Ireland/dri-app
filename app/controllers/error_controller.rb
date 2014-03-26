class ErrorController < ApplicationController

  def error_404
    redirect_to error_404_path
  end

  def error_422
    redirect_to error_404_path
  end

  def error_500
    redirect_to error_404_path
  end

end