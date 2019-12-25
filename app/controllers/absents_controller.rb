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
              sheet.add_row [data.check_in.to_s, data.check_out.to_s, data.work_hour, "", data.overtime_in.to_s, data.overtime_out.to_s, data.overtime_hours]
            end
          end
        end
        p.serialize(filename)
        send_file(filename)
      end
    end
  end

  def user_recap
    return redirect_back_data_error absents, "User tidak ditemukan" if params[:id].nil?
    @user = User.find_by(id: params[:id])
    return redirect_back_data_error absents, "User tidak ditemukan" if @user.nil?
    
    if params[:month].present?
      start_date = ("01-" + params[:month].to_s + "-" + params[:year].to_s).to_time.beginning_of_month
      @filter = start_date.strftime("%B %Y")
      end_date = start_date.end_of_month
      @absents = Absent.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
    else
      start_date = DateTime.current.beginning_of_month
      end_date = start_date.end_of_month
      @filter = start_date.strftime("%B %Y")
      @absents = Absent.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
    end

    @rawdata = @absents.pluck(:check_in, :work_hour, :overtime_hour, :overtime_in)
    date = []
    work_hours = []
    overtime_hours = []
    @work_totals = 0
    @overtime_totals = 0
    @no_check_out = 0
    @no_check_out_overtime = 0

    @rawdata.each do |rawdata|
      tanggal = rawdata.first.to_date.to_s
      work_hour = rawdata.second.split(":")
      hour = work_hour[0].to_f
      minutes = work_hour[1].to_f
      hour += minutes/60
      date << tanggal
      work_hours << hour
      @work_totals += hour
      @no_check_out += 1 if hour == 0

      
      work_hour = rawdata.third.split(":")
      hour = work_hour[0].to_f
      minutes = work_hour[1].to_f
      hour += minutes/60
      overtime_hours << hour
      @overtime_totals += hour
      if rawdata[3].present?
        @no_check_out_overtime += 1 if hour == 0
      else
        overtime_hours << hour
      end
    end

    if  work_hours.sum.to_f > 0 && (work_hours.count - @no_check_out).to_f > 0
      average_work = work_hours.sum.to_f / (work_hours.count - @no_check_out).to_f
      average_work_hour = average_work.modulo(24).to_i
      average_work_minute = (average_work.modulo(1) * 60).to_i
      @average_work = average_work_hour.to_s + " jam " + average_work_minute.to_s + " menit"
    else
      @average_work = "-"
    end

    if  overtime_hours.sum.to_f > 0 && (overtime_hours.count - @no_check_out).to_f > 0
      average_work = overtime_hours.sum.to_f / (overtime_hours.count - @no_check_out).to_f
      average_work_hour = average_work.modulo(24).to_i
      average_work_minute = (average_work.modulo(1) * 60).to_i
      @average_overtime = average_work_hour.to_s + " jam " + average_work_minute.to_s + " menit"
    else
      @average_overtime = "-"
    end

    gon.work_hour = work_hours
    gon.label_work_hour = date
    gon.overtime_hours = overtime_hours 
  end

  def daily_recap
    start_day = params[:date].to_time
    end_day = start_day.end_of_day
    @absents = Absent.where("created_at >= ? AND created_at <= ?", start_day, end_day)
    @absents = @absents.order("created_at DESC")
    @start_day = start_day
    @kriteria = "Rekap Absensi Harian - "+Date.today.to_s
    render pdf: DateTime.now.to_i.to_s,
      layout: 'pdf_layout.html.erb',
      template: "absents/print_recap.html.slim"
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