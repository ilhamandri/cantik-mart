class TaxsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	filter = filter_search
    @search = filter[0]
    @finances = filter[1]
  end

  private
    def param_page
      params[:page]
    end

    def filter_search
      results = []
      search_text = "Pencarian "
      filters = CashFlow.where(finance_type: CashFlow::TAX).page param_page
      filters = filters.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
      switch_data_month_param = params[:switch_date_month]
      before_months = 5
      if params[:months].present?
        before_months = params[:months].to_i
      end
      
      search_text += before_months.to_s + " bulan terakhir "
      start_months = (DateTime.now - before_months.months).beginning_of_month 
      filters = filters.where("date_created >= ?", start_months)

      if params[:order_by] == "asc"
        search_text+= "secara menaik"
        filters = filters.order("date_created ASC")
      else
        filters = filters.order("date_created DESC")
        search_text+= "secara menurun"
      end
      results << search_text
      results << filters
      return results
    end
end