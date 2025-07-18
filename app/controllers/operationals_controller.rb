class OperationalsController < ApplicationController
  before_action :require_login
  before_action :screening
  

  def index
  	filter = filter_search params
    @search = filter[0]
    @finances = filter[1]
    @params = params
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        new_params["type"] = "print"
        filter = filter_search new_params
        @search = filter[0]
        @finances = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout',
          template: "operationals/print", 
          formats: [:html], 
          disposition: :inline
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

      filters = CashFlow.where(finance_type: CashFlow::OPERATIONAL).includes(:user, :store)

      filters = filters.page param_page if params["type"].nil? 

      end_date = Date.today + 1.day
      start_date = Date.today - 1.weeks
      end_date = params["end_date"].to_date if params["end_date"].present?
      start_date = params["date_from"].to_date if params["date_from"].present?

      search_text += "dari " + start_date.to_s + " hingga " + end_date.to_s + " "
      filters = filters.where(date_created: start_date..end_date)
      

      store_name ="SEMUA TOKO"

      if params["store_id"].present?
        if dataFilter.nil?
          store = Store.find_by(id: params["store_id"])
          if store.present?
            filters = filters.where(store: store)
            search_text += "di Toko '"+store.name+"' "
            store_name = store.name
          else
            search_text += "di Semua Toko "
          end
        else
          filter = filter.where(store: current_user.store)
          search_text += "di Toko '"+store.name+"' "
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