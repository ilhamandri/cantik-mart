class ReCheck

	def self.complain
		end_date = DateTime.now
		start_date = end_date - 1.day
		trxs = Transaction.where(from_complain: true, created_at:start_date..end_date)
		trxs.each do |trx2|
			trx2_grand_total = trx2.grand_total
			trx2_hpp = trx2.hpp_total
			trx1 = Transaction.find_by(id: trx2.complain.transaction_id)
			trx1_complain_hpp = 0
			trx1.transaction_items.each do |trx1_item|
				trx1_complain_hpp += (trx1_item.item.buy*trx1_item.retur) if trx1_item.retur.present?
			end
			trx2_hpp -= trx1_complain_hpp
			trx2.save!
		end
	end

end