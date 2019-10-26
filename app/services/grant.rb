class Grant

	def self.insert_access_grant
		UserMethod.delete_all
		files = Dir["data/grant/*.xlsx"]
		files.each do |file|
			xlsx = Roo::Spreadsheet.open("./"+file, extension: :xlsx)
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

end