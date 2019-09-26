class PromotionsController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	filter = filter_search params
    @search = filter[0]
    @promotions = filter[1]
    @params = params.to_s
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params
        @search = filter[0]
        @promotions = filter[1]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "promotions/print.html.slim"
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
      filters = Promotion.page param_page

      switch_data_month_param = params["switch_date_month"]
      if switch_data_month_param == "month" 
        before_months = params["months"].to_i
        search_text += before_months.to_s + " bulan terakhir "
        start_months = (DateTime.now - before_months.months).beginning_of_month 
        filters = filters.where("date_created >= ?", start_months)
      elsif switch_data_month_param == "date"
        end_date = DateTime.now.to_date + 1.day
        start_date = DateTime.now.to_date - 1.weeks
        end_date = params["end_date"] if params["end_date"].present?
        start_date = params["date_from"] if params["date_from"].present?
        search_text += "dari " + start_date.to_s + " hingga " + end_date.to_s + " "
        filters = filters.where("date_created >= ? AND date_created <= ?", start_date, end_date)
      else
        filters = filters.where("end_promo <= ?", Date.today.end_of_week.end_of_day)
        search_text += "jatuh tempo di minggu ini "
      end

      if params["order_by"] == "asc"
        search_text+= "secara menaik"
        filters = filters.order("date_created ASC")
      else
        filters = filters.order("date_created DESC")
        search_text+= "secara menurun"
      end

      if params["type"].present?
        filters = filters.where(finance_type: Debt.finance_types.key(params["type"].to_i))
        filters = filters.where("deficiency > ?",0)
      end

      results << search_text
      results << filters
      return results
  	end

end