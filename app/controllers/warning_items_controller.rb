class WarningItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :require_login
  before_action :screening
  

  def index
    @inventories = StoreItem.includes(:item, :item => :item_cat).page param_page
    store_id = current_user.store.id
    @inventories = @inventories.where(store_id: store_id).where('stock < ideal_stock')
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      items = Item.where('lower(name) like ? OR code like ?', search, search).pluck(:id)
      @inventories = @inventories.where(item_id: items)
    end
    
    # @ongoing_orders = Order.where('date_receive is null and date_paid_off is null').includes(:order_item, :order_item => :item)
    # @ongoing_orders = Order.where(date_receive: nil, date_paid_off: nil)

    respond_to do |format|
      format.html
      format.xlsx do
        filename = "./report/opname/"+DateTime.now.to_i.to_s+".xlsx"
        p = Axlsx::Package.new
        wb = p.workbook

        wb.add_worksheet(:name => "OPNAME") do |sheet|
          items = StoreItem.where(store: current_user.store).where("stock < 0")
          sheet.add_row ["No", "Kode", "Nama", "STOK SISTEM", "OPNAME"]
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

  def opname_day
    so_type = params[:so_type]
    filename = nil
    
    items = nil
    department = Department.find_by(id: params[:opname][:department_id])
    supplier = Supplier.find_by(id: params[:opname][:supplier_id])

    if so_type == "department"  
      item_cats = department.item_cat
      items = Item.where(item_cat: item_cats)
      filename = "./report/opname/" + so_type + "_" + department.name + "_" + current_user.store.id.to_s + "_" +DateTime.now.to_i.to_s+".xlsx"
    else
      item_ids = supplier.supplier_items.pluck(:item_id)
      items = Item.where(id: item_ids)
      filename = "./report/opname/" + so_type + "_" + supplier.name + "_" + current_user.store.id.to_s + "_" +DateTime.now.to_i.to_s+".xlsx"
    end

    store_items = StoreItem.where(store: current_user.store, item: items)
    filename = "./report/opname/" + "SO-" + DateTime.now.to_i.to_s + ".xlsx"
    

    p = Axlsx::Package.new
    wb = p.workbook 

    wb.add_worksheet(:name => "OPNAME") do |sheet|
      sheet.add_row ["No", "Kode", "Nama", "Beli", "Jual", "STOK SISTEM", "OPNAME"]
      idx = 1
      store_items.each do |store_item|
        item = store_item.item
        b = item.buy.to_i
        s = item.sell.to_i
        a = sheet.add_row [idx, item.code.to_s+" ", item.name, b, s, store_item.stock]
        idx+=1
      end
    end

    p.serialize(filename)
    send_file(filename)
  end

  def update_stock
    file = params[:file]
    not_read = []
    return redirect_back_data_error opname_form_path, "File tidak valid" if file.nil?
    if File.extname(file.path) == ".xlsx"
      excel = Roo::Excelx.new(file.path)
      excel.each_with_pagename do |name, sheet|
        is_file_ok = check_excel sheet
        # return redirect_back_data_error opname_form_path, "File tidak valid" if !is_file_ok
        
        sheet.each do |row|
          next if sheet.first == row
          next if row[1].nil?
          code = row[1].to_s
          code = code.gsub(" ","")
          code = code.gsub("'","")
          code = code.gsub(".0","")
          item = Item.find_by(code: code)
          if item.nil?
            not_read << code
            next
          end
          store_item = StoreItem.find_by(store: current_user.store, item: item)
          next if store_item.nil?
          last_stock = row[5]
          curr_stock = store_item.stock
          real_stock = row[6]
          next if real_stock.nil? 
          new_stock = curr_stock + (last_stock * -1) + real_stock
          # new_stock = real_stock
          if curr_stock < 0
            new_stock = real_stock
          elsif new_stock < 0
            new_stock = 0
          end
          store_item.stock = new_stock
          store_item.save!
        end
      end
    else
      return redirect_back_data_error opname_form_path, "File tidak valid" 
    end 
    upload_io = params[:file]
    filename = Digest::SHA1.hexdigest([Time.now, rand].join).to_s+File.extname(file.path).to_s
    File.open(Rails.root.join('public', 'uploads', 'stock_opnames', filename), 'wb') do |file|
      file.write(upload_io.read)
    end
    Opname.create user: current_user, store: current_user.store, file_name: filename
    return redirect_success opnames_path, "Item telah selesai diopname."
  end

  def check_excel sheet
    sheet.each do |row|
      next if sheet.first == row
      code = row[1]
      # code = row[1].gsub(" ","")
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
        # return false
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
