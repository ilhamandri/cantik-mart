class Grant

	def self.insert_user
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

end