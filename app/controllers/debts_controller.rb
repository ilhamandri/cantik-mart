class DebtsController < ApplicationController
  before_action :require_login
  before_action :screening
  

  def index
    ReCheck.debt
    
    debts = Serve.graph_debt dataFilter
    gon.debt_label = debts.keys
    gon.debt_data = debts.values

  	filter = filter_search params
    @search = filter[0]
    @finances = filter[1]
    @count_debt = filter[3]
    @debt_totals = debt_total
    @params = params.to_s
    @debt = Debt.where("deficiency > ?",0)
    respond_to do |format|
      format.html
      format.pdf do
        new_params = eval(params[:option])
        filter = filter_search new_params
        @search = filter[0]
        @finances = filter[1]
        @store_name= filter[2]
        render pdf: DateTime.now.to_i.to_s,
          layout: 'pdf_layout',
          template: "debts/print", 
          formats: [:html], 
          disposition: :inline
      end
    end

    supplier_id = Debt.all.pluck(:supplier_id).uniq
    @suppliers = Supplier.where(id: supplier_id)
  end

  def show
    ReCheck.debt
    return redirect_back_data_error departments_path, "Data Hutang Tidak Ditemukan" unless params[:id].present?
    @debt = Debt.find_by_id params[:id]
    return redirect_back_data_error departments_path, "Data Hutang Tidak Ditemukan" unless @debt.present?
  end

  def edit
    return redirect_back_data_error departments_path, "Data Hutang Tidak Ditemukan" unless params[:id].present?
    @debt = Debt.find_by_id params[:id]
    return redirect_back_data_error departments_path, "Data Hutang Tidak Ditemukan" unless @debt.present?
  end

  def update
    return redirect_back_data_error departments_path, "Data Hutang Tidak Ditemukan" unless params[:id].present?
    @debt = Debt.find_by_id params[:id]
    return redirect_back_data_error departments_path, "Data Hutang Tidak Ditemukan" unless @debt.present?
    new_nominal = params[:debt][:nominal].to_i
    old_nominal = @debt.nominal

    if new_nominal != old_nominal
      diff = new_nominal - old_nominal
      @debt.nominal = new_nominal
      @debt.deficiency = @debt.deficiency + diff
      if @debt.finance_type == "ORDER"
        order = Order.find_by(id: @debt.ref_id)
        order.grand_total = new_nominal
        order.save!
      end
    end
    @debt.save!
    return redirect_success debts_path, "HUTANG - " + @debt.description + " telah diubah."
  end
  
  private
    def param_page
      params[:page]
    end

    def filter_search params
      results = []
      search_text = "Pencarian "
      filters = Debt.all
      filter = filters.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level
      due_date = params["due_date"]
      
      if params["invoice"].present?
        filters = filters.where(description: "ORD-"+params["invoice"])
        search_text += "invoice 'ORD-" + params["invoice"] + "' "
      end
      
      if params["supplier_id"] != "0"
        supplier = Supplier.find_by(id: params["supplier_id"].to_i)
        if supplier.present?
          filters = filters.where(supplier: supplier)
          search_text += " pada " + supplier.name.upcase + " "
        end
      end

      if params["status"] != "all"
        if params["status"] == "paid"
          filters = filters.where(deficiency: 0)
          search_text += "dengan status LUNAS "
        else
          filters = filters.where("deficiency > 0")
          search_text += "dengan status BELUM LUNAS "
        end
      end

      switch_data_month_param = params["switch_date_month"]
      if params["date_from"].present?
        if switch_data_month_param == "due_date" 
          end_date = DateTime.now.to_date + 1.day
          start_date = DateTime.now.to_date - 1.weeks
          end_date = params["end_date"] if params["end_date"].present?
          start_date = params["date_from"] if params["date_from"].present?
          search_text += "jatuh tempo dari " + start_date.to_s + " hingga " + end_date.to_s + " "
          filters = filters.where("due_date >= ? AND due_date <= ?", start_date, end_date)
        elsif switch_data_month_param == "date"
          end_date = Date.today + 1.day
          start_date = Date.today - 1.weeks
          end_date = params["end_date"].to_date if params["end_date"].present?
          start_date = params["date_from"].to_date if params["date_from"].present?
          search_text += "dari " + start_date.to_s + " hingga " + end_date.to_s + " "
          filters = filters.where("date_created >= ? AND date_created <= ?", start_date, end_date)
        end
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
      count_debt = filters.count
      filters = filters.page param_page
      results << search_text
      results << filters.includes(:user, :store)
      results << store_name
      results << count_debt
      
      return results
    end

    def debt_total
      totals = Debt.where("deficiency > ?",0).sum(:deficiency)
      return totals
    end
end