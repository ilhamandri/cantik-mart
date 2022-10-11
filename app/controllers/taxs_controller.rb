class TaxsController < ApplicationController
  before_action :require_login
  before_action :screening
  

  def index
  	filter = filter_search params

    taxs = Serve.graph_tax dataFilter
    gon.tax_label = taxs.keys
    gon.tax_data = taxs.values

    @search = filter[0]
    @finances = filter[1]
    @params = params.to_s
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params
        new_params["type"] = "print"
        @search = filter[0]
        @finances = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "taxs/print.html.slim"
      end
    end
  end

  def recap
    start_day = (params[:month] + params[:year]).to_datetime
    end_day = start_day.end_of_month
    @desc = "Rekap pajak bulanan " 
    trx = Transaction.where(has_coin: false, created_at: start_day..end_day)
    @orders = Order.where(created_at: start_day..end_day)
    filename = "./report/taxs/Tax_"
    if params[:store_id]!="0"
      trx = trx.where(store_id: params[:store_id])
      @orders = @orders.where(store_id: params[:store_id])
      @desc += " - " + Store.find_by(id: params[:store_id]).name.upcase
      filename += Store.find_by(id: params[:store_id]).name.upcase 
    end
    @trxs = trx
    @desc += " ( " + start_day.month.to_s + "/" + start_day.year.to_s + " )"
    filename += DateTime.now.to_i.to_s+".xlsx"

    @trx_items = TransactionItem.where(trx: trx)
    @uniq_items = @trx_items.pluck(:item_id).uniq
    @suppliers_id = Supplier.where(id: SupplierItem.where(item_id: @uniq_items).pluck(:supplier_id))
    @suppliers = Supplier.where(id: @suppliers_id)

    if params[:file_type] == "xlsx"
      p = Axlsx::Package.new
      wb = p.workbook
      order_1 = 0
      order_tax_1 = 0
      trx_1 = 0
      trx_tax_1 = 0
      wb.add_worksheet(:name => "Kena PPn") do |sheet|
        sheet.add_row [@desc]
        sheet.add_row [""]
        @suppliers.where("tax > 0 ").each do |supplier|
          sheet.add_row [supplier.name.upcase]
          supplier_items_id = supplier.supplier_items.pluck(:item_id)
          items_id = @uniq_items && supplier_items_id
          trx_totals = 0
          trx_tax_totals = 0
          order_totals = 0
          order_tax_totals = 0
          @trx_items.where(item_id: items_id).each do |trx_item|
            trx_totals += trx_item.quantity * (trx_item.price - trx_item.discount )
            trx_tax_totals = trx_totals - ( (100.0 / (100.0 + supplier.tax) * trx_totals ) )
          end
          order_totals = @orders.where(supplier: supplier).sum(:grand_total)
          order_tax_totals = @orders.where(supplier: supplier).sum(:tax)
          order_1 += order_totals
          order_tax_1 += order_tax_totals
          trx_1 += trx_totals
          trx_tax_1 += trx_tax_totals
          a = sheet.add_row ["Jenis", "Total", "PPn"]
          b = sheet.add_row ["Order", order_totals.to_i, order_tax_totals.to_i]
          c = sheet.add_row ["Penjualan", trx_totals.to_i, trx_tax_totals.to_i]
          d = sheet.add_row ["","",""]
        end
      end

      order_2 = 0
      trx_2 = 0
      wb.add_worksheet(:name => "Tidak Kena PPn") do |sheet|
        sheet.add_row [@desc]
        sheet.add_row [""]
        @suppliers.where("tax = 0 ").each do |supplier|
          sheet.add_row [supplier.name.upcase]
          supplier_items_id = supplier.supplier_items.pluck(:item_id)
          items_id = @uniq_items && supplier_items_id
          trx_totals = 0
          order_totals = 0
          order_tax_totals = 0
          @trx_items.where(item_id: items_id).each do |trx_item|
            trx_totals += trx_item.quantity * (trx_item.price - trx_item.discount )
          end
          order_totals = @orders.where(supplier: supplier).sum(:grand_total)
          order_2 += order_totals
          trx_2 += trx_totals
          a = sheet.add_row ["Jenis", "Total"]
          b = sheet.add_row ["Order", order_totals.to_i]
          c = sheet.add_row ["Penjualan", trx_totals.to_i]
          d = sheet.add_row ["","",""]
        end
      end

      wb.add_worksheet(:name => "Rangkuman") do |sheet|
        sheet.add_row [@desc]
        sheet.add_row [""]
        o = sheet.add_row ["Kena PPn"]
        a = sheet.add_row ["Jenis", "Total", "PPn"]
        b = sheet.add_row ["Order", order_1.to_i, order_tax_1.to_i]
        c = sheet.add_row ["Penjualan", trx_1.to_i, trx_tax_1.to_i]
        d = sheet.add_row ["","",""]

        o = sheet.add_row ["Tidak Kena PPn"]
        a = sheet.add_row ["Jenis", "Total"]
        b = sheet.add_row ["Order", order_2.to_i]
        c = sheet.add_row ["Penjualan", trx_2.to_i]
        d = sheet.add_row ["","",""]
      end

      p.serialize(filename)
      send_file(filename)
    else
      render pdf: DateTime.now.to_i.to_s,
        layout: 'pdf_layout.html.erb',
        template: "taxs/print_recap_monthly.html.slim"
    end
  end

  private
    def param_page
      params[:page]
    end

    def filter_search params
      results = []
      search_text = "Pencarian "
      filters = CashFlow.where(finance_type: CashFlow::TAX)

      filters = filters.page param_page if params["type"].nil? 

      filters = filters.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
      before_months = 5
      if params["months"].present?
        before_months = params["months"].to_i
      end
      
      search_text += before_months.to_s + " bulan terakhir "
      start_months = (DateTime.now - before_months.months).beginning_of_month 
      filters = filters.where("date_created >= ?", start_months)

      store_name = "SEMUA TOKO"

      if params["store_id"].present?
        store = Store.find_by(id: params["store_id"])
        if store.present?
          filters = filters.where(store: store)
          search_text += "di Toko '"+store.name+"' "
          store_name = store.name
        else
          search_text += "di Semua Toko "
        end
      end

      if params["order_by"] == "asc"
        search_text+= "secara menaik"
        filters = filters.order("date_created ASC")
      else
        filters = filters.order("date_created DESC")
        search_text+= "secara menurun"
      end
      results << search_text
      results << filters
      results << store_name
      return results
    end
end