class AccountBalance
  
  @@store_id = 1
  @@salary_date = "25"

  def initialize
  end

  def self.balance_account
    stores = Store.all
    time_start = DateTime.now.beginning_of_month.beginning_of_day
    time_end = DateTime.now.end_of_day
    stores.each do |store|
      # kas
      kas = store.cash.to_f - store.grand_total_before.to_f
      # piutang
      piutang_sebelumnya = Receivable.where("created_at < ? AND deficiency > 0", time_start).where(store: store).sum(:deficiency).to_f
      piutang =  piutang_sebelumnya + Receivable.where("created_at >= ? AND created_at <= ? AND deficiency > 0", time_start, time_end).where(store: store).sum(:deficiency).to_f
      # stock_value
      nilai_stok = stock_values(store).to_f
      # assets
      nilai_aset = assets(store, time_start, time_end).to_f


      # trx
      transaksi_arr = transaksi(store, time_start, time_end)
      profit = transaksi_arr[0]
      penjualan = transaksi_arr[1]

      kas += penjualan

      # binding.pry if store.id == 1
      
      # outcome
      pengeluaran = outcomes(store, time_start, time_end).to_f
      #income
      pemasukan = incomes(store, time_start, time_end).to_f
      # loss_item
      loss = loss_item(store, time_start, time_end).to_f
      # (profit - loss)
      income_outcome = pemasukan - pengeluaran - loss
      # modal
      modals = store.equity.to_f
      # debt
      hutang_sebelumnya = Debt.where("created_at < ? AND deficiency > 0", time_start).where(store: store).sum(:deficiency).to_f
      hutang = hutang_sebelumnya + Debt.where("created_at >= ? AND created_at <= ? AND deficiency > 0", time_start, time_end).where(store: store).sum(:deficiency).to_f

      aktiva = kas + piutang + nilai_stok + nilai_aset
      passiva = profit + income_outcome + modals + hutang

      # Loss Item

     # kas baru diisi dari kas bulan lama
     # modal sama dengan bulan sebelumnya 

      store.debt = hutang
      store.receivable = piutang
      store.save!

      curr_day_start = DateTime.now.beginning_of_day
      curr_day_end = DateTime.now.end_of_day

      balance = nil
      balances = StoreBalance.where(store: store).where("created_at >= ? AND created_at <= ?",curr_day_start, curr_day_end)
      filenames = balances.pluck(:filename)
      balances.delete_all
      balance = StoreBalance.create store: store, cash: kas, receivable: piutang, stock_value: nilai_stok,
          asset_value: nilai_aset, transaction_value: profit, equity: modals, debt: hutang, outcome: income_outcome
      
      store.cash = kas
      store.grand_total_before = penjualan
      
      store.save!

      if filenames.present?
        filenames.each do |filename|
          next if filename.nil?
          File.delete(filename) if File.exist?(filename)
        end
      end

      balances = StoreBalance.where(store: store).where("created_at >= ? AND created_at <= ?",curr_day_start, curr_day_end)
      
      file_name = "./report/"+DateTime.now.to_i.to_s+"_balance_"+store.id.to_s+".xlsx"
      download_cont = DownloadsController.new
      download_cont.prepare_file_balance balances, file_name
      balance.filename = file_name
      balance.save! 
    end
  end

  def self.stock_values store
    stocks = StoreItem.where(store: store).where('stock != 0')
    values = 0
    stocks.each do |store_stock|
      values += store_stock.stock * store_stock.item.buy if !store_stock.item.local_item
      values += store_stock.buy * store_stock.stock if store_stock.item.local_item
    end
    time_start = DateTime.now.beginning_of_day
    time_end = DateTime.now.end_of_day
    stock_value = StockValue.where(store: store).where("created_at >= ? AND created_at <= ?", time_start, time_end).first
    if stock_value.nil?
      StockValue.create store: store, user: User.first, date_created: DateTime.now, nominal: values, description: "Nilai Stock - "+Date.today.month.to_s+"/"+Date.today.year.to_s
    else
      stock_value.nominal = values
      stock_value.save!
    end
    return values
  end

  def self.assets store, time_start, time_end
    values = CashFlow.where(finance_type: "Asset").where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store).sum(:nominal)
    return values
  end

  def self.transaksi store, time_start, time_end
    hpp_totals = Transaction.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store).sum(:hpp_total)
    grand_totals = Transaction.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store).sum(:grand_total)
    return [(grand_totals-hpp_totals), grand_totals]
  end

  def self.outcomes store, time_start, time_end
    cash_flow = CashFlow.where(finance_type: ["Tax", "Fix_Cost", "Operational", "Outcome"])
    values = cash_flow.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store, payment: nil).sum(:nominal)
    return values
  end

  def self.incomes store, time_start, time_end
    cash_flow = CashFlow.where(finance_type: ["Income"])
    values = cash_flow.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store, payment: nil).sum(:nominal)
    
    return values
  end

  def self.loss_item store,time_start, time_end
    loss_val = 0
    losses = Loss.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store)
    losses.each do |loss|
      losses_items = loss.loss_items
      losses_items.each do |loss|
        store_stock = StoreItem.find_by(store: store, item: loss.item)
        loss_val += loss.quantity * store_stock.item.buy if !store_stock.item.local_item
        loss_val += loss.quantity * store_stock.buy if store_stock.item.local_item
      end
    end
    return loss_val
  end

  def self.salary 
    end_date_s = @@salary_date+"-"+Date.today.month.to_s+"-"+Date.today.year.to_s
    end_date = end_date_s.to_datetime.end_of_day
    start_date = (end_date - 1.month + 1.day).beginning_of_day

    User.all.each do |user|
      absents = Absent.where(user: user).where("check_in >= ? AND check_in <= ?", start_date, end_date).count
      user_salary = user.salary
      salary = user_salary * absents
      user_salary = UserSalary.where(user: user).where("created_at >= ? AND created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day).first
      if user_salary.nil?
        UserSalary.create user: user, nominal: salary, checking: absents
      else
        user_salary.checking = absents
        user_salary.nominal = salary
        user_salary.save!
      end
    end

  end
  
end