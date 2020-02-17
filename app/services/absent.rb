class Absent  

  def self.get_data
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

  def self.calculate_work_hour check_in, check_out
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