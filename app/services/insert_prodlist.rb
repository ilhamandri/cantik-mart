require 'roo'

class InsertProdlist

	def initialize
	end

	def self.read
		StoreItem.delete_all
		Item.delete_all
		ItemCat.delete_all
		Department.delete_all
		department = Department.create name: "DEFAULT"
		itemcat_id = ItemCat.create name: "DEFAULT", department: department
		files = Dir["data/prodlist/*.xlsx"]
		puts files.count
		files.each do |file|
			xlsx = Roo::Spreadsheet.open("./"+file, extension: :xlsx)
			store_id = file.gsub('data/prodlist/','').split('-').first
			xlsx.each_with_index do |row, idx|
				puts "IDX : "+idx.to_s
				next if xlsx.first == row
				binding.pry if row[0].nil?
				binding.pry if row[0]=="#NAME?"
				code = row[0]
				name = row[1]
				buy = row[3]
				sell = row[4]
				limit = 5
				stock = row[5]
				brand = row[1].split[0]
	 			insert_prod code, name, buy, sell, itemcat_id, brand, store_id, stock, limit
			end
		end
	end

	def self.insert_prod code, name, buy, sell, cat_id, brand, store_id, stock, limit
		item = Item.find_by(code: code)
		if item.nil?
			item = Item.create code: code, name: name, buy: buy, sell: sell, item_cat: cat_id, brand: brand
		end
		a = StoreItem.create store_id: store_id.to_i, stock: stock, item: item, min_stock: limit
	end

	def self.find_cat cat_name
		cat = ItemCat.find_by(name: cat_name)
		if cat.present?
			return cat
		else
			binding.pry
		end
	end
end