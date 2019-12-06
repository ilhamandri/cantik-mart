class RetursController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  def index
    filter = filter_search params, "html"
    @search = filter[0]
    @returs = filter[1]
    @params = params.to_s

    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params, "pdf"
        @search = filter[0]
        @returs = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "returs/print_all.html.slim"
      end
    end
  end

  def new
    @suppliers = Supplier.order("supplier_type DESC").all
    if params[:item_id].present?
      @supplier_items = SupplierItem.where(item_id: params[:item_id])
      if @supplier_items.count > 1
        urls = item_suppliers_path(id: params[:item_id])
        return redirect_back_data_error urls, "Data Barang Supplier Tidak Ditemukan"
      end
    end
    if params[:supplier_id].present?
      @supplier_id = params[:supplier_id].to_i
    else
      @supplier_id = @suppliers.first.id.to_i
    end

    @supplier_items = SupplierItem.where(supplier_id: @supplier_id)
    all_options = ""
    @supplier_items.each do |supplier_item|
      s_item = supplier_item.item
      all_options+= "<option value="+s_item.id.to_s+" data-subtext='"+s_item.item_cat.name+"'>"+s_item.name+"</option>"
    end
    gon.select_options = all_options

    ongoing_order_ids = Order.where('date_receive is null and date_paid_off is null').pluck(:id)
    @ongoing_order_items = OrderItem.where(order_id: ongoing_order_ids)

    @inventories = StoreItem.page param_page
    store_id = current_user.store.id
    @inventories = @inventories.where(store_id: store_id).where('stock < min_stock')

    gon.inv_count = @inventories.count + 2
  end

  def create
    invoice = "RE-" + Time.now.to_i.to_s
    items = retur_items
    return redirect_back_data_error new_retur_path, "Data Item Tidak Boleh Kosong" if items.empty?
    total_item = items.size
    address_to = params[:retur][:supplier_id]

    retur = Retur.create invoice: invoice,
      total_items: total_item,
      store_id: current_user.store.id,
      date_created: Time.now,
      supplier_id: address_to,
      user_id: current_user.id
    
    retur.create_activity :create, owner: current_user
    items.each do |retur_item|
      item = StoreItem.find_by(item_id:retur_item[0], store: current_user.store)
      if item.nil? 
        ReturItem.where(retur: retur).delete_all
        retur.delete
        return redirect_back_data_error new_retur_path, "Data Barang Retur Tidak Tersedia di Toko"
      end
      description = "-"
      description = retur_item[5] if retur_item[5].size > 0
      ReturItem.create item_id: retur_item[0], retur_id: retur.id, quantity: retur_item[4], description: description
    end
    urls = retur_path(id: retur.id)
    set_notification(current_user, User.find_by(store: current_user.store, level: User::SUPERVISI), 
        Notification::INFO, "Konfirmasi retur "+retur.invoice, urls)
    return redirect_success urls, "Data Retur Telah Disimpan"
  end

  def confirmation
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless params[:id].present?
    @retur = Retur.find params[:id]
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" if @retur.nil?
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" if @retur.date_picked.present? || @retur.date_approve.present?
    @retur_items = ReturItem.where(retur_id: @retur.id)
  end

  def accept
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless params[:id].present?
    retur = Retur.find params[:id]
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" if retur.nil?
    return redirect_back_data_error returs_path, "Data Retur Tidak Valid" if retur.date_picked.present? || retur.date_approve.present?
    items = retur_items
    any_item_to_retur = false
    items.each do |item|
      retur_item = ReturItem.find item[0]
      break if retur_item.nil?
      break if retur_item.quantity < item[1].to_i
      retur_item.accept_item = item[1]
      any_item_to_retur = true if item[1].to_i > 0
      retur_item.save!

      store_item = StoreItem.find_by(item: retur_item.item, store: current_user.store)

      if store_item.stock <= store_item.min_stock
        set_notification current_user, current_user, "warning", store_item.item.name + " berada dibawah limit", warning_items_path
      end
    end
    retur.date_approve = Time.now
    retur.approved_by = current_user

    if !any_item_to_retur
      retur.date_picked = Time.now - 50.years
      retur.picked_by = current_user
      retur.status = Time.now - 50.years
    end

    retur.save!
    return redirect_success retur_path(id: params[:id]), "Retur Telah Dikonfirmasi"
  end

  def picked
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless params[:id].present?
    retur = Retur.find params[:id]
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" if retur.nil?
    return redirect_back_data_error returs_path, "Data Retur Tidak Valid" unless retur.date_picked.present? || retur.date_approve.present?
    retur.date_picked = Time.now
    retur.picked_by = current_user
    retur.save!
    urls = retur_path(id: retur.id)
    set_notification(current_user, User.find_by(store: current_user.store, level: User::SUPERVISI), 
        Notification::INFO, "Retur "+retur.invoice+" telah diambil", urls)
    decrease_stock params[:id]
    return redirect_success urls, "Retur Telah Diambil Suplier"
  end

  def destroy
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless params[:id].present?
    retur = Retur.find params[:id]
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless retur.present?
    return redirect_back_data_error returs_path, "Data Retur Tidak Valid" if retur.date_approve.present?
    ReturItem.where(retur_id: params[:id]).destroy_all
    retur.destroy
    return redirect_success returs_path, "Date Retur Berhasil Dihapus"
  end

  def show
    return redirect_back_data_error returs_path, "Data Retur Tidak Ditemukan" unless params[:id].present?
    @retur = Retur.find_by(id: params[:id])
    @retur_items = ReturItem.page param_page
    @retur_items = @retur_items.where(retur: @retur)
    respond_to do |format|
      format.html
      format.pdf do
        @recap_type = "retur"
        render pdf: @retur.invoice,
          layout: 'pdf_layout.html.erb',
          template: "returs/print.html.slim"
      end
    end
  end

  private
    def filter_search params, r_type
      results = []
      @returs = Retur.all.order("created_at DESC")
      if r_type == "html"
        @returs = @returs.page param_page if r_type=="html"
      end
      @returs = @returs.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
      @search = ""
      if params["search"].present?
        @search += "Pencarian "+params["search"]
        search = params["search"].downcase
        @returs =@returs.where("invoice like ?", "%"+ search+"%")
      end

      before_months = params["months"].to_i
      if before_months != 0
        @search += before_months.to_s + " bulan terakhir "
        start_months = (DateTime.now - before_months.months).beginning_of_month.beginning_of_day 
        @returs = @returs.where("created_at >= ?", start_months)
      end

      store_name = "SEMUA TOKO"
      if params["store_id"].present?
        store = Store.find_by(id: params["store_id"])
        if store.present?
          @returs = @returs.where(store: store)
          store_name = store.name
          @search += "Pencarian" if @search==""
          @search += " di Toko '"+store.name+"' "
        else
          @search += "Pencarian" if @search==""
          @search += " di Semua Toko "
        end
      end

      if params["type"].present?
        @color = ""
        @search += "Pencarian " if @search==""
        type = params["type"]
        if type == "pick" 
          @color = "warning"
          @search += "dengan status menunggu pengambilan supplier"
          @returs = @returs.where('date_approve is not null AND date_picked is null').order("date_created DESC")
        elsif type == "feedback"
          @color = "danger"
          @search += "dengan status menunggu hasil"
          @returs = @returs.where('date_picked is not null AND status is null').order("date_created DESC")
         elsif type == "complete"
          @color = "success"
          @search += "dengan status selesai"
          @returs = @returs.where('status is not null').order("date_created DESC")
        elsif type == "confirm"
          @returs = @returs.where('date_approve is null').order("date_created DESC")
          @color = "info"
          @search += "dengan status menunggu konfirmasi"
        end
      end

      results << @search
      results << @returs
      results << store_name
      return results
    end


    def retur_items
      items = []
      if params[:retur][:retur_items].present?
        params[:retur][:retur_items].each do |item|
          items << item[1].values
        end
      end
      items
    end

    def decrease_stock retur_id
      retur_items = ReturItem.where(retur_id: retur_id)
      retur_items.each do |retur_item|
        confirmation = retur_item.accept_item
        item = StoreItem.find_by(item_id: retur_item.item.id, store_id: current_user.store.id)
        new_stock = item.stock.to_i - confirmation.to_i
        item.stock = new_stock
        item.save!
      end
    end

    def param_page
      params[:page]
    end

end
