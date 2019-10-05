class PointsController < ApplicationController
  before_action :require_login

  def index
  	return redirect_back_data_error members_path, "Data tidak valid" if params[:id].nil?
  	@member = Member.find_by(id: params[:id])
  	return redirect_back_data_error members_path, "Data tidak valid" if @member.nil?
  	@points = Point.where(member: @member).page param_page

  end

  def new
  end

  private
  	def param_page
  		params[:page]
  	end
end
