class GrocerItemsController < ApplicationController
  before_action :require_login
  before_action :screening
  
  def new
    return redirect_back_data_error items_path, "Data tidak valid" unless params[:id].present?
    item = Item.find_by_id params[:id]
    return redirect_back_data_error new_grocer_item_path, "Data tidak valid" unless item.present?
    @id = item.id
    @name = item.name
  end

  def create
    return redirect_back_data_error items_path, "Data tidak valid" unless params[:id].present?
    item = Item.find_by_id params[:id]
    return redirect_back_data_error new_grocer_item_path, "Data tidak valid" unless item.present?
    grocer_item = GrocerItem.new grocer_item_params
    grocer_item.price = params[:grocer_item][:price].gsub(".","").to_i
    grocer_item.item = item
    grocer_item.member_price = grocer_item.price
    min = grocer_item.min
    max = grocer_item.max
    grocer_items = GrocerItem.where(item: item)
    grocer_item.edited_by = current_user
    if grocer_item.discount <= 0
      return redirect_back_data_error item_path(id: item.id), "Silahkan Set Diskon Supaya Harga Jual Lebih Besar dari Harga Beli"
    end

    if grocer_item.discount < 100
      grocer_item.discount = grocer_item.price * grocer_item.discount / 100.0
    end

    grocer_item.ppn = grocer_item.price - ((grocer_item.price) / ((item.tax/100.0)+1))
    grocer_item.selisih_pembulatan = grocer_item.price - (((grocer_item.price) / ((item.tax/100.0)+1)) + grocer_item.ppn)

    if min < 2
      return redirect_back_data_error new_grocer_item_path, "Data tidak valid (1)"
    else
      if min > max 
        return redirect_back_data_error new_grocer_item_path, "Data tidak valid. Minimum dan Maximum terbalik."
      else
        check_same_value = grocer_items.where("max = ? OR max = ? OR min = ? OR min = ?", min, max, min, max)
        if check_same_value.present?
          return redirect_back_data_error new_grocer_item_path, "Data tidak valid (2)"
        else
          check_same_value = grocer_items.where("min < ? AND max > ? ", min, min)
          if check_same_value.present?
            return redirect_back_data_error new_grocer_item_path, "Data tidak valid (3)"
          else
            check_same_value = grocer_items.where("min < ? AND max > ? ", max, max)
            if check_same_value.present?
              return redirect_back_data_error new_grocer_item_path, "Data tidak valid (4)"
            end
          end
        end
      end
    end

    item.price_updated = DateTime.now
    item.save!


    to_users = User.where(level: ["owner", "super_admin", "super_visi"])
      
    Store.all.each do |store|
      Print.create item: item, store: store, grocer_item: grocer_item
    end
    message = "Harga GROSIR - "+item.name
    to_users.each do |to_user|
      set_notification current_user, to_user, "warning", message, prints_path
    end

    return redirect_back_data_error new_grocer_item_path, "Data tidak valid" if grocer_item.invalid?
    grocer_item.save!
    grocer_item.create_activity :create, owner: current_user
    return redirect_success item_path(id: item.id), "Penambahan harga "+item.name+" berhasil disimpan"
  end

  def edit
    return redirect_back_data_error item_cats_path, "Data tidak valid" unless params[:id].present?
    @grocer_item = GrocerItem.find_by_id params[:id]
    return redirect_back_data_error new_item_cat_path, "Data tidak valid" unless @grocer_item.present?
  end

  def update
    return redirect_back_data_error items_path, "Data tidak valid" if params[:id].nil?
    grocer_item = GrocerItem.find_by_id params[:id]
    return redirect_back_data_error new_grocer_item_path, "Data tidak valid" if grocer_item.nil?
    grocer_item.assign_attributes grocer_item_params
    grocer_item.price = params[:grocer_item][:price].gsub(".","").to_i
    item = grocer_item.item
    if grocer_item.min > grocer_item.max 
        return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
    end

    if grocer_item.discount <= 0
      return redirect_back_data_error item_path(id: item.id), "Silahkan Set Diskon Supaya Harga Jual Lebih Besar dari Harga Beli"
    end

    if grocer_item.discount < 100
      grocer_item.discount = grocer_item.price * grocer_item.discount / 100.0
    end

    grocer_item.ppn = grocer_item.price - ((grocer_item.price) / ((item.tax/100.0)+1))
    grocer_item.selisih_pembulatan = grocer_item.price - (((grocer_item.price) / ((item.tax/100.0)+1)) + grocer_item.ppn)
    grocer_item.edited_by = current_user
    grocer_item.save!
    to_users = User.where(level: ["owner", "super_admin", "super_visi"])
    item = grocer_item.item
    Store.all.each do |store|
      Print.create item: item, store: store, grocer_item: grocer_item
    end
    message = "Harga GROSIR - "+item.name
    to_users.each do |to_user|
      set_notification current_user, to_user, "warning", message, prints_path
    end
    return redirect_success item_path(item), "Harga Grosir Telah Disimpan"
  end

  def show
    return redirect_back_data_error item_cats_path, "Data Tidak Ditemukan" unless params[:id].present?
    @grocer_item = GrocerItem.find_by_id params[:id]
    return redirect_back_data_error new_item_cat_path, "Data Tidak Ditemukan" unless @grocer_item.present?
    @item = @grocer_item.item
    respond_to do |format|
      format.html
      format.pdf do
        Print.create item: @item, store: current_user.store, grocer_item: @grocer_item
        return redirect_success item_path(id: @item.id), "Data Barang Telah Ditambahkan di Daftar Cetak"
      end
    end
  end

  def destroy
    return redirect_back_data_error item_cats_path, "Data Tidak Ditemukan" unless params[:id].present?
    @grocer_item = GrocerItem.find_by_id params[:id]
    return redirect_back_data_error new_item_cat_path, "Data Tidak Ditemukan" unless @grocer_item.present?
    item_name = @grocer_item.item.name
    Print.where(grocer_item: @grocer_item).delete_all
    @grocer_item.delete
    return redirect_success item_path(id: @grocer_item.item.id), "Harga Grosir "+item_name+" berhasil dihapus"
  end

  private
    def grocer_item_params
      params.require(:grocer_item).permit(
        :min, :max, :price, :discount
      )
    end

    def param_page
      params[:page]
    end
end
