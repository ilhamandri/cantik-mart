class DownloadsController < ApplicationController
  before_action :require_login

  	def serve_file
  		data_type = params[:type]
  		redirect_home if data_type.nil?

	  	if ["balance"].include? data_type
	  		options = params[:option]
	  		datas = search_data data_type
	  		redirect_home if datas.nil?
	  		if options.nil?
	  			datas = latest_month datas
	  		else
	  			datas = filter_data datas, options
	  		end
	  		datas.order("store_id ASC")
	  		serving_file datas, data_type
	  	else
	  		redirect_home
	  	end
	  	return
  	end

  	def selected_download datas, data_type
  		serving_file datas, data_type
  	end

  	def get_file
	    return redirect_back_data_error balances_path, "File Tidak Ditemukan" if params[:name].nil?
	    filename = "./report/"+params[:name]
	    file_exist = File.exist?(filename)
	    if file_exist
	    	send_file(filename)
	    else
	      return redirect_back_data_error balances_path, "File Tidak Ditemukan" 
	    end
	end

	def prepare_file_balance datas, filename
		p = Axlsx::Package.new
		wb = p.workbook

		temp_datas = datas.order("created_at")
		from_date = temp_datas.first.created_at.beginning_of_day
		to_date = temp_datas.last.created_at.end_of_day

		store = datas.first.store

		## A Simple Workbook
		wb.add_worksheet(:name => "Data Toko") do |sheet|
		  sheet.add_row ["Toko", "Tanggal", "Kas", "Piutang", "Nilai Stok", "Nilai Aset", "", "Modal", "Hutang", "Penjualan", "Pengeluaran"]
		  datas.each do |data|
			sheet.add_row [data.store.name, data.created_at.to_date.to_s, data.cash, data.receivable, data.stock_value, data.asset_value, "", data.equity, data.debt, data.transaction_value, data.outcome]
		  end
		end

		wb.add_worksheet(:name => "Hutang") do |sheet|
			sheet.add_row ["Tanggal", "Deskripsi", "Nominal", "Kekurangan"]

			debts = Debt.where("created_at <= ? AND deficiency > 0", from_date).where(store: store)
			debts.each do |debt|
				sheet.add_row [debt.created_at.to_date.to_s, debt.description, debt.nominal, debt.deficiency]
			end

			debts = Debt.where("created_at >= ? AND created_at <= ?", from_date, to_date).where(store: store)
			debts.each do |debt|
				sheet.add_row [debt.created_at.to_date.to_s, debt.description, debt.nominal, debt.deficiency]
			end
		end

		wb.add_worksheet(:name => "Piutang") do |sheet|
			sheet.add_row ["Tanggal", "Yang bersangkutan","Deskripsi", "Nominal", "Kekurangan"]

			receivables = Receivable.where("created_at <= ? AND deficiency > 0", from_date).where(store: store)
			receivables.each do |receivable|
				target = "-"
				if receivable.finance_type == "EMPLOYEE"
					target = User.find_by(id: receivable.user_id).name
				elsif receivable.finance_type == "RETUR"
					target = Supplier.find_by(id: receivable.user_id).name
				end		
				sheet.add_row [receivable.created_at.to_date.to_s, target,receivable.description, receivable.nominal, receivable.deficiency]
			end

			receivables = Receivable.where("created_at >= ? AND created_at <= ?", from_date, to_date).where(store: store)
			receivables.each do |receivable|
				target = "-"
				if receivable.finance_type == "EMPLOYEE"
					target = User.find_by(id: receivable.user_id).name
				elsif receivable.finance_type == "RETUR"
					target = Supplier.find_by(id: receivable.user_id).name
				end		
				sheet.add_row [receivable.created_at.to_date.to_s, target,receivable.description, receivable.nominal, receivable.deficiency]
			end
		end

		wb.add_worksheet(:name => "Nilai Aset") do |sheet|
			sheet.add_row ["Deskripsi", "Tanggal","Total"]
			assets = Asset.where(store: store)
			assets.each do |asset|
				sheet.add_row [asset.description, asset.created_at.to_date.to_s, asset.nominal]
			end
		end

		wb.add_worksheet(:name => "Nilai Stok") do |sheet|
			sheet.add_row ["Kode", "Nama","Stok", "Harga", "Total"]
			store_stocks = StoreItem.where(store: store).where("stock > 0")
			store_stocks.each do |stocks|
				buy = stocks.item.buy if stocks.buy==0
				buy = stocks.buy if stocks.buy>0
				total = stocks.stock.to_f * buy.to_f
				sheet.add_row [stocks.item.code, stocks.item.name, stocks.stock, buy, total]
			end
		end

		wb.add_worksheet(:name => "Pengeluaran") do |sheet|
			sheet.add_row ["Deskripsi", "Tanggal","Total"]
			cash_flows = CashFlow.where(store: store, finance_type: ["Outcome", "Operational", "Fix_Cost", "Tax"]).where("created_at >= ? AND created_at <= ?", from_date, to_date)
			cash_flows.each do |cash_flow|
				sheet.add_row [cash_flow.description, cash_flow.created_at.to_date.to_s, cash_flow.nominal]
			end
		end

		wb.add_worksheet(:name => "Pemasukan") do |sheet|
			sheet.add_row ["Deskripsi", "Tanggal","Total"]
			cash_flows = CashFlow.where(store: store, finance_type: ["Income"]).where("created_at >= ? AND created_at <= ?", from_date, to_date)
			cash_flows.each do |cash_flow|
				sheet.add_row [cash_flow.description, cash_flow.created_at.to_date.to_s, cash_flow.nominal]
			end
		end

		wb.add_worksheet(:name => "Transaksi") do |sheet|
			sheet.add_row ["Invoice", "Toko", "Dibuat Oleh", "Tanggal", "Pelanggan", "HPP", "Total", "Profit"]
			trxs = Transaction.where(store: store).where("created_at >= ? AND created_at <= ?", from_date, to_date)
			trxs.each do |trx|
				member_name = "-"
				member_name = Member.find_by(card_number: trx.member_card).name if trx.member_card.present?
				sheet.add_row [trx.invoice, trx.store.name, trx.user.name, trx.created_at.to_date, member_name, trx.hpp_total, trx.grand_total, (trx.grand_total-trx.hpp_total)]
			end
		end

		wb.add_worksheet(:name => "Modal") do |sheet|
			sheet.add_row ["Deskripsi", "Tanggal","Total"]
			cash_flows = CashFlow.where(store: store, finance_type: ["Modal"]).where("created_at >= ? AND created_at <= ?", from_date, to_date)
			cash_flows.each do |cash_flow|
				sheet.add_row [cash_flow.description, cash_flow.created_at.to_date.to_s, cash_flow.nominal]
			end
		end

		wb.add_worksheet(:name => "Order") do |sheet|
			sheet.add_row ["Invoice", "Toko", "Dibuat Oleh", "Tanggal", "Supplier", "Jumlah Barang", "Total Tagihan", "Total Dibayarkan", "Kekurangan"]
			orders = Order.where(store: store).where("created_at >= ? AND created_at <= ?", from_date, to_date)
			orders.each do |order|
				invoice = order.invoice
				store_name = order.store.name
				user_name = order.user.name
				supplier_name = order.supplier.name
				created_at = order.created_at
				number_items = order.total_items
				total = order.total

			    dibayarkan = InvoiceTransaction.where(invoice: order.invoice).sum(:nominal) 
			    kekurangan = order.total.to_i - dibayarkan

				sheet.add_row [invoice, store_name, user_name, created_at, supplier_name, number_items, total, dibayarkan, kekurangan]
			end
		end

		wb.add_worksheet(:name => "Retur") do |sheet|
			sheet.add_row ["Invoice", "Toko", "Dibuat Oleh", "Tanggal", "Supplier", "Jumlah Barang"]
			returs = Retur.where(store: store).where("created_at >= ? AND created_at <= ?", from_date, to_date)
			returs.each do |retur|
				invoice = retur.invoice
				store_name = retur.store.name
				user_name = retur.user.name
				created_at = retur.created_at
				supplier_name = retur.supplier.name

				number_items = retur.retur_items.count

				sheet.add_row [invoice, store_name, user_name, created_at, supplier_name, number_items]
			end
		end

		wb.add_worksheet(:name => "Komplain Pelanggan") do |sheet|
			sheet.add_row ["Invoice", "Toko", "Dibuat Oleh", "Tanggal", "Pelanggan", "Jumlah Barang", "Total Tagihan", "Total Dibayarkan", "Kekurangan"]
			complains = Complain.where(store: store).where("created_at >= ? AND created_at <= ?", from_date, to_date)
			complains.each do |complain|
				invoice = complain.invoice
				store_name = complain.store.name
				user_name = complain.user.name
				created_at = complain.created_at

				member_name = "-"
				member_name = Member.find_by(card_number: trx.member_card).name if complain.member_card.present?
				number_items = complain.complain_items.count

				sheet.add_row [invoice, store_name, user_name, created_at, member_name, number_items]
			end
		end

		wb.add_worksheet(:name => "Transfer") do |sheet|
			sheet.add_row ["Invoice", "Toko", "Dibuat Oleh", "Tanggal", "Kepada", "Jumlah Barang"]
			transfers = Transfer.where("from_store_id = ? OR to_store_id = ?", store, store).where("created_at >= ? AND created_at <= ?", from_date, to_date)
			transfers.each do |transfer|
				invoice = transfer.invoice
				from_store_name = transfer.from_store.name
				to_store_name = transfer.to_store.name
				user_name = transfer.user.name
				created_at = transfer.created_at

				number_items = transfer.transfer_items.count

				sheet.add_row [invoice, from_store_name, user_name, created_at, to_store_name, number_items]
			end
		end

		wb.add_worksheet(:name => "Barang Hilang Rusak") do |sheet|
			sheet.add_row ["Kode", "Nama","Jumlah", "Harga", "Total"]
		end

		p.serialize(filename)
	end

	private 
	  	def redirect_home
		  return redirect_back fallback_location: root_path
		end

		def search_data data_type
			data = nil
			if data_type == "balance"
				data = StoreBalance.all
			else
				return data
			end
			return data
		end

		def latest_month datas

			return datas
		end

		def filter_data datas, option

			return datas
		end

		def serving_file datas, data_type
			filename = "./report/"+Time.now.to_i.to_s+"_"+data_type+".xlsx"
			
			if data_type == "balance"
				prepare_file_balance datas, filename
			end

			send_file(filename)
		end	

end