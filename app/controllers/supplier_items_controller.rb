class SupplierItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :require_login
  before_action :screening
  

  def item_recaps
    return redirect_back_data_error suppliers_path, "Data Barang Suplier Tidak Ditemukan" unless params[:id].present?
    supplier = Supplier.find_by_id params[:id]
    return redirect_back_data_error suppliers_path, "Suplier Tidak Ditemukan" if supplier.nil?
    start_params = params[:date_start]
    end_params = params[:date_end]
    return redirect_back_data_error item_path(id: item.id), "Silahkan cek tanggal kembali" if start_params.empty? || end_params.empty? 
    date_from = start_params.to_datetime.beginning_of_day
    date_to = end_params.to_datetime.end_of_day
    trx_items = TransactionItem.where(supplier: supplier, created_at: date_from..date_to)
    trx_items = trx_items.where(store: current_user.store) if ["super_visi"].include? current_user.level

    filename = "./report/supplier/" + supplier.name + "-" + DateTime.now.to_i.to_s + ".xlsx"

    p = Axlsx::Package.new
    wb = p.workbook 
    
    wb.add_worksheet(:name => "INFO")do |sheet|
      sheet.add_row ["Dekripsi", "Rekap penjualan " + supplier.name.upcase + " ( " + date_from.to_date.to_s + " ... " + date_to.to_date.to_s + " )"]
      sheet.add_row ["Total Barang Terjual", trx_items.sum(:quantity)]
    end

    total_omzet = 0
    total_tax = 0
    total_profit = 0
    total_terjual = 0
    
    wb.add_worksheet(:name => "PENJUALAN") do |sheet|
      if ["super_visi", "stock_admin"].include? current_user.level
        sheet.add_row ["No", "Kode", "Nama Barang", "Terjual", "Omzet"]
      else
        sheet.add_row ["No", "Kode", "Nama Barang", "Terjual", "Omzet", "Pajak", "Profit"]
      end
      Item.where(id: trx_items.pluck(:item_id).uniq).each_with_index do |item,idx|
        trx_item = trx_items.where(item: item)
        terjual = trx_item.sum(:quantity)
        total_terjual += terjual
        omzet = trx_item.sum(:total)
        total_omzet+=omzet
        tax = trx_item.sum(:ppn).ceil(3)
        total_tax += tax
        profit = trx_item.sum(:profit).ceil(3)
        total_profit += profit
        if ["super_visi", "stock_admin"].include? current_user.level
          sheet.add_row [idx+1, item.code, item.name, terjual, omzet]
        else
          sheet.add_row [idx+1, item.code, item.name, terjual, omzet, tax, profit]
        end
      end

      sheet.add_row []

      if ["super_visi", "stock_admin"].include? current_user.level
        sheet.add_row ["TOTAL", "", "", total_terjual, total_omzet]
      else
        sheet.add_row ["TOTAL", "", "", total_terjual, total_omzet, total_tax, total_profit]
      end
      sheet.merge_cells sheet.rows.last.cells[(0..2)]

    end

    sheet = p.workbook.worksheets.select {|w| w.name == "INFO"}.first
    sheet.add_row ["Total omzet", total_omzet]
    if ["super_admin", "finance", "owner"].include? current_user.level
      sheet.add_row ["Total omzet", total_omzet]
      sheet.add_row ["Total pajak", total_tax]
      sheet.add_row ["Total profit", total_profit]
    end

    p.serialize(filename)
    send_file(filename)
  end

  private
    def supplier_item_params
      params.require(:supplier_item).permit(
        :item_id
      )
    end

    def param_page
      params[:page]
    end
end
