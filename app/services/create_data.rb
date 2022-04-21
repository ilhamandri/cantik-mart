class CreateData
	def self.CreateNotificationNewPrice
		Item.where("tax > 0").each do |item|
			Store.all.each do |store|
	          Print.create item: item, store: store
	        end
	        message = "Terdapat perubahan harga jual. Segera cetak label harga "+item.name
	        to_users = User.where(level: ["owner", "super_admin", "super_visi"])
	        to_users.each do |to_user|
	        	Notification.create from_user: User.last, to_user: to_user, m_type: "info", message: message, link: "/prints", date_created: DateTime.now
	        end
	    end
	end

	def self.insert_user
		puts "INSERT USER!"
		store_1 = nil
		store_2 = nil
		store_3 = nil
		if Store.find_by(name: "GUDANG CIRATA").nil?
			store_1 = Store.create name:"GUDANG CIRATA", cash: 10000000, equity: 10000000
			store_2 = Store.create name:"TOKO CIRATA", cash: 10000000, equity: 10000000
			store_3 = Store.create name:"TOKO PLERED", cash: 10000000, equity: 10000000
		else
			store_1 = Store.find_by(name: "GUDANG CIRATA")
			store_2 = Store.find_by(name: "TOKO CIRATA")
			store_3 = Store.find_by(name: "TOKO PLERED")
		end

		xlsx = Roo::Spreadsheet.open("./data/grant/users.xlsx", extension: :xlsx)
		xlsx.each_with_pagename do |name, sheet|
			xlsx.each_with_index do |row, idx|
				fingerprint_id = row[0]
				name = row[1]
				email = row[2]
				level = row[3]
				store = row[4].to_i

				next if User.find_by(email: email).present?
				
				user = User.new
				user.name = name
				user.email = email
				user.password = "cantikmart"
				user.level = level.to_i
				user.fingerprint = fingerprint_id

				if store == 1
					user.store = store_1
				elsif store == 2
					user.store = store_2
				else
					user.store = store_3
				end
				user.save!
			end
		end
	end

	def self.insert_access_grant
		UserMethod.delete_all
		xlsx = Roo::Spreadsheet.open("./data/grant/grant.xlsx", extension: :xlsx)
		xlsx.each_with_pagename do |name, sheet|
			xlsx.each_with_index do |row, idx|
				next if xlsx.first == row
				controller = Controller.find_by(name: name)
				controller_method = ControllerMethod.find_by(controller: controller,name: row)
				if controller_method.nil?
				end
				if row[1]==nil
					User::levels.keys.each do |level|
						a = UserMethod.create controller_method: controller_method, user_level: level
						binding.pry if a.errors.present?
					end
				else
					levels = row[1].split(',')
				if levels.include? "-"
					UserMethod.create controller_method: controller_method, user_level: "owner"
						UserMethod.create controller_method: controller_method, user_level: "super_admin"
					else
						levels = row[1].split(',')
						levels.each do |level|
							level = level.gsub(' ','')
							UserMethod.create controller_method: controller_method, user_level: level
						end
						
						UserMethod.create controller_method: controller_method, user_level: "super_admin"
						

						if levels.include? "owner"
							UserMethod.create controller_method: controller_method, user_level: "owner"
						end
					end
				end
			end
		end
	end


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
				if send_back_items.empty? && trx_items.empty? && transfer_items.empty? && order_items.empty? 
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