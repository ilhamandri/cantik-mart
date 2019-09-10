class AccountBalance
  
  @@store_id = 1

  def initialize
  end

  def self.balance_account
    stores = Store.all
    time_start = DateTime.now.beginning_of_day-1.days
    time_end = DateTime.now.end_of_day
    stores.each do |store|
      # kas
      kas = store.cash.to_f
      # piutang
      piutang = Receivable.where("created_at >= ? AND created_at <= ? AND deficiency > 0", time_start, time_end).where(store: store).sum(:deficiency).to_f
      # stock_value
      nilai_stok = stock_values(store, time_start, time_end).to_f
      # assets
      nilai_aset = assets(store, time_start, time_end).to_f


      # trx (profit - loss)
      transaksi = trxs(store, time_start, time_end).to_f
      # outcome
      pengeluaran = outcomes(store, time_start, time_end).to_f
      # modal
      modal = store.equity.to_f
      # debt
      hutang = Debt.where("created_at >= ? AND created_at <= ? AND deficiency > 0", time_start, time_end).where(store: store).sum(:deficiency).to_f


      aktiva = kas + piutang + nilai_stok + nilai_aset
      passiva = transaksi + pengeluaran + modal + hutang

      # PENGELUARAN PEMASUKAN PAJAK FIX_COST OPERASIONAL TRX
      # save ke db

      store.debt = hutang
      store.receivable = piutang
      store.save!

      balances = StoreBalance.where(store: store).where("created_at >= ? AND created_at <= ?",time_start, time_end)
      if balances.size == 0 
        StoreBalance.create store: store, cash: kas, receivable: piutang, stock_value: nilai_stok,
          asset_value: nilai_aset, transaction_value: transaksi, equity: modal, debt: hutang, outcome: pengeluaran
      else
        balance = balances.first
        balance.cash = kas
        balance.receivable = piutang
        balance.stock_value = nilai_stok
        balance.asset_value = nilai_aset
        balance.equity = modal
        balance.debt = hutang
        balance.transaction_value = transaksi
        balance.outcome = pengeluaran

        balance.save! if balance.changed?
      end
      # binding.pry
    end
  end

  def self.stock_values store, time_start, time_end
    stocks = StoreItem.where(store: store).where("stock > 0")
    values = 0
    stocks.each do |store_stock|
      values += store_stock.stock * store_stock.item.buy if store_stock.buy == 0
      values += store_stock.buy * store_stock.stock if store_stock.buy > 0
    end
    return values
  end

  def self.assets store, time_start, time_end
    values = CashFlow.where(finance_type: "Asset").where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store).sum(:nominal)
    return values
  end

  def self.trxs store, time_start, time_end
    # LOSS
    hpp_totals = Transaction.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store).sum(:hpp_total)
    grand_totals = Transaction.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store).sum(:grand_total)
    return (hpp_totals-grand_totals)
  end

  def self.outcomes store, time_start, time_end
    # income masuk mana
    cash_flow = CashFlow.where(finance_type: ["Tax", "Fix_Cost", "Operational"])
    values = cash_flow.where("created_at >= ? AND created_at <= ?", time_start, time_end).where(store: store).sum(:nominal)
    cash_flow_outcome = CashFlow.where(finance_type: "Outcome")
    cash_flow_outcome.each do |cash|
      if cash.invoice.split("-").count != 3
        values += cash.nominal
      end
    end
    return values
  end
end