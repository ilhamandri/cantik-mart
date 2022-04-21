class ReCheck
	# complain
	def self.complain
		end_date = DateTime.now
		start_date = end_date - 1.day
		trxs = Transaction.where(from_complain: true, created_at:start_date..end_date)
		trxs.each do |trx2|
			trx2_hpp = 0
			trx2.transaction_items.each do |trx2_item|
				trx2_hpp += trx2_item.item.buy.to_i * trx2_item.quantity.to_i
			end
			trx2.hpp_total = trx2_hpp
			trx1 = Transaction.find_by(id: trx2.complain.transaction_id)
			trx1_complain_hpp = 0
			trx1_hpp = 0
			trx1.transaction_items.each do |trx1_item|
				trx1_complain_hpp += (trx1_item.item.buy*trx1_item.retur) if trx1_item.retur.present?
				trx1_hpp += trx1_item.item.buy*trx1_item.quantity
			end
			trx1.hpp_total = trx1_hpp 
			trx2.hpp_total = trx2_hpp - trx1_complain_hpp
			trx2.save!
			trx1.save!
		end
	end

	# HUTANG
	def self.debt
		duplicates = Debt.where("description like 'ORD-%'").select(:description).group(:description).having("count(*) > 1").count
		duplicates.each do |duplicate|
			debts = Debt.where(description: duplicate[0])
			debts.each do |debt|
				debt.destroy
				break
			end
		end
	end

	# KOIN

end