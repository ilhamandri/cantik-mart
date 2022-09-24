class ServerInformationsController < ApplicationController
  before_action :require_login
  before_action :screening
  require 'usagewatch'

  def index
  	@usw = Usagewatch
  end

  private

end
