class SalariesController < ApplicationController
  before_action :require_login
  

  def index
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

  def delete_salary
    return redirect_back_data_error salaries_path, "Data tidak ditemukan" if params["id"].nil?
    user_salary = UserSalary.find_by(id: params[:id])
    return redirect_back_data_error salaries_path, "Data tidak ditemukan" if user_salary.nil?
    
    tag = user_salary.tag
    if tag.present?
      cfs = CashFlow.where(tag: tag)
      incomes = cfs.where(finance_type: "Income")
      outcome = cfs.where(finance_type: "Outcome").first
      incomes.each do |income|
        nominal = income.nominal
        receivable = Receivable.find_by(id: income.ref_id)
        receivable.deficiency = receivable.deficiency + nominal
        receivable.save!
        income.destroy
      end
      store = current_user.store
      nominal_salary = outcome.nominal
      store.cash = store.cash + nominal_salary
      store.save!
      outcome.destroy
    end
    user_salary.destroy!
    return redirect_success salaries_path, "Data berhasil dihapus"
  
  end

  def new
    @users = User.where.not(level: [1,2]).order("name ASC")
  end

  def print_salary
    start_day = DateTime.now.beginning_of_month
    end_day = start_day.end_of_month
    if params[:month].present? && params[:year].present?
      start_day = (params[:month] + params[:year]).to_datetime
      end_day = start_day.end_of_month
    end
    @salaries = UserSalary.where(created_at: start_day..end_day).order("jp ASC, jht ASC")
    
    @salaries = @salaries.drop(1)

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: DateTime.now.to_i.to_s,
          show_as_html: false,
          template: "salaries/print_salary.html.slim"
      end
    end
  end

  def create

    user = User.find_by(id: params[:user_id])
    return redirect_back_data_error new_salary_path, "Karyawan tidak ditemukan" if user.nil?
    pay_kasbon = params[:salary][:pay_kasbon].to_i
    # pay_kasbon = 0
    pay_receivable = params[:salary][:pay_receivable].to_i
    paid = pay_kasbon + pay_receivable
    paid = pay_receivable
    bonus = params[:salary][:bonus].to_i
    receivables = Receivable.where(to_user: user.id).where("deficiency > 0")
    return redirect_back_data_error new_salary_path, user.name + " tidak memiliki hutang. Silahkan cek kembali" if receivables.sum(:deficiency) == 0 && paid > 0
    
    paid_for_deficiency = paid
    tag = "SL-"+DateTime.now.to_i.to_s
    receivables.each do |receivable|
      curr_receivable_deficiency = receivable.deficiency
      break if paid_for_deficiency == 0
      new_val_deficiency = curr_receivable_deficiency - paid_for_deficiency
      pay_nominal = curr_receivable_deficiency
      if new_val_deficiency < 0
        paid_for_deficiency = new_val_deficiency.abs
      else
        pay_nominal = paid_for_deficiency
        paid_for_deficiency = 0
      end
      store = current_user.store
      date_created = DateTime.now
      inv_number = Time.now.to_i.to_s
      desc = "Pembayaran piutang "+user.name+" dengan potong gaji"
      invoice = " IN-"+inv_number+"-1"
      cash_flow = CashFlow.create user: user, store: store, nominal: pay_nominal, date_created: date_created, description: desc, 
                        finance_type: CashFlow::INCOME, invoice: invoice, payment: "receivable", ref_id: receivable.id, tag: tag
      store.cash = store.cash + pay_nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user 
      receivable.deficiency = new_val_deficiency
      receivable.save!
    end 

    if pay_kasbon != 0
      kasbon = Kasbon.find_by(user: user)
      if kasbon.present?
        kasbon.nominal = kasbon.nominal - pay_kasbon
        kasbon.nominal = 0 if kasbon.nominal < 0
        kasbon.save!
      else
        pay_kasbon = 0
      end
    end

    jp = 0
    jht = 0 
    jp = 0.01 * user.salary.to_f if params[:jp].present?
    jht = 0.02 * user.salary.to_f if params[:jht].present?

    store = user.store
    date_created = DateTime.now
    inv_number = Time.now.to_i.to_s
    desc = "Gaji " + user.name + "(" + Date.today.month.to_s + "/" + Date.today.year.to_s + ")"
    invoice = "SLRY-"+inv_number+"-"+user.id.to_s
    cash_flow = CashFlow.create user: user, store: store, nominal: user.salary + bonus - pay_receivable - pay_kasbon, date_created: date_created, description: desc, 
                finance_type: CashFlow::OUTCOME, invoice: invoice, tag: tag
    user_salary = UserSalary.create user: user, nominal: user.salary, pay_kasbon: pay_kasbon, pay_receivable: pay_receivable, bonus: bonus, tag: tag, jp: jp, jht: jht
    user_salary.create_activity :create, owner: current_user 
    store.cash = store.cash - user.salary - bonus + pay_receivable + pay_kasbon
    store.save!
    cash_flow.create_activity :create, owner: current_user 
    return redirect_success new_salary_path, desc + " berhasil disimpan"
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