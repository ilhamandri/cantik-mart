class WarningItemsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
    @inventories = StoreItem.page param_page
    store_id = current_user.store.id
    @inventories = @inventories.where(store_id: store_id).where('stock < min_stock')
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      items = Item.where('lower(name) like ? OR code like ?', search, search).pluck(:id)
      @inventories = @inventories.where(item_id: items)
    end
    @ongoing_orders = Order.where('date_receive is null and date_paid_off is null')
    
    respond_to do |format|
      format.html
      format.xlsx do
        filename = "./report/opname/"+DateTime.now.to_i.to_s+".xlsx"
        p = Axlsx::Package.new
        wb = p.workbook

        wb.add_worksheet(:name => "OPNAME") do |sheet|
          items = StoreItem.where(store: current_user.store).where("stock < 0")
          sheet.add_row ["Kode", "Nama", "STOK SISTEM", "OPNAME"]
          idx = 1
          items.each do |store_item|
            item = store_item.item
            a = sheet.add_row [idx, item.code.to_s+" ", item.name, store_item.stock]
            idx+=1
          end
        end

        p.serialize(filename)
        send_file(filename)
      end
    end
  end

  def opname
  end

  def update_stock
    file = params[:file]
    if File.extname(file.path) == ".xlsx"
      excel = Roo::Excelx.new(file.path)
      excel.each_with_pagename do |name, sheet|
        is_file_ok = check_excel sheet
        return redirect_back_data_error opname_form_path, "File tidak valid" if !is_file_ok
        
        sheet.each do |row|
          next if sheet.first == row
          code = row[1].gsub(" ","")
          item = Item.find_by(code: code)
          next if item.nil?
          store_item = StoreItem.find_by(store: current_user.store, item: item)
          next if store_item.nil?
          last_stock = row[3]
          curr_stock = store_item.stock
          real_stock = row[4]
          new_stock = curr_stock + (last_stock * -1) + real_stock
          store_item.stock = new_stock
          store_item.save!
        end
      end
    else
      return redirect_back_data_error opname_form_path, "File tidak valid" 
    end 
  end

  def check_excel sheet
    sheet.each do |row|
      next if sheet.first == row
      code = row[0].gsub(" ","")
      item = Item.find_by(code: code)
      if item.nil?
        return false
      end
      store_item = StoreItem.find_by(store: current_user.store, item: item)
      if store_item.nil?
        return false
      end
      last_stock = row[3]
      real_stock = row[4]
      if last_stock.nil?
        return false
      end
      if real_stock.nil?
        return false
      end
    end
    return true
  end

  private
    def stock_params
      {
        stock: params[:item][:stock][:stock]
      }
    end

    def param_page
      params[:page]
    end
end
