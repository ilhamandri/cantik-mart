class FixCostsController < ApplicationController
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
        filter = filter_search new_params
        @search = filter[0]
        @finances = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout',
          template: "fix_costs/print", 
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
      filters = CashFlow.where(finance_type: CashFlow::FIX_COST).page param_page
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