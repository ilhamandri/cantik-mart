class ReCheck

	def self.complain
		end_date = DateTime.now
		start_date = end_date - 3.day
		trxs = Transaction.where(from_complain: true, created_at:start_date..end_date)
		trxs.each do |trx2|
			trx2_hpp = 0
			trx2.transaction_items.each do |trx2_item|
				trx2_hpp += trx_item.item.buy * trx2_item.quantity
			end
			trx2.hpp_total = trx2_hpp
			trx2_grand_total = trx2.grand_total
			trx1 = Transaction.find_by(id: trx2.complain.transaction_id)
			trx1_complain_hpp = 0
			trx1.transaction_items.each do |trx1_item|
				trx1_complain_hpp += (trx1_item.item.buy*trx1_item.retur) if trx1_item.retur.present?
			end
			trx2.hpp_total = trx2.hpp_total - trx1_complain_hpp
			binding.pry
			trx2.save!
		end
	end

end