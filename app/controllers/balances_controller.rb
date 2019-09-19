class BalancesController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	@balances = StoreBalance.page param_page
  	filter_search = search @balances
  	@balances = filter_search[0]
  	@search = filter_search[1]
    @params = params[:balance]

    respond_to do |format|
      format.html
      format.zip do
        new_params = eval(params[:option])
        start_date = nil
        end_date = nil
        if new_params.nil?
          end_date = DateTime.now.end_of_day
          start_date = (end_date - 1.month).beginning_of_day
        else
          if new_params["switch_date_month"] == "date"
            start_date = DateTime.now.beginning_of_day
            end_date = DateTime.now.end_of_day
            start_date = new_params["date_from"].to_datetime.beginning_of_day if new_params[:date_from].present?
            end_date = new_params["date_to"].to_datetime.end_of_day if new_params[:date_to].present?
          else
            n_month = new_params["month"].to_i
            end_date = DateTime.now.end_of_day
            start_date = (end_date - n_month.months).beginning_of_day
          end
        end
        filenames = StoreBalance.where("created_at >= ? AND created_at <= ?", start_date, end_date).pluck(:filename)
        if filenames.empty?
          redirect_back_data_error balances_path, "File Tidak Ditemukan"
        else
          folder = ""
          input_filenames = filenames

          zipfile_name = "./report/zip/"+DateTime.now.to_i.to_s+".zip"

          Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
            input_filenames.each do |filename|
              file_exist = File.exist?(filename)
              if file_exist
                zipfile.add(filename, File.join(filename))
              end
            end
            zipfile.get_output_stream("README") { |f| f.write "DATA BALANCE TOKO - (TGL - TGL)" }
          end

          send_file(zipfile_name)
        end
      end
    end
  end

  def show
  	return redirect_back_data_error balances_path, "Data Keuangan Tidak Ditemukan" unless params[:id].present?
    @balance = StoreBalance.find_by(id: params[:id])
    return redirect_back_data_error balances_path, "Data Keuangan Tidak Ditemukan" unless @balance.present?
  end

  def refresh
    AccountBalance.balance_account
  	return redirect_to balances_path
  end

  private
  	def param_page
  		params[:page]
  	end

  	def search balances
  		search_text = "Pencarian data "
  		return [balances, search_text] if params[:balance].nil?

      balances = balances.where(store: current_user.store) if !["owner", "super_admin", "super_finance"].include? current_user.level 

  		switch_date_month = params[:balance][:switch_date_month]
  		date_from = params[:balance][:date_from]
  		date_to = params[:balance][:date_to]
  		month = params[:balance][:month]
  		order_by = params[:balance][:order_by]
      store_id = params[:balance][:store_id].to_i

  		if switch_date_month.present?
  			if switch_date_month == "month"
  				if month.present?
  					search_text += month.to_s + " bulan terakhir"
  					date_from = (DateTime.now - month.to_i.months).beginning_of_day
  					balances = balances.where("created_at >= ?", date_from)
  				end
  			else
  				if date_from.present? && date_to.present?
  					d_date_from = date_from.to_datetime.beginning_of_day
  					d_date_to = date_to.to_datetime.end_of_day
  					search_text += "dari "+d_date_from.to_date.to_s + " - " + d_date_to.to_date.to_s
  					balances = balances.where("created_at >= ? AND created_at <= ?", d_date_from, d_date_to)
  				end
  			end	
  		end

       if store_id.present?
        if store_id != 0
          store = Store.find_by(id: store_id)
          if store.present?
            balances = balances.where(store: store)
            search_text += " pada Toko "+store.name
          end
        else
          search_text += " pada semua Toko"
        end
      end

  		if order_by.present?
  			if order_by == "desc"
  				balances = balances.order("created_at DESC")
  				search_text += " secara menurun"
  			else
  				search_text += " secara menaik"
  			end
  		end

  		return [balances, search_text]
  	end
 end