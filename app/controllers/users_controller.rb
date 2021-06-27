class UsersController < ApplicationController
  before_action :require_login
  
  def index
    
    # Grant.insert_access_grant
    # Grant.insert_user
    # InsertProdlist.cross_check "3-prodlist.xlsx"

    # InsertProdlist.cross_check "1-prodlist.xlsx"
    # InsertProdlist.cross_check "2-prodlist.xlsx"
    # InsertProdlist.additional_file "3-additional.xlsx"

    @users = User.page param_page
    if params[:search].present?
      @search = params[:search].downcase
      search = "%"+@search+"%"
      @users = @users.where("lower(name) like ? OR phone like ?", search, search)
    end

    respond_to do |format|
      format.html
      format.pdf do
        @users = User.all
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "users/print.html.slim"
      end
    end
  end

  

  def show
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless params[:id].present?
    @user = User.find_by_id params[:id]
    if !["owner", "super_admin", "finance"].include? current_user.level
      if @user != current_user
        return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless @user.present?
      end
    end
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless @user.present?

    @salaries = UserSalary.where(user: @user).order("created_at DESC").limit(12)
    # @date = []
    # @work_hours = []
    # @work_hours_morning = []
    # @work_hours_afternoon = []
    # @overtime_hours = []
    # @work_totals = 0
    # @work_morning = 0
    # @work_afternoon = 0
    # @overtime_totals = 0
    # @no_check_out = 0
    # @no_check_out_morning = 0
    # @no_check_out_afternoon = 0
    # @no_check_out_overtime = 0
    # @n_absents = 0
    # @late_morning = []
    # @late_afternoon = []
    # @late_general = []
    # @performance = 0
    
    # absent @user

    @receivables = Receivable.where(to_user: @user, finance_type: "EMPLOYEE").order("created_at DESC").page param_page
    
    # # if params[:month].present?
    # #   start_date = ("01-" + params[:month].to_s + "-" + params[:year].to_s).to_time.beginning_of_month
    # #   end_date = start_date.end_of_month
    # #   @receivables = @receivables.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
    # # else
    # #   start_date = DateTime.current.beginning_of_month
    # #   end_date = start_date.end_of_month
    # #   @receivables = @receivables.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
    # # end

    # @receivable_not_paid = @receivables.where("created_at <= ?", DateTime.now - 6.months)
    # @receivable_now = @receivables.where("created_at >= ?", DateTime.now - 6.months)

    # pinjaman_belum_lunas = @receivables.sum(:deficiency)
    # @limit_pinjaman = 5000000 - pinjaman_belum_lunas
    # @total_pinjaman = pinjaman_belum_lunas
    # @avg_pinjaman = @receivables.average(:nominal).to_i

    # n_pays = CashFlow.where(finance_type: "Income", payment: "receivable", ref_id: @receivables.pluck(:id)).count
    # total_n_term = @receivables.sum(:n_term)
    # @avg_pay_complete_pinjaman = total_n_term.to_f / n_pays.to_f
    # @avg_pay_complete_pinjaman = 1 if @avg_pay_complete_pinjaman.nan?
    # @receivables = Receivable.where(user: @user, finance_type: "EMPLOYEE").page param_page

    # gon.work_hour = @work_hours
    # gon.label_work_hour = @date
    # gon.overtime_hours = @overtime_hours 
  end

  def new
    @stores = Store.all
  end

  def create
    user = User.new user_params
    return redirect_back_data_error new_user_path, "Data Pengguna Tidak Ditemukan" if user.invalid?
    user.fingerprint = 0
    user.save!
    user.fingerprint = user.id
    user.save!
    user.create_activity :create, owner: current_user
    return redirect_success users_path, "Pengguna - " + user.name + " - Berhasil Ditambahkan"
  end

  def edit
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless params[:id].present?
    @user = User.find_by_id params[:id]
    if !["owner", "super_admin", "finance"].include? current_user.level
      if @user != current_user
        return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless @user.present?
      end
    end
    @stores = Store.all
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless @user.present?
  end

  def update
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless params[:id].present?
    user = User.find_by_id params[:id]
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless user.present?
    file = params[:user][:image]
    upload_io = params[:user][:image]
    if file.present?
      filename = Digest::SHA1.hexdigest([Time.now, rand].join).to_s+File.extname(file.path).to_s
      File.open(Rails.root.join('public', 'uploads', 'profile_picture', filename), 'wb') do |file|
        file.write(upload_io.read)
      end
      user.image = filename
    end

    param = user_params
    if user != current_user
      param = user_params.delete("password")
    end

    user.assign_attributes user_params
    changes = user.changes
    user.save! if user.changed?
    user.create_activity :edit, owner: current_user, parameters: changes
    return redirect_success user_path(id: user.id), "Data Pengguna - " + user.name + " - Berhasil Diubah"
  end

  def destroy
    return redirect_back_data_error users_path, "Data Tidak Valid" unless params[:id].present?
    user = User.find params[:id]
    return redirect_back_data_error users_path, "Data Tidak Valid" unless user.present?
    if user.level == "owner" || user.level == "super_admin"
      return redirect_back_data_error users_path, "Data Tidak Valid" 
    else 
      user.destroy
      return redirect_success users_path, "Data Pengguna - " + user.name + " - Berhasil Dihapus"
    end
  end

  def recap
    return redirect_back_data_error users_path, "Data Pengguna Tidak Ditemukan" unless params[:id].present?
    @user = User.find_by_id params[:id]
    @kasbon = 0
    @piutang = 0

  end

  private
    def user_params
      params.require(:user).permit(
        :name, :email, :password, :level, :phone, :sex, :store_id, :id_card, :address, :fingerprint, :salary
      )
    end

    def param_page
      params[:page]
    end

    def receivable user
      @receivables = Receivable.where(user: @user, finance_type: "EMPLOYEE")
      @receivable_not_paid = @receivables.where("created_at <= ?", DateTime.now - 6.months)
      @receivable_now = @receivables.where("created_at >= ?", DateTime.now - 6.months)

      pinjaman_belum_lunas = @receivables.sum(:deficiency)
      @limit_pinjaman = 5000000 - pinjaman_belum_lunas
      @total_pinjaman = pinjaman_belum_lunas
      @avg_pinjaman = @receivables.average(:nominal).to_i

      n_pays = CashFlow.where(finance_type: "Income", payment: "receivable", ref_id: @receivables.pluck(:id)).count
      total_n_term = @receivables.sum(:n_term)
      @avg_pay_complete_pinjaman = total_n_term.to_f / n_pays.to_f
      @avg_pay_complete_pinjaman = 1 if @avg_pay_complete_pinjaman.nan?
    end

    def absent user
      @user = user

      if params[:month].present?
        start_date = ("01-" + params[:month].to_s + "-" + params[:year].to_s).to_time.beginning_of_month
        @filter = start_date.strftime("%B %Y")
        end_date = start_date.end_of_month
        @absents = Absent.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
      else
        start_date = DateTime.current.beginning_of_month - 6.months
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
    end
end
