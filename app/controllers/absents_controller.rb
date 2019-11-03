class AbsentsController < ApplicationController
  before_action :require_login

  def index
    status = false
    status = get_data
    AccountBalance.salary
    if !status
      @status = "Fingerprint tidak terhubung."
    end
    @search_text = "Pencarian  "
    @absents = Absent.page param_page
    if params[:option].present?
      new_params = eval(params[:option])
    end
    params = new_params
    @params = params
    if ["owner", "super_admin", "finance"].include? current_user.level 
      if params[:id].present?
        @search_id = params[:id]
        @absents = @absents.where(user_id: params[:id])
      end

      if params[:search].present?
        search = "%"+params[:search]+"%".downcase
        @search_text+= " '"+params[:search]+"' "
        users = User.where("lower(name) like ?", search).pluck(:id)
        @absents = @absents.where(user_id: users)
      end

      if params[:date_from_search].present?
        @search_date = params[:date_from_search].to_date
        @search_text+= "dari "+@search_date.to_s
        @absents = @absents.where("DATE(check_in) >= ?", @search_date)
        if params[:date_to_search].present?
          if params[:date_to_search] != params[:date_from_search]
            @search_date = params[:date_to_search].to_date
            @search_text+= " hingga "+@search_date.to_s
            @absents = @absents.where("DATE(check_in) <= ?", @search_date)
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
          wb.add_worksheet(:name => user.name+" - "+user.store.name) do |sheet|
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

  def get_data
    url = URI.parse('http://localhost/getData.php')
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }

    return false if res.code == "404"
    
    return false if res.body.include? "Gagal"

    datas = JSON.parse(res.body)
    datas.each_with_index do |data, index|
      next if data==datas.first || data==datas.last
      fingerprint_id = data["pin"]
      user = User.find_by(fingerprint: fingerprint_id)
      next if user.nil?
      check_type = data["status"]
      date_time = data["waktu"]
      next if date_time.to_date != DateTime.now.to_date
      absent = Absent.find_by("DATE(check_in) = ? AND user_id = ?", DateTime.now.to_date, user.id)
      absent = Absent.create user: user, check_in: date_time if absent.nil? && check_type == "0"
      next if absent.nil?
      if check_type == "0"
        next if absent.check_in.present?
        absent.check_in = date_time
        work_hours = calculate_work_hour absent.check_in, absent.check_out
        absent.work_hour = work_hours
      elsif check_type == "1"
        next if absent.check_out.present? || absent.check_in.nil?
        absent.check_out = date_time
        work_hours = calculate_work_hour absent.check_in, absent.check_out
        absent.work_hour = work_hours
      elsif check_type == "4"
        next if absent.overtime_in.present? || absent.check_out.nil?
        absent.overtime_in = date_time
        work_hours = calculate_work_hour absent.overtime_in, absent.overtime_out
        absent.overtime_hour = work_hours
      elsif check_type == "5"
        next if absent.overtime_out.present? || absent.overtime_in.nil?
        absent.overtime_out = date_time
        work_hours = calculate_work_hour absent.overtime_in, absent.overtime_out
        absent.overtime_hour = work_hours
      end
      absent.save!
    end
    return true
  end

  def calculate_work_hour check_in, check_out
    return nil if check_out.nil?
    divide_hour = check_out.to_time - check_in.to_time
    raw_hour = divide_hour / 1.hour
    hour = raw_hour.to_i.to_s
    divide_min = raw_hour - raw_hour.to_i
    raw_min = divide_min*60
    minute = raw_min.to_i.to_s
    sec = ((raw_min - raw_min.to_i)*60).to_i.to_s
    return hour+":"+minute+":"+sec
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