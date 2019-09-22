class OperationalsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	filter = filter_search params
    filter = filter.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
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
          template: "operationals/print.html.slim"
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
      filters = CashFlow.where(finance_type: CashFlow::OPERATIONAL).page param_page

      switch_data_month_param = params[:switch_date_month]
      if switch_data_month_param == "month" 
        before_months = params[:months].to_i
        search_text += before_months.to_s + " bulan terakhir "
        start_months = (DateTime.now - before_months.months).beginning_of_month 
        filters = filters.where("date_created >= ?", start_months)
      else
        end_date = DateTime.now.to_date + 1.day
        start_date = DateTime.now.to_date - 1.weeks
        end_date = params[:end_date] if params[:end_date].present?
        start_date = params[:date_from] if params[:date_from].present?
        search_text += "dari " + start_date.to_s + " hingga " + end_date.to_s + " "
        filters = filters.where("date_created >= ? AND date_created <= ?", start_date, end_date)
      end

      store_name ="SEMUA TOKO"

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