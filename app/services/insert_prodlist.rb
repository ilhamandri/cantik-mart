require 'roo'

class InsertProdlist

	def self.read_file_category
		files = Dir["./data/backup/department/*.xlsx"]
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
						item = Item.find_by(code: name)
						next if item.nil?
						item.item_cat = item_cat
						item.save!
			  		end
				end
			end
		end
	end

	def self.delete_items
		files = Dir["./data/backup/delete/*.xlsx"]
		files.each do |file|
			xlsx = Roo::Spreadsheet.open(file, extension: :xlsx)
			xlsx.each_with_index do |row, idx|
				code = row[0]
				item = Item.find_by(code: code)
				next if item.nil?
				trx_items = item.transaction_items
				transfer_items = item.transfer_items
				order_items = item.order_items
				send_back_items = item.send_back_items
				if send_back_items && trx_items.empty? && transfer_items.empty? && order_items.empty? 
					item.store_items.destroy_all
					item.item_prices.destroy_all 
					item.destroy
				end
	 		end
	 	end
	end

	def self.additional_file 
		files = Dir["./data/backup/barang_baru/*.xlsx"]
		files.each do |file|
			xlsx = Roo::Spreadsheet.open(file, extension: :xlsx)
			store_id = 1
			xlsx.each_with_index do |row, idx|
				code = row[0]
				name = row[1]
				category_name = row[2]
				qty = row[3]
				item = Item.find_by(code: code)
				next if item.present?
				item_category = ItemCat.find_by(name: category_name)
				next if item_category.nil?
				insert_prod code, name, 0, 0, item_category.id, "DEFAULT", store_id, qty, 10
	 		end
	 	end
	end

	def self.insert_prod code, name, buy, sell, cat_id, brand, store_id, stock, limit
		item = Item.find_by(code: code)
		if item.nil?
			item = Item.create code: code, name: name, buy: buy, sell: sell, item_cat_id: cat_id, brand: brand
			Store.all.each do |store|
				if store.id == store_id
					StoreItem.create item: item, stock: stock, store:  store
				else
					StoreItem.create item: item, stock: 0, store: store
				end
			end
		end
	end
end