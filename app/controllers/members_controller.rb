class MembersController < ApplicationController
  before_action :require_login
  def index
    @members = Member.page param_page
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      @members = @members.where("lower(name) like ? OR phone like ?", search, search)
    end
  end

  def new
  end

  def create
    member = Member.new member_params
    return redirect_to new_member_path if member.invalid?

    member.save!
    return redirect_to members_path
  end

  def edit
    return redirect_back_no_access_right unless params[:id].present?
    @member = Member.find_by_id params[:id]
    return redirect_to members_path unless @member.present?
  end

  def update
    return redirect_back_no_access_right unless params[:id].present?
    member = Member.find_by_id params[:id]
    member.assign_attributes member_params
    member.save! if member.changed?
    return redirect_to members_path
  end

  private
    def member_params
      params.require(:member).permit(
        :name, :phone, :address, :card_number, :id_card, :sex
      )
    end

    def param_page
      params[:page]
    end

end
