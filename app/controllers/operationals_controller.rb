class OperationalsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	filter = filter_search
    filter = filter.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
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