class CashFlowsController < ApplicationController
  before_action :require_login
  before_action :screening
  

  def index
  	filter = filter_search params
    @search = filter[0]
  	@finances = filter[1]
    @params = params.to_s
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
          template: "cash_flows/print.html.slim"
      end
    end
  end

  def new
    @users = User.all
  end

  def create
    finance_type = params[:finance][:finance_type]
    nominal = params[:finance][:nominal].to_f.abs
    description = params[:finance][:description]
    date_created = DateTime.now
    user = current_user
    store = Store.find params[:finance][:store_id]
    finance_types = []
    to_user = params[:finance][:to_user]
    due_date = params[:finance][:due_date]
    n_term = params[:finance][:n_term]
    inv_number = Time.now.to_i.to_s
    if finance_type == "Loan" 
      invoice = " EL-"+inv_number
      return redirect_back_data_error new_cash_flow_path, "Banyak cicilan harus diisi." if n_term.nil?
      return redirect_back_data_error new_cash_flow_path, "Tanggal jatuh tempo harus diisi." if due_date.nil?
      return redirect_back_data_error new_cash_flow_path, "Yang berkenaan harus diisi." if to_user.nil?
      return redirect_back_data_error new_cash_flow_path, "Tanggal jatuh tempo harus diisi." if due_date==""
      return redirect_back_data_error new_cash_flow_path, "Tanggal jatuh tempo yang dimasukkan harus lebih dari tanggal hari ini." if due_date.to_date <= Date.today

      nominal_term = nominal.to_f / n_term.to_i

      receivable = Receivable.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                    finance_type: Receivable::EMPLOYEE, deficiency:nominal, to_user: to_user, due_date: due_date, n_term: n_term, nominal_term: nominal_term
      
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::EMPLOYEE_LOAN, invoice: invoice, ref_id: receivable.id
      
      store.cash = store.cash - nominal
      store.receivable = store.receivable + nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user
      receivable.create_activity :create, owner: current_user      
    elsif finance_type == "transfer_to_cash" 
      store.bank = store.bank - nominal
      store.cash = store.cash + nominal

      invoice = "WBANK-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::WITHDRAW_BANK, invoice: invoice
      cash_flow.create_activity :create, owner: current_user  
      store.save!
    elsif finance_type == "transfer_to_bank"
      store.bank = store.bank + nominal
      store.cash = store.cash - nominal
      invoice = "SBANK-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::SEND_BANK, invoice: invoice
      cash_flow.create_activity :create, owner: current_user  
      store.save!
    elsif finance_type == "OtherLoan"
      return redirect_back_data_error new_cash_flow_path, "Tanggal jatuh tempo harus diisi." if due_date.nil?
      return redirect_back_data_error new_cash_flow_path, "Tanggal yang dimasukkan harus lebih dari tanggal hari ini." if due_date.to_date <= Date.today
      invoice = "OL-"+inv_number
      debt = Debt.create user: user, store: store, nominal: nominal, date_created: date_created, description: description,
                    finance_type: Debt::OTHERLOAN, deficiency:nominal, due_date: due_date
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::OTHERLOAN, invoice: invoice, ref_id: debt.id
      
      store.cash = store.cash + nominal
      store.debt = store.debt + nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user       
      debt.create_activity :create, owner: current_user      
    elsif finance_type == "Sent"
      invoice = " TRF-S-"+inv_number
      a = cash_flow = CashFlow.create user: user, store: current_user.store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::SEND, invoice: invoice
      b = cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::RECEIVE, invoice: invoice
      store.cash = store.cash+nominal
      store.equity = store.equity + nominal
      store.save!
      gudang = current_user.store
      gudang.cash = gudang.cash-nominal
      gudang.equity = gudang.equity-nominal
      gudang.save!
    elsif finance_type == "Receive"  
      invoice = " TRF-R-"+inv_number
      a = CashFlow.create user: user, store: current_user.store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::RECEIVE, invoice: invoice
      b = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::SEND, invoice: invoice
      store.cash = store.cash-nominal
      store.equity = store.equity - nominal
      store.save!
      gudang = current_user.store
      gudang.cash = gudang.cash+nominal
      gudang.equity = gudang.equity+nominal
      gudang.save!
    elsif finance_type == "BankLoan"
      return redirect_back_data_error new_cash_flow_path, "Tanggal jatuh tempo harus diisi." if due_date.nil?
      return redirect_back_data_error new_cash_flow_path, "Tanggal yang dimasukkan harus lebih dari tanggal hari ini." if due_date.to_date <= Date.today
      invoice = " BL-"+inv_number
      debt = Debt.create user: user, store: store, nominal: nominal, date_created: date_created, description: description,
                    finance_type: Debt::BANK, deficiency:nominal, due_date: due_date
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::BANK_LOAN, invoice: invoice, ref_id: debt.id
      
      store.cash = store.cash + nominal
      store.debt = store.debt + nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user       
      debt.create_activity :create, owner: current_user           
    elsif finance_type == "Outcome"
      invoice = " OUT-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::OUTCOME, invoice: invoice
      
      store.cash = store.cash - nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user         
    elsif finance_type == "Income"
      invoice = " IN-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::INCOME, invoice: invoice
      
      store.cash = store.cash + nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user   
    elsif finance_type == "Bonus"
      invoice = " BNS-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::BONUS, invoice: invoice
      
      store.cash = store.cash + nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user         
    elsif finance_type == "Asset"
      invoice = " AST-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::ASSET, invoice: invoice
      
      store.cash = store.cash - nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user         
    elsif finance_type == "Operational"
      invoice = " OPR-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::OPERATIONAL, invoice: invoice
      
      store.cash = store.cash - nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user         
    elsif finance_type == "Tax"
      description = "TAX "+Date::MONTHNAMES[Date.today.month]+"/"+Date.today.year.to_s + " ("+description+")"
      invoice = " TAX-"+inv_number
      date_created = Date.today.beginning_of_month
      tax_current_month = CashFlow.find_by("date_created > ? AND date_created < ? AND finance_type = ?", Time.now.beginning_of_month, Time.now.end_of_month, CashFlow::TAX)
      if tax_current_month.present?
        tax_current_month.nominal = nominal
        tax_current_month.date_created = DateTime.now
        tax_current_month.save!
        tax_current_month.create_activity :edit, owner: current_user         
      else
        cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                        finance_type: CashFlow::TAX, invoice: invoice
        cash_flow.create_activity :create, owner: current_user
        
        store.cash = store.cash - nominal
        store.save!         
      end
    elsif finance_type == "Fix_Cost"
      invoice = " FIX-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::FIX_COST, invoice: invoice
      
      store.cash = store.cash - nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user                
    elsif finance_type == "Modal"
      invoice = " MDL-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::MODAL, invoice: invoice
      
      store.cash = store.cash + nominal
      store.equity = store.equity + nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user   
    elsif finance_type == "Withdraw"
      invoice = " WDR-"+inv_number
      cash_flow = CashFlow.create user: user, store: store, nominal: nominal, date_created: date_created, description: description, 
                      finance_type: CashFlow::WITHDRAW, invoice: invoice
      
      store.cash = store.cash - nominal
      store.equity = store.equity - nominal
      store.save!
      cash_flow.create_activity :create, owner: current_user                
    end
    return redirect_success cash_flows_path, "Data Berhasil Disimpan"
  end

  private
    def param_page
      params[:page]
    end

    def filter_search params
      results = []
      search_text = "Pencarian "
      filters = CashFlow.page param_page
      filters = filters.where(store: current_user.store) if  !["owner", "super_admin", "finance"].include? current_user.level

      finance_types = params["finance_type"]
      if finance_types.present?
        finance_types = finance_types.map(&:to_i)
        if finance_types.size > 0
          if !finance_types.include? 0
            filters = filters.where(finance_type: finance_types)
            search_text+= "[" if finance_types.size > 1
            finance_types.each do |f_type|
              type = CashFlow.finance_types.key(f_type)
              if finance_types.last == f_type
                search_text+= type.upcase + "] " if finance_types.size > 1
                search_text+= type.upcase + " " if finance_types.size == 1
              else
                search_text+= type.upcase + ", "
              end
            end
          else
            search_text+= "SEMUA DATA "
          end
        end
      end

      end_date = Date.today + 1.day
      start_date = Date.today - 1.weeks
      end_date = params["end_date"].to_date if params["end_date"].present?
      start_date = params["date_from"].to_date if params["date_from"].present?
      search_text += "dari " + start_date.to_s + " hingga " + end_date.to_s + " "
      filters = filters.where("created_at >= ? AND created_at <= ?", start_date, end_date)
    

      store_id = params["store_id"].to_i
      store_name = "SEMUA TOKO"
      if store_id.present?
        if store_id != 0
          store = Store.find_by(id: store_id)
          if store.present?
            filters = filters.where(store: store)
            search_text+= "pada Toko "+store.name+" "
            store_name = store.name
          else
            search_text += "pada Semua Toko "
          end
        end
      else
        search_text += "pada Semua Toko "
      end

      if params["order_by"] == "asc"
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
end