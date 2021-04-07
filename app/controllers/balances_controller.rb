class BalancesController < ApplicationController
  before_action :require_login
  

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

        switch_data_month_param = params["switch_date_month"]
        if switch_data_month_param == "due_date" 
          end_date = DateTime.now.to_date + 1.day
          start_date = DateTime.now.to_date - 1.weeks
          end_date = params["end_date"] if params["end_date"].present?
          start_date = params["date_from"] if params["date_from"].present?
          search_text += "jatuh tempo dari " + start_date.to_s + " hingga " + end_date.to_s + " "
          filters = filters.where("due_date >= ? AND due_date <= ?", start_date, end_date)
        elsif switch_data_month_param == "date"
          end_date = Date.today + 1.day
          start_date = Date.today - 1.weeks
          end_date = params["end_date"].to_date if params["end_date"].present?
          start_date = params["date_from"].to_date if params["date_from"].present?
          search_text += "dari " + start_date.to_s + " hingga " + end_date.to_s + " "
          filters = filters.where("date_created >= ? AND date_created <= ?", start_date, end_date)
        else
          filters = filters.where("due_date <= ?", Date.today.end_of_week.end_of_day)
          search_text += "jatuh tempo di minggu ini "
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

      date_start = Date.today 
      date_to = Date.today + 1.weeks
  		switch_date_month = params[:balance][:switch_date_month]
  		date_from = params[:balance][:date_from].to_date if params[:balance][:date_from].present?
  		date_to = params[:balance][:date_to].to_date if params[:balance][:date_to].present?
  		order_by = params[:balance][:order_by]
      store_id = params[:balance][:store_id].to_i

			search_text += "dari "+date_start.to_s + " - " + date_to.to_date.to_s
			balances = balances.where("created_at >= ? AND created_at <= ?", date_start.to_datetime, date_to.to_datetime)
  				

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