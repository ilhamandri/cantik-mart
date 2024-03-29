class AccountBalance

  # day of the week in 0-6. Sunday is day-of-week 0; Saturday is day-of-week 6.
  @@work_day = [1,2,3,4,5]
  @@salary_date = "25"

  def initialize
  end

  def self.send_trx
    puts "OKE"
  end

  def self.balance_account
    stores = Store.all
    time_start = DateTime.now.beginning_of_month.beginning_of_day
    time_end = DateTime.now.end_of_day
    stores.each do |store|
      # kas
      kas = store.cash.to_f - store.grand_total_before.to_f
      bank = store.bank.to_f - store.grand_total_card_before.to_f
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
      penjualan_cash = transaksi_arr[1]
      penjualan_bank = transaksi_arr[2]

      kas += penjualan_cash
      bank += penjualan_bank
      
      # transfer value
      transfer = transfers(store, time_start, time_end).to_f
      # outcome
      pengeluaran = outcomes(store, time_start, time_end).to_f
      #income
      pemasukan = incomes(store, time_start, time_end).to_f
      # loss_item
      loss = loss_item(store, time_start, time_end).to_f
      # (profit - loss)
      profit -= loss
      income_outcome = pemasukan - pengeluaran 
      # modal
      modals = store.equity.to_f
      modals = modals - store.modals_before.to_f
      modals+= transfer
      # debt
      hutang_sebelumnya = Debt.where("created_at < ? AND deficiency > 0", time_start).where(store: store).sum(:deficiency).to_f
      hutang = hutang_sebelumnya + Debt.where("created_at >= ? AND created_at <= ? AND deficiency > 0", time_start, time_end).where(store: store).sum(:deficiency).to_f

      aktiva = bank + kas + piutang + nilai_stok + nilai_aset
      passiva = profit + income_outcome + modals + hutang


      store.debt = hutang
      store.receivable = piutang
      store.save!

      curr_day_start = DateTime.now.beginning_of_day
      
      curr_day_end = DateTime.now.end_of_day

      balance = nil
      balances = StoreBalance.where(store: store).where("created_at >= ? AND created_at <= ?",curr_day_start, curr_day_end)
      filenames = balances.pluck(:filename)
      balances.delete_all
      balance = StoreBalance.create store: store, cash: kas.round, receivable: piutang.round, stock_value: nilai_stok.round,
          asset_value: nilai_aset.round, transaction_value: profit.round, equity: modals.round, debt: hutang.round, outcome: income_outcome.round, bank: bank.round

      activa = balance.cash + balance.receivable + balance.asset_value + balance.stock_value
      passiva = balance.equity + balance.outcome + balance.transaction_value + balance.debt

      if activa != passiva
        diff_act_pass = activa-passiva
        if diff_act_pass <= 10000
          if activa > passiva
            balance.equity = balance.equity + diff_act_pass.abs
          else
            balance.equity = balance.equity - diff_act_pass.abs
          end
          balance.save!
        end
      end
      
      dt_now = DateTime.now
      end_month = DateTime.now.end_of_month - 1.hour - 30.minutes
      store.cash = kas
      store.bank = bank
      store.equity = modals


      store.grand_total_before = penjualan_cash
      store.grand_total_card_before = penjualan_bank
      store.modals_before = transfer
      
      if  dt_now.month == end_month.month
        if dt_now > end_month
          store.grand_total_before = 0
          store.grand_total_card_before = 0
          store.modals_before = 0
        end
      end
      
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
    # record tiap hari
    time_start = DateTime.now.beginning_of_day
    time_end = DateTime.now.end_of_day
    stock_value = StockValue.where(store: store).where(created_at: time_start.beginning_of_day..time_end.end_of_day).first
    if stock_value.nil?
      stocks = StoreItem.where(store: store).where('stock != 0')
      values = 0
      stocks.each do |store_stock|
        next if store_stock.stock <= 0
        next if store_stock.item.id == 30331
        values += (store_stock.stock * store_stock.item.buy)
      end
      # bypass
      values = values - 5000000000000000 if values > 5000000000000000

      StockValue.create store: store, user: User.first, date_created: DateTime.now, nominal: values, description: "Nilai Stock - "+Date.today.month.to_s+"/"+Date.today.year.to_s
    end
    return values
  end

  def self.assets store, time_start, time_end
    values = CashFlow.where(finance_type: "Asset").where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store).sum(:nominal)
    return values
  end

  def self.transaksi store, time_start, time_end
    trx = Transaction.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store)
    hpp_totals = trx.sum(:hpp_total)
    grand_totals = trx.sum(:grand_total)

    trx_cash = trx.where(payment_type: ["CASH"]).sum(:grand_total)
    trx_card = trx.where(payment_type: ["DEBIT", "CREDIT"]).sum(:grand_total)

    return [(grand_totals-hpp_totals), trx_cash, trx_card]
  end

  def self.outcomes store, time_start, time_end
    cash_flows = CashFlow.where(finance_type: ["Tax", "Fix_Cost", "Operational", "Outcome"]).where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store, payment: nil)
    values = 0
    cash_flows.each do |cash_flow|
      desc = cash_flow.description.split("#")
      if desc.count == 2
        inv = desc[1]
        retur = Retur.find_by(invoice: inv)
        if retur.present?
          retur_items = ReturItem.where(retur: retur, feedback: "cash")
          if retur_items.present?
            val = 0
            retur_items.each do |ret_item|
              item = ret_item.item
              store_item = StoreItem.find_by(store: cash_flow.store, item: item)
              buy = item.buy
              buy = store_item.buy if item.local_item
              val += ( ret_item.accept_item * buy) - ret_item.nominal
            end
            if val >= 0
              cash_flow.finance_type = CashFlow::INCOME
            else
              cash_flow.finance_type = CashFlow::OUTCOME
            end
            cash_flow.nominal = val
            cash_flow.save!
          end
        end
      end

      nominal = cash_flow.nominal
      values += nominal
    end
    return values
  end

  def self.incomes store, time_start, time_end
    values = 0
    cash_flows = CashFlow.where(finance_type: ["Income", "Bonus"]).where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store, payment: nil)

    cash_flows.each do |cash_flow|
      desc = cash_flow.description.split("#")
      if desc.count == 2
        inv = desc[1]
        retur = Retur.find_by(invoice: inv)
        if retur.present?
          retur_items = ReturItem.where(retur: retur, feedback: "cash")
          if retur_items.present?
            val = 0
            retur_items.each do |ret_item|
              item = ret_item.item
              store_item = StoreItem.find_by(store: cash_flow.store, item: item)
              buy = item.buy
              buy = store_item.buy if item.local_item
              val += ret_item.nominal - ( ret_item.accept_item * buy)
            end
            if val >= 0
              cash_flow.finance_type = CashFlow::INCOME
            else
              cash_flow.finance_type = CashFlow::OUTCOME
            end
            cash_flow.nominal = val
            cash_flow.save!
          end
        end
      end

      nominal = cash_flow.nominal
      values += nominal
    end
    
    return values
  end

  def self.loss_item store,time_start, time_end
    loss_val = 0
    losses = Loss.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store)
    losses.each do |loss|
      losses_items = loss.loss_items
      losses_items.each do |loss|
        store_stock = StoreItem.find_by(store: store, item: loss.item)
        loss_val += (loss.quantity * store_stock.item.buy) if !store_stock.item.local_item
        loss_val += (loss.quantity * store_stock.buy) if store_stock.item.local_item
      end
    end
    return loss_val
  end

  def self.transfers store, time_start, time_end
    val = 0
    request_transfers = Transfer.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(from_store: store)
    sent_transfers = Transfer.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(to_store: store)

    request_transfers.each do |req_trf|
      req_items = req_trf.transfer_items
      req_items.each do |req_item|
        item = req_item.item
        val += (req_item.receive_quantity.to_f * item.buy)
      end
    end

    sent_transfers.each do |sent_trf|
      sent_items = sent_trf.transfer_items
      sent_items.each do |sent_item|
        item = sent_item.item
        val -= (sent_item.sent_quantity.to_f * item.buy)
      end
    end

    return val
  end

  def self.send_backs store, time_start, time_end
    val = 0
    send_backs = SendBack.where("created_at >= ? AND created_at <= ?", time_start, time_end)
    if store.store_type != "warehouse"
      send_backs = send_backs.where(store: store)
    end

    send_backs.each do |send_back|
      send_back.send_back_items.each do |send_back_item|
        item = send_back_item.item
        val += (send_back_item.quantity * item.buy)
      end
    end

    request_transfers.each do |req_trf|
      req_items = req_trf.transfer_items
      req_items.each do |req_item|
        item = req_item.item
        val += (req_item.receive_quantity * item.buy)
      end
    end

    sent_transfers.each do |sent_trf|
      sent_items = sent_trf.transfer_items
      sent_items.each do |sent_item|
        item = sent_item.item
        val -= (sent_item.sent_quantity * item.buy)
      end
    end

    return val
  end

  def self.salary 
    binding.pry
    end_date_s = @@salary_date+"-"+Date.today.month.to_s+"-"+Date.today.year.to_s
    end_date = end_date_s.to_datetime.end_of_day+1.month
    start_date = (end_date - 1.month + 1.day).beginning_of_day
    n_days = (end_date-start_date).to_i

    working_dates = (start_date..end_date).to_a.select {|k| @@work_day.include?(k.wday)}

    User.all.each do |user|
      absents = Absent.where(user: user).where("check_in >= ? AND check_in <= ?", start_date, end_date).count
      user_salary = user.salary
      salary = user_salary.to_f * (absents.to_f / working_dates.size.to_f)
      user_salary = UserSalary.where(user: user).where("created_at >= ? AND created_at <= ?", start_date, end_date).first
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