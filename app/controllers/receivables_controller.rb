class ReceivablesController < ApplicationController
  before_action :require_login
  before_action :require_fingerprint

  def index
  	filter = filter_search params
    @search = filter[0]
    @finances = filter[1]
    @params = params.to_s
    @totals = total
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params
        @search = filter[0]
        @finances = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout.html.erb',
          template: "receivables/print.html.slim"
      end
    end
  end

  def show
    return redirect_back_data_error departments_path, "Data Piutang Tidak Ditemukan" unless params[:id].present?
    @receivable = Receivable.find_by_id params[:id]
    return redirect_back_data_error departments_path, "Data Piutang Tidak Ditemukan" unless @receivable.present?
  end

  def edit
    return redirect_back_data_error departments_path, "Data Piutang Tidak Ditemukan" unless params[:id].present?
    @receivable = Receivable.find_by_id params[:id]
    return redirect_back_data_error departments_path, "Data Piutang Tidak Ditemukan" unless @receivable.present?
    return redirect_back_data_error departments_path, "Data Piutang Tidak Dapat Diubah" unless can_edit
  end

  def can_edit_or_destroy receivable
    pays = CashFlow.where(finance_type: "Income", payment: "receivable", ref_id: @receivable.id)
  end

  def update
    return redirect_back_data_error departments_path, "Data Piutang Tidak Ditemukan" unless params[:id].present?
    @receivable = Receivable.find_by_id params[:id]
    return redirect_back_data_error departments_path, "Data Piutang Tidak Ditemukan" unless @receivable.present?
    return redirect_back_data_error departments_path, "Data Piutang Tidak Dapat Diubah" unless can_edit
    new_nominal = params[:receivable][:nominal].to_i
    old_nominal = @receivable.nominal

    if new_nominal != old_nominal
      diff = new_nominal - old_nominal
      @receivable.nominal = new_nominal
      @receivable.deficiency = @receivable.deficiency + diff
    end
    @receivable.save!
    return redirect_success receivables_path, "PIUTANG - " + @receivable.description + " telah diubah."
  end

  def user_recap
    return redirect_back_data_error absents, "User tidak ditemukan" if params[:id].nil?
    @user = User.find_by(id: params[:id])
    return redirect_back_data_error absents, "User tidak ditemukan" if @user.nil?
    

    @receivables = Receivable.where(user: @user, finance_type: "EMPLOYEE")
    
    # if params[:month].present?
    #   start_date = ("01-" + params[:month].to_s + "-" + params[:year].to_s).to_time.beginning_of_month
    #   end_date = start_date.end_of_month
    #   @receivables = @receivables.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
    # else
    #   start_date = DateTime.current.beginning_of_month
    #   end_date = start_date.end_of_month
    #   @receivables = @receivables.where(user: @user).order("check_in ASC").where("check_in >= ? AND check_in <= ?", start_date, end_date)
    # end

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
    @receivables = Receivable.where(user: @user, finance_type: "EMPLOYEE").page param_page
  end

  private
    def param_page
      params[:page]
    end

    def filter_search params
      results = []
      search_text = "Pencarian "
      filters = Receivable.page param_page
      filters = filters.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level

      switch_data_month_param = params["switch_date_month"]
      if switch_data_month_param == "due_date" 
        end_date = DateTime.now.to_date + 1.day
        start_date = DateTime.now.to_date - 1.weeks
        end_date = params["end_date"].to_date if params["end_date"].present?
        start_date = params["date_from"].to_date if params["date_from"].present?
        search_text += "jatuh tempo dari " + start_date.to_s + " hingga " + end_date.to_s + " "
        filters = filters.where("due_date >= ? AND due_date <= ?", start_date, end_date)
      elsif switch_data_month_param == "date"
        end_date = Date.today + 1.day
        start_date = Date.today - 1.weeks
        end_date = params["end_date"].to_date if params["end_date"].present?
        start_date = params["date_from"].to_date if params["date_from"].present?
        search_text += "dari " + start_date.to_s + " hingga " + end_date.to_s + " "
        filters = filters.where("date_created >= ? AND date_created <= ?", start_date, end_date)
      else
        filters = filters.where("due_date <= ?", Date.today.end_of_week.end_of_day)
        search_text += "jatuh tempo di minggu ini "
      end
      
      store_name = "SEMUA TOKO"

      if params["store_id"].present?
        store = Store.find_by(id: params["store_id"])
        if store.present?
          filters = filters.where(store: store)
          search_text += "di Toko '"+store.name+"' "
          store_name = store.name
        else
          search_text += "di Semua Toko "
        end
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
      results << store_name
      return results
    end

    def total
      totals = Receivable.where("deficiency > ?",0).sum(:deficiency)
      return totals
    end
end