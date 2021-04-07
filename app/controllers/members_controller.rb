class MembersController < ApplicationController
  before_action :require_login
  

  def index
    @members = Member.page param_page
    @search = ""
    if params["search"].present?
      @search += "Pencarian '" + params["search"].upcase + "' "
      search = "%"+params["search"].downcase+"%"
      @members = @members.where("lower(name) like ? OR phone like ?", search, search)
    end

    if params["store_id"].present?
      store = Store.find_by(id: params["store_id"])
      if store.present?
        @members = @members.where(store: store)
        @search += "Pencarian " if @search == ""
        @search += " pada Toko "+store.name
      else
        @search += "Pencarian " if @search == ""
        @search += " pada Semua Toko "
      end
    end
  end

  def new
  end

  def create
    member = Member.new member_params
    member.name = params[:member][:name].camelize
    member.user = current_user
    member.store = current_user.store
    member.point = 10
    return redirect_back_data_error new_member_path, "Nomor HP telah digunakan." if Member.find_by(phone: member.phone).present?
    return redirect_back_data_error new_member_path, "Nomor Kartu Tidak Valid. Silahkan Ganti dengan Kartu Lain. " if Member.find_by(card_number: member.card_number).present?
    return redirect_back_data_error new_member_path, "Data Member - " + member.name + " - Tidak Valid" if member.invalid?
    member.save!
    member.create_activity :create, owner: current_user
    urls = member_path id: member.id
    return redirect_success urls, "Member - " + member.name + " - Berhasil Ditambahkan"
  end

  def edit
    return redirect_back_data_error members_path, "Data Member Tidak Ditemukan" unless params[:id].present?
    @member = Member.find_by_id params[:id]
    return redirect_back_data_error members_path, "Data Member Tidak Ditemukan" unless @member.present?
  end

  def update
    return redirect_back_data_error members_path, "Data Member Tidak Ditemukan" unless params[:id].present?
    member = Member.find_by_id params[:id]
    member.assign_attributes member_params
    member.name = params[:member][:name].camelize
    changes = member.changes
    member.save! if member.changed?
    member.create_activity :edit, owner: current_user, parameters: changes
    urls = member_path id: member.id
    return redirect_success urls, "Member - " + member.name + " - Berhasil Diubah"
  end

  def show
    return redirect_back_data_error members_path, "Data Member Tidak Ditemukan" unless params[:id].present?
    @member = Member.find_by_id params[:id]
    return redirect_back_data_error members_path, "Data Member Tidak Ditemukan" unless @member.present?
    @transactions = Transaction.where(member_card: @member.card_number).order("date_created DESC")
    @trx_items = TransactionItem.where(transaction_id: @transactions.pluck(:id)).group(:item_id).count
    @points = Point.where(member: @member).order("created_at DESC").limit(10)
    @transactions = @transactions.limit(10)
    @trx_item_cats = Item.where(id: @trx_items.to_h.keys).group(:item_cat_id).count

    @trx_item_cats = @trx_item_cats.sort_by(&:last).reverse.first(10)
    @trx_items = @trx_items.sort_by(&:last).reverse.first(10)
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
