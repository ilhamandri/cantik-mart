class StockRecapsController < ApplicationController
  before_action :require_login

  def index
    respond_to do |format|
      format.html
      format.xlsx do
        filename =""
        date = params[:date]
        if date.present?
          stock_recap = StockRecap.find_by(date: date)
          if stock_recap.present?
            filename = stock_recap.filename
          else
            filename = "./public/stocks/"+date.to_s+"_"+DateTime.now.to_i.to_s+".xlsx"
            calculate filename, date
          end
        end
        if filename != ""
          send_file(filename)
        else
          return redirect_back_data_error stock_recaps_path, "Silahkan mengisi tanggal"
        end
      end
    end
  end

  private
    def calculate filename, date
      start_date = date.to_datetime
      end_date = Date.today.to_datetime
      stocks = []
      Item.all.order("name ASC").each do |item|
        if(item.store_items.count != Store.all.count)
          Store.all.each do |store|
            if item.store_items.find_by(store: store).nil?
              StoreItem.create item: item, store: store
            end
          end
        end

        current_stock = item.store_items.sum(:stock)
        
        trx_items = TransactionItem.where(created_at: start_date..end_date, item: item)
        loss_items = LossItem.where(created_at: start_date..end_date, item: item)
        order_items = OrderItem.where(created_at: start_date..end_date, item: item)

        trx_item_total = 0
        loss_item_total = 0
        order_item_total = 0

        if trx_items.present?
          trx_item_total = trx_items.sum(:quantity)
        end
        if loss_items.present?
          loss_item_total = loss_items.sum(:quantity)
        end
        if order_item.present?
          order_item_total = order_items.sum(:quantity)
        end

        stock_before = current_stock + trx_item_total + loss_item_total - order_item_total

        stocks << [item.code, item.name, stock_before]
      end
      create_xlsx filename, stocks, date
    end

    def create_xlsx filename, stocks, date
      p = Axlsx::Package.new
      wb = p.workbook
      wb.add_worksheet(:name => "STOCK ") do |sheet|
        sheet.add_row ["Kode", "Nama", "Stok"]
        sheet.add_row ["","",""]
        stocks.each do |stock|
          sheet.add_row [stock[0], stock[1], stock[2]]
        end
      end
      p.serialize(filename)
      StockRecap.create filename: filename, date: date
    end

end