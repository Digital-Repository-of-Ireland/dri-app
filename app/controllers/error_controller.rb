class ErrorController < ApplicationController
  def error_404
    redirect_to error_404_url
  end

  def error_422
    redirect_to error_422_url
  end

  def error_500
    redirect_to error_500_url
  end
end
