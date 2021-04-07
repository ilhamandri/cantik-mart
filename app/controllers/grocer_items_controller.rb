class GrocerItemsController < ApplicationController
  before_action :require_login
  
  
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
    grocer_item.item = item
    min = grocer_item.min
    max = grocer_item.max
    grocer = GrocerItem.where(item: item)
    
    if grocer_item.price == 0
      grocer_item.price = item.sell
      if grocer_item.price <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Set Harga Jual Lebih Besar dari Harga Beli"
      end
    end
    
    if grocer_item.discount == 0
      if grocer_item.price == item.sell
        return redirect_back_data_error new_grocer_item_path, "Tidak ada data yang disimpan"
      end
      new_price = grocer_item.price - (grocer_item.price * grocer_item.discount / 100) if grocer_item.discount < 100
      new_price = grocer_item.price - (grocer_item.price - grocer_item.discount) if grocer_item.discount > 100
      if new_price <= item.buy
        return redirect_back_data_error item_path(id: item.id), "Silahkan Set Diskon Supaya Harga Jual Lebih Besar dari Harga Beli"
      end
    end



    if min < 2
      return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
    else
      if min > max 
        return redirect_back_data_error new_grocer_item_path, "Data tidak valid. Minimum dan Maximum terbalik."
      else
        check_same_value = grocer.where("max = ? OR max = ? OR min = ? OR min = ?", min, max, min, max)
        if check_same_value.present?
          return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
        else
          check_same_value = grocer.where("min < ? AND max > ? ", min, min)
          if check_same_value.present?
            return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
          else
            check_same_value = grocer.where("min < ? AND max > ? ", max, max)
            if check_same_value.present?
              return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
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
    message = "Terdapat penambahan harga grosir. Segera cetak label harga "+item.name
    to_users.each do |to_user|
      set_notification current_user, to_user, "info", message, prints_path
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
    return redirect_back_data_error items_path, "Data tidak valid" unless params[:id].present?
    grocer_item = GrocerItem.find_by_id params[:id]
    return redirect_back_data_error new_grocer_item_path, "Data tidak valid" unless grocer_item.present?
    grocer_item.assign_attributes grocer_item_params
    
    min = grocer_item.min
    max = grocer_item.max
    grocer = GrocerItem.where(item: grocer_item.item)
    item = grocer_item.item

    if grocer_item.price == 0
      grocer_item.price = item.sell
    end
    if grocer_item.member_price == 0
      grocer_item.member_price = grocer_item.price
    end
    if grocer_item.discount == 0
      if grocer_item.price == item.sell
        return redirect_back_data_error new_grocer_item_path, "Tidak ada data yang disimpan"
      end
    end

    if min < 2
      return redirect_back_data_error new_grocer_item_path
    else
      if min > max 
        return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
      else
        check_same_value = grocer.where("min < ? AND max > ? ", max, max)
        if check_same_value.present?
          return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
        else
          check_same_value = grocer.where("min < ? AND max > ? ", min, min)
          if check_same_value.present?
            return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
          else
            check_same_value = grocer.where("max = ? OR max = ? OR min = ? OR min = ?", min, max, min, max)
            if check_same_value.present?
              return redirect_back_data_error new_grocer_item_path, "Data tidak valid" if grocer_item.invalid?
              grocer_item.save!
              grocer_item.create_activity :create, owner: current_user
              return redirect_success item_path(id: grocer_item.item.id), "Perubahan harga "+grocer_item.item.name+" berhasil disimpan"
            end
          end
        end
      end
    end

    to_users = User.where(level: ["owner", "super_admin", "super_visi"])
      
    Store.all.each do |store|
      Print.create item: item, store: store, grocer_item: grocer_item
    end
    message = "Terdapat perubahan harga grosir. Segera cetak label harga "+item.name
    to_users.each do |to_user|
      set_notification current_user, to_user, "info", message, prints_path
    end

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
        :min, :max, :price, :discount, :member_price
      )
    end

    def param_page
      params[:page]
    end
end
