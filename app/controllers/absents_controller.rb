class AbsentsController < ApplicationController
  before_action :require_login

  def index
    status = false
    # status = Absent.get_data
    # AccountBalance.salary
    if !status
      @status = "Fingerprint tidak terhubung."
    end
    @search_text = "Pencarian  "
    @absents = Absent.order("created_at DESC").page param_page
    new_params = nil
    if params[:option].present?
      new_params = eval(params[:option])
    end
    
    

    @params = params
    if ["owner", "super_admin", "finance"].include? current_user.level 
      if new_params.present?
        @search_id = new_params["id"] if new_params["id"].present?
        search_params = new_params["search"]
        search_from_date = new_params["date_from_search"]
        search_to_date = new_params["date_to_search"]
      else
        @search_id = params[:id] if params[:id].present?
        search_params = params[:search]
        search_from_date = params[:date_from_search]
        search_to_date = params[:date_to_search]
      end

      if @search_id.present?
        @absents = @absents.where(user_id: @search_id)
      end

      if params[:user_id].present?
        user = User.find_by(id: params[:user_id])
        if user.present?
          @absents = @absents.where(user: params[:user_id])
          @search_text += " '" + user.name + "'"
        end
      end

      if search_from_date.present?
        @search_text+= " dari "+search_from_date.to_s
        @absents = @absents.where("check_in >= ?", search_from_date.to_time)
        binding.pry
        if search_to_date.present?
          if search_to_date != search_from_date
            @search_date = search_to_date.to_date
            @search_text+= " hingga "+@search_date.to_s
            @absents = @absents.where("check_in <= ?", search_to_date.to_time.end_of_day)
          end
        end
      end
    else
      @absents = @absents.where(user: current_user)
    end

    respond_to do |format|
      format.html
      format.xlsx do
        filename = "./report/absent/"+DateTime.now.to_i.to_s+".xlsx"
        p = Axlsx::Package.new
        wb = p.workbook
        users_id = @absents.pluck(:user_id).uniq
        users = User.where(id: users_id)
        users.each do |user|
          wb.add_worksheet(:name => user.name) do |sheet|
            sheet.add_row ["Masuk", "Pulang", "Jam Kerja", " ", "Mulai Lembur", "Selesai Lembur", " Jam Lembur"]
            @absents.where(user: user).order("check_in ASC").each do |data|
              sheet.add_row [data.check_in.to_s, data.check_out.to_s, data.work_hour, "", data.overtime_in.to_s, data.overtime_out.to_s, data.overtime_hour]
            end
          end
        end
        p.serialize(filename)
        send_file(filename)
      end
    end
  end

  

  def show
    return redirect_back_data_error absents_path unless params[:id].present?
    @absents = Absent.find_by_id params[:id]
    return redirect_back_data_error absents_path unless @absents.present?
  end

  private
  	def param_page
      params[:page]
    end
end