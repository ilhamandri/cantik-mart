class GrocerItemsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint
  
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
    if min < 2
      return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
    else
      if min > max 
        return redirect_back_data_error new_grocer_item_path, "Data tidak valid"
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
  end

  def show
    return redirect_back_data_error item_cats_path unless params[:id].present?
    @grocer_item = GrocerItem.find_by_id params[:id]
    return redirect_back_data_error new_item_cat_path unless @grocer_item.present?
  end

  def destroy
    return redirect_back_data_error item_cats_path unless params[:id].present?
    @grocer_item = GrocerItem.find_by_id params[:id]
    return redirect_back_data_error new_item_cat_path unless @grocer_item.present?
    @grocer_item.destroy
    return redirect_success item_path(id: @grocer_item.item.id)
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
