class LossProfitsController < ApplicationController
  before_action :require_login

  def index
  	curr_date = DateTime.now
  	start_day = curr_date.beginning_of_month
  	@start = start_day
   	end_day = curr_date.end_of_month
   	@end = end_day
   	cirata = Store.find_by(id: 2)
   	plered = Store.find_by(id: 3)

   	cash_flow = CashFlow.where("created_at >= ? AND created_at <= ?", start_day, end_day)
  	trx = Transaction.where("created_at >= ? AND created_at <= ?", start_day, end_day)
  	
  	grand_total_plered = trx.where(store: plered).sum(:grand_total)
  	hpp_total_plered = trx.where(store: plered).sum(:hpp_total)
  	grand_total_cirata = trx.where(store: cirata).sum(:grand_total)
  	hpp_total_cirata = trx.where(store: cirata).sum(:hpp_total)

  	@margin_plered = grand_total_plered - hpp_total_plered
  	@margin_cirata = grand_total_cirata - hpp_total_cirata
  	@supplier_income = 0
  	@bonus = cash_flow.where(finance_type: CashFlow::BONUS).sum(:nominal)
  	@other_income = cash_flow.where(finance_type: CashFlow::INCOME).sum(:nominal)

  	@total_income = @margin_plered + @margin_cirata + @supplier_income + @bonus + @other_income
  
  	cash_flow = CashFlow.where("created_at >= ? AND created_at <= ?", start_day, end_day)
  	@operational = cash_flow.where(finance_type: [CashFlow::OPERATIONAL, CashFlow::TAX]).sum(:nominal)
  	@fix_cost = cash_flow.where(finance_type: CashFlow::FIX_COST).sum(:nominal)
  	@losses = losses(start_day, end_day)
  	@other_outcome = cash_flow.where(finance_type: CashFlow::OUTCOME).sum(:nominal)
  	
  	@total_outcome = @operational + @fix_cost + @losses + @other_outcome
  end

  private
  	def losses start_day, end_day
  		loss_val = 0
	    Store.all.each do |store|
	    	losses = Loss.where("created_at >= ? AND created_at <= ?", start_day, end_day)
		    losses.each do |loss|
		      losses_items = loss.loss_items
		      losses_items.each do |loss|
		        store_stock = StoreItem.find_by(store: store, item: loss.item)
		        loss_val += (loss.quantity * store_stock.item.buy) if !store_stock.item.local_item
		        loss_val += (loss.quantity * store_stock.buy) if store_stock.item.local_item
		      end
		    end
		end
	    return loss_val
  	end
end