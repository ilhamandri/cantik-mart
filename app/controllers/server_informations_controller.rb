class ServerInformationsController < ApplicationController
  before_action :require_login
  require 'usagewatch'

  def index
  	@usw = Usagewatch
  end

  private

end
