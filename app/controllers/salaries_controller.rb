class SalariesController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	AccountBalance.salary
    filter = filter_search params
    @search = filter[0]
    @salaries = filter[1]
    @params = params.to_s
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params
        @search = filter[0]
        @finances = filter[1]
        @user_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "salaries/print.html.slim"
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
      filters = UserSalary.page param_page
      filters = filters.where(store: current_user.store) if  !["owner", "super_admin", "super_finance","finance"].include? current_user.level
      before_months = 5
      if params[:months].present?
        before_months = params[:months].to_i
      end
      
      search_text += before_months.to_s + " bulan terakhir "
      start_months = (DateTime.now - before_months.months).beginning_of_month 
      filters = filters.where("created_at >= ?", start_months)

      user_name = "SEMUA KARYAWAN"
      if params["user_id"].present?
        user = User.find_by(id: params["user_id"])
        if user.present?
          filters = filters.where(user: user)
          search_text += "dengan karyawan '"+user.name+"' "
          user_name = user.name
        else
          search_text += "dengan semua karyawan "
        end
      end
      
      if params[:order_by] == "asc"
        search_text+= "secara menaik"
        filters = filters.order("created_at ASC")
      else
        filters = filters.order("created_at DESC")
        search_text+= "secara menurun"
      end
      results << search_text
      results << filters
      results << user_name
      return results
    end
end