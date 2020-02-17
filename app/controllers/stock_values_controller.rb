class StockValuesController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
    AccountBalance.balance_account
    filter = filter_search params
    @search = filter[0]
    @finances = filter[1]

    @params = params
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params
        @search = filter[0]
        @finances = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "stock_values/print.html.slim"
      end
    end
  end

  private
    def param_page
      params[:page]
    end
    
    def filter_search params
      results = []
      search_text = "Pencarian "
      filters = StockValue.page param_page
      filters = filters.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
      switch_data_month_param = params[:switch_date_month]
      before_months = 5
      if params[:months].present?
        before_months = params[:months].to_i
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
        else
          search_text += "di Semua Toko "
        end
      end
      
      if params[:order_by] == "asc"
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