require 'roo'

class InsertProdlist

	def self.read_file_category
		files = Dir["./data/prodlist/category/*.xlsx"]
		files.each do |file|

			xlsx = Roo::Spreadsheet.open(file, extension: :xlsx)

			department = nil
			department_name = nil
			subdept_name = nil
			item_cat = nil

			xlsx.each_with_pagename do |name, sheet|
			  	sheet.each do |name, code|
			  		next if name.nil?
			  		if code.nil?
			  			if department_name.nil?
			  				department_name = name.split(":")[1]
			  				department = Department.find_by(name: department_name)
							department = Department.create name: department_name if department.nil?
							next
				  		else
				  			subdept_name = name.split(":")[1]
							item_cat = ItemCat.find_by(name: subdept_name)
							item_cat = ItemCat.create department: department, name: subdept_name if item_cat.nil?
							next
				  		end
			  		else
						item = Item.find_by(code: code)
						next if item.nil?
						item.item_cat = item_cat
						item.save!
			  		end
				end
			end
		end
	end

	def self.create_backup
		path = "item.txt"

		File.open(path, "w+") do |f|
			Item.all.each do |item|
				data = item.id.to_s + ";" + item.code.to_s + ";" + item.name.to_s + ";" + item.brand.to_s + ";" + item.buy.to_s + ";" + item.sell.to_s + ";" + item.item_cat_id.to_s + ";" + 						item.discount.to_s + ";" + item.margin.to_s + ";" + item.local_item.to_s
				f.puts(data)
			end
		end

		path = "stock.txt"

		File.open(path, "w+") do |f|
			StoreItem.all.each do |item|
				data = item.id.to_s + ";" + item.store_id.to_s + ";" + item.stock.to_s + ";" + item.min_stock.to_s + ";" + item.buy.to_s + ";" + item.sell.to_s + ";" + item.head_buy.to_s + ";" + item.item_id.to_s
				f.puts(data)
			end
		end
	end

	def self.restore
		File.open("item.txt", "r").each_line do |line|
			data = line.split(";")
			id = data[0]
			code = data[1]
			name = data[2]
			brand = data[3]
			buy = data[4]
			sell = data[5]
			item_cat_id = data[6]
			discount = data[7]
			margin = data[8]
			local_item = data[9]

			item = Item.find_by(id: id)
			if !item.present?
				Item.create id: id, name: name, code: code, brand: brand, buy: buy, sell: sell, item_cat_id: item_cat_id, discount: discount, margin: margin, local_item: local_item
			end
		end
		File.open("stock.txt", "r").each_line do |line|
			data = line.split(";")
			id = data[0]
			store_id = data[1]
			stock = data[2]
			min_stock = data[3]
			buy = data[4]
			sell = data[5]
			head_buy = data[6]
			item_id = data[7]

			item = Item.find_by(id: item_id)
			if !StoreItem.find_by(item: item, store_id: store_id).present?
				StoreItem.create id: id, store_id: store_id, stock: stock, min_stock: min_stock, buy: buy, sell: sell, head_buy: head_buy, item_id: item_id
			end
		end
	end

	def self.additional_file file
		xlsx = Roo::Spreadsheet.open("./data/prodlist/"+file, extension: :xlsx)
		store_id = file.gsub('./data/prodlist/','').split('-').first
		xlsx.each_with_index do |row, idx|
			code = row[0]
			qty = row[1]
			next if qty.nil?
			item = Item.find_by(code: code)
			store_item = StoreItem.find_by(item: item, store_id: store_id)
			next if store_item.nil?
			store_item.stock = store_item.stock + qty.to_f
 			store_item.save!	
 		end
	end

	def self.cross_check file
		department = Department.create name: "DEFAULT" if Department.find_by(name: "DEFAULT").nil?
		itemcat_id = ItemCat.find_by(name: "DEFAULT")
		if itemcat_id.nil?
			itemcat_id = ItemCat.create name: "DEFAULT", department: department 
		end
		xlsx = Roo::Spreadsheet.open("./data/prodlist/"+file, extension: :xlsx)
		store_id = file.gsub('./data/prodlist/','').split('-').first
		xlsx.each_with_index do |row, idx|
			puts "IDX : "+idx.to_s
			next if xlsx.first == row
			binding.pry if row[0].nil?
			binding.pry if row[0]=="#NAME?"
			code = row[0]
			name = row[1]
			buy = row[3]
			sell = row[4]
			limit = 1
			stock = row[5]
			if stock.nil? || stock == "\n" || stock == "  "
				stock = 0
			end
			brand = row[1].split[0]
 			insert_prod code, name, buy, sell, itemcat_id, brand, store_id, stock, limit
		end
	end

	def self.insert_prod code, name, buy, sell, cat_id, brand, store_id, stock, limit
		item = Item.find_by(code: code)
		if item.nil?
			item = Item.create code: code, name: name, buy: buy, sell: sell, item_cat: cat_id, brand: brand
		end
		if item.errors.present?
			binding.pry
		end
		if StoreItem.find_by(store_id: store_id, item: item).nil?
			a = StoreItem.create store_id: store_id.to_i, stock: stock, item: item, min_stock: limit
			if a.errors.present?
				binding.pry
			end
		end
	end
end