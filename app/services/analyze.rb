class Analyze
  require 'apriori'

	def self.generate_popular_items
      PopularItem.destroy_all
      start_date = DateTime.now-1.year
      end_date = DateTime.now-1.day
      Store.all.each do |store|
        trxs = Transaction.where(store: store, created_at: start_date..end_date)
        item_sells = TransactionItem.where(transaction_id: trxs).where.not(item: Item.where(item_cat_id: 134)).group(:item_id).count
        high_results = Hash[item_sells.sort_by{|k, v| v}.reverse]
        low_results = Hash[item_sells.sort_by{|k, v| v}]
        highs = high_results
        date = DateTime.now.beginning_of_month
        highs.each_with_index do |data, idx|
          break if idx==100
          item = Item.find_by(id: data[0])
          item_cat = item.item_cat
          department = item_cat.department
          sell = data[1]
          pop_item = PopularItem.create item: item, item_cat: item_cat, department: department, n_sell: sell, date: date, store: current_user.store
        end
      end
    end


    def self.calculate_kpi 
    	Thread.start{
	    	Item.all.each do |item|
	    		calculate_kpi_item item	
	    	end
    	}
    end

	def self.calculate_kpi_item item
	    date_end = DateTime.now
	    order_3months = OrderItem.where(item: item, created_at: (DateTime.now-6.months)..date_end).sum(:receive).to_f
	    order_6months = OrderItem.where(item: item, created_at: (DateTime.now-12.months)..date_end).sum(:receive).to_f

	    sell_3months = TransactionItem.where(item: item, created_at: (DateTime.now-6.months)..date_end).sum(:quantity).to_f
	    sell_6months = TransactionItem.where(item: item, created_at: (DateTime.now-12.months)..date_end).sum(:quantity).to_f

	    kpi_3month = 0.01
	    kpi_6month = 0.01
	    kpi_3month = (sell_3months.to_f / order_3months.to_f) * 100.0 if order_3months > 0 && sell_3months > 0
	    kpi_6month = (sell_6months.to_f / order_6months.to_f) * 100.0 if order_6months > 0 && sell_6months > 0
	    
	    kpi_3month = 100.0 if kpi_3month > 100.0
	    kpi_6month = 100.0 if kpi_6month > 100.0
	    
	    kpi = ((kpi_3month*0.75) + (kpi_6month*0.25)).ceil(2)

	    item.kpi = kpi

	    item.save!
	end

	def self.predict_all
		Thread.start{
			predict_items
			predict_item_cats
		}
	end

	def self.predict_item_cats
	    data_item = []
	    data = []
	    trxs = TransactionItem.where("created_at >= ?", DateTime.now.beginning_of_day-1.months)
	    trxs.each do |trx|
	    	item_cat_id = trx.item.item_cat.id
	    	next if item_cat_id == 134
	      data << item_cat_id
	    end
	    item_cat_set = Apriori::ItemSet.new(data)
	    support = 1
	    confidence = 1

	    minings_item_cats = item_cat_set.mine(support, confidence)
	    minings_item_cats.each do |mining|
	      percentage = mining[1]
	      items = mining[0].split("=>")
	      buy = ItemCat.find_by(id: items[0])
	      # next if items[1] == 134 || items[0] == 134
	      usually = ItemCat.find_by(id: items[1])
	      predict_cat = PredictCategory.find_by(buy: buy, usually: usually)
	      if predict_cat.present?
	        predict_cat.percentage = ( percentage.to_f + predict_cat.percentage) / 2
	        predict_cat.save!
	      else
	        predict_cat = PredictCategory.create percentage: percentage, buy: buy, usually: usually
	      end
	    end

	    puts "=========================> Refresh Prediksi [ITEM CAT] Selesai" 
	end

	def self.predict_items
	    data_item = []
	    data = []
	    trxs = Transaction.where("created_at >= ?", DateTime.now-3.month)
	    trxs.each do |trx|
	      trx_items_id = trx.transaction_items.pluck(:item_id)
	      data_item << trx_items_id
	    end
	    item_set = Apriori::ItemSet.new(data_item)
	    support = 0.05
	    confidence = 0.8
	    minings_item = item_set.mine(support, confidence)

	    minings_item.each do |mining|
	      percentage = mining[1]
	      items = mining[0].split("=>")
	      buy = Item.find_by(id: items[0])
	      usually = Item.find_by(id: items[1])
	      predict = PredictItem.find_by(buy: buy, usually: usually)
	      if predict.present?
	        predict.percentage = percentage
	        predict.save!
	      else
	        predict = PredictItem.create percentage: percentage, buy: buy, usually: usually
	      end
	    end


	    puts "--------------------------------> Refresh Prediksi [ITEM] Selesai" 
	end
end  
