class AccountBalance
  
  @@store_id = 1

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
      nilai_stok = stock_values(store, time_start, time_end).to_f
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

  def self.stock_values store, time_start, time_end
    stocks = StoreItem.where(store: store).where('stock != 0')
    values = 0
    stocks.each do |store_stock|
      values += store_stock.stock * store_stock.item.buy if !store_stock.item.local_item
      values += store_stock.buy * store_stock.stock if store_stock.item.local_item
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
    # LOSS
    loss_val = 0
    returs = Retur.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store)
    returs.each do |retur|
      losses = retur.retur_items.where(feedback: 'loss')
      losses.each do |loss|
        store_stock = StoreItem.find_by(store: store, item: loss.item)
        loss_val += loss.quantity * store_stock.item.buy if store_stock.buy == 0
        loss_val += loss.quantity * store_stock.stock if store_stock.buy > 0
      end
    end
    return loss_val
  end
  
end