class AbsentsController < ApplicationController
  before_action :require_login

  def index
    status = false
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

    @date = []
    @work_hours = []
    @work_hours_morning = []
    @work_hours_afternoon = []
    @overtime_hours = []
    @work_totals = 0
    @work_morning = 0
    @work_afternoon = 0
    @overtime_totals = 0
    @no_check_out = 0
    @no_check_out_morning = 0
    @no_check_out_afternoon = 0
    @no_check_out_overtime = 0
    @n_absents = 0
    @late_morning = []
    @late_afternoon = []
    @late_general = []
    @performance = 0
    
    if params[:month].present?
      start_date = ("01-" + params[:month].to_s + "-" + params[:year].to_s).to_time.beginning_of_month
      @filter = start_date.strftime("%B %Y")
      end_date = start_date.end_of_month
      @absents = Absent.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
    else
      start_date = DateTime.current.beginning_of_month - 1.months
      end_date = start_date.end_of_month
      @filter = start_date.strftime("%B %Y")
      @absents = Absent.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
    end

    @rawdata = @absents.pluck(:check_in, :work_hour, :overtime_hour, :overtime_in)
    if @rawdata.present?
        day_before = @rawdata.first.first.beginning_of_month - 1.day
        @rawdata.each do |rawdata|
          check_in = rawdata.first
          if (check_in.to_date - day_before.to_date)-1 > 1
            if ['super_visi', 'pramuniaga', 'cashier', 'super_admin'].include? @user.level
              @n_absents += (check_in.to_date - day_before.to_date).to_i - 1
            else
              start_date = day_before.to_date # your start
              end_date = check_in.to_date # your end
              result = (start_date..end_date).to_a.select {|k| k.wday == 0}
              @n_absents += (check_in.to_date - day_before.to_date).to_i - 1 - result.count
            end
          end

          morning_shift = check_in.beginning_of_day + 7.hours
          afternoon_shift = check_in.beginning_of_day + 14.hours
          half_day = check_in.beginning_of_day + 12.hours

          tanggal = rawdata.first.to_date.to_s
          work_hour = rawdata.second.split(":")
          hour = work_hour[0].to_f
          minutes = work_hour[1].to_f
          hour += minutes/60
          @date << tanggal
          @work_hours << hour
          @work_totals += hour

          @no_check_out += 0.0025 if hour == 0 && minutes == 0 

          if check_in < half_day
            if check_in > morning_shift
              @late_morning << check_in - morning_shift  
              @late_general << check_in - morning_shift  
            end
            @work_hours_morning << hour
            @work_morning += hour
            @no_check_out_morning += 0.0025 if hour == 0 && minutes == 0 
          else
            if check_in > afternoon_shift
              @late_afternoon << check_in - afternoon_shift  
              @late_general << check_in - afternoon_shift  
            end
            @work_hours_afternoon << hour
            @work_afternoon += hour
            @no_check_out_afternoon += 0.0025 if hour == 0 && minutes == 0 
          end 

        
          work_hour = rawdata.third.split(":")
          hour = work_hour[0].to_f
          minutes = work_hour[1].to_f
          seconds = work_hour[2].to_f
          minutes += 1 if seconds >= 30
          hour += minutes/60
          @overtime_hours << hour
          @overtime_totals += hour
          if rawdata[3].present?
            @no_check_out_overtime += 0.001 if hour == 0 && minutes == 0
          else
            @overtime_hours << hour
          end
          day_before = check_in

        end

        if (Date.today - day_before.to_date).to_i - 1 > 1
          @n_absents += (Date.today - day_before.to_date).to_i 
        end

        if @work_hours.sum.to_f > 0 && (@work_hours.count - @no_check_out).to_f > 0
          average_work = @work_hours.sum.to_f / (@work_hours.count - @no_check_out).to_f
          average_work_hour = average_work.modulo(24).to_i
          average_work_minute = (average_work.modulo(1) * 60).to_i
          @average_work = average_work_hour.to_s + " jam " + average_work_minute.to_s + " menit"
        else
          @average_work = "-"
        end

        if  @overtime_hours.sum.to_f > 0 && (@overtime_hours.count - @no_check_out).to_f > 0
          average_work = @overtime_hours.sum.to_f / (@overtime_hours.count - @no_check_out).to_f
          average_work_hour = average_work.modulo(24).to_i
          average_work_minute = (average_work.modulo(1) * 60).to_i
          @average_overtime = average_work_hour.to_s + " jam " + average_work_minute.to_s + " menit"
        else
          @average_overtime = "-"
        end

        avg_work_morning = @work_hours_morning.sum.to_f / @work_hours_morning.count.to_f
        if avg_work_morning.nan?
          @average_work_morning = "-" 
        else  
          average_work_morning_hour = avg_work_morning.modulo(24).to_i
          average_work_morning_minute = (avg_work_morning.modulo(1) * 60).round.to_i
          @average_work_morning = average_work_morning_hour.to_s + " jam " + average_work_morning_minute.to_s + " menit"
        end

        avg_work_afternoon = @work_hours_afternoon.sum.to_f / @work_hours_afternoon.count.to_f
        if avg_work_afternoon.nan?
          @average_work_afternoon = "-" 
        else 
          average_work_afternoon_hour = avg_work_afternoon.modulo(24).to_i
          average_work_afternoon_minute = (avg_work_afternoon.modulo(1) * 60).round.to_i
          @average_work_afternoon = average_work_afternoon_hour.to_s + " jam " + average_work_afternoon_minute.to_s + " menit"
        end

        start_date = @rawdata.first.first.beginning_of_month.to_date # your start
        end_date = nil
        if Date.today != @rawdata.first.first.end_of_month
          end_date = Date.today
        else
          end_date = @rawdata.first.first.end_of_month # your end
        end
        days = nil
        if ['super_visi', 'pramuniaga', 'cashier', 'super_admin'].include? @user.level
          days = [1,2,3,4,5,6,7] # day of the week in 0-6. Sunday is day-of-week 0; Saturday is day-of-week 6.
        else
          days = [1,2,3,4,5,6] # day of the week in 0-6. Sunday is day-of-week 0; Saturday is day-of-week 6.
        end
        
        work_days = (start_date..end_date).to_a.select {|k| days.include?(k.wday)}

        @performance = (@date.count.to_f) - (@late_general.count * 0.005) 
        @performance = @performance / work_days.count.to_f
        @performance = (@performance * 10000.0 ).round / 100.0
      end
    gon.work_hour = @work_hours
    gon.label_work_hour = @date
    gon.overtime_hours = @overtime_hours 
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