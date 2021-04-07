class SupplierItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :require_login
  def index
    return redirect_back_data_error suppliers_path, "Data Barang Suplier Tidak Ditemukan" unless params[:id].present?
    @supplier = Supplier.find_by_id params[:id]
    @order_items = OrderItem.where(order: Order.where(supplier: @supplier).pluck(:id))
    if params[:search].present?
      @search = "Pencarian '" + params[:search].downcase + "'"
      search = "%"+@search+"%"
      items = Item.where('lower(name) like ? OR lower(code) like ?', search, search).pluck(:id)
      @order_items = @order_items.where(item_id: items)
    end
    @order_items = @order_items.select(:item_id, :quantity).page param_page
    @inventories = @order_items.group(:item_id).sum(:quantity)
    @inventories = @inventories.sort_by(&:last).reverse
    

    respond_to do |format|
      format.html
      format.pdf do
        @order_items = OrderItem.where(order: Order.where(supplier: @supplier).pluck(:id)).select(:item_id, :quantity)
        @inventories = @order_items.group(:item_id).sum(:quantity)
        @inventories = @inventories.sort_by(&:last).reverse
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "supplier_items/print.html.slim"
      end
    end
  end

  def item_recaps
    return redirect_back_data_error suppliers_path, "Data Barang Suplier Tidak Ditemukan" unless params[:id].present?
    supplier = Supplier.find_by_id params[:id]

    return redirect_back_data_error suppliers_path, "Data Barang Suplier Tidak Ditemukan" if supplier.nil?
    supplier_items = SupplierItem.where(supplier: supplier).pluck(:item_id)
    start_params = params[:date_start]
    end_params = params[:date_end]
    return redirect_back_data_error item_path(id: item.id), "Silahkan cek tanggal kembali" if start_params.empty? || end_params.empty? 
    date_from = start_params.to_date
    date_to = end_params.to_date
    @trx_items = TransactionItem.where(item: supplier_items, created_at: date_from..date_to).group(:item_id).sum(:quantity)
    @description = "Rekap penjualan " + supplier.name.upcase + " ( " + date_from.to_s + " ... " + date_to.to_s + " )"
    # render pdf: DateTime.now.to_i.to_s,
    #   layout: 'pdf_layout.html.erb',
    #   template: "supplier_items/trxs.html.slim"
    filename = "./report/supplier/" + supplier.name + "-" + DateTime.now.to_i.to_s + ".xlsx"

    p = Axlsx::Package.new
    wb = p.workbook 
    
    wb.add_worksheet(:name => "INFO")do |sheet|
      sheet.add_row ["Dekripsi", @description]
      total = @trx_items.values.inject(0){|sum,x| sum + x }
      sheet.add_row ["Total Barang Terjual", total]
    end
    
    wb.add_worksheet(:name => "PENJUALAN") do |sheet|
      if ['super_admin', 'owner'].include? current_user.level
        sheet.add_row ["Tanggal", "Order", "Terjual", "Omzet"]
      else
        sheet.add_row ["Tanggal", "Order", "Terjual"]
      end
      idx = 0
      total_omzet = 0
      @trx_items.each do |trx_item|
        idx+=1
        item = Item.find trx_item[0]
        item_name = item.name
        terjual = trx_item[1]
        omzet = (trx_item[1]*item.sell).to_i
        total_omzet+=omzet
        omzet_str = number_with_delimiter(omzet, delimiter: ",")
        # if ['super_admin', 'owner'].include? current_user.level
          sheet.add_row [idx,item_name, terjual, omzet_str]
        # else
          # sheet.add_row [idx,item_name, terjual]
        # end
      end
      # if ['super_admin', 'owner'].include? current_user.level

        sheet.add_row ["", "", "", total_omzet]
        sheet.merge_cells sheet.rows.last.cells[(0..3)]
        sheet.add_row ["TOTAL", "", "", number_with_delimiter(total_omzet, delimiter: ",")]
        sheet.merge_cells sheet.rows.last.cells[(0..2)]

      # end
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
