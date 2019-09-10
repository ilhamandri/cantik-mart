require 'roo'

class InsertProdlist

	def initialize
	end

	def read
		insert_department

		files = Dir["data/*.xlsx"]
		files.each do |file|
			xlsx = Roo::Spreadsheet.open("./"+file, extension: :xlsx)
			xlsx.each_with_index do |row, idx|
				next if xlsx.first == row
				binding.pry if row[0].nil?
				binding.pry if row[0]=="#NAME?"
				cat_name = row[0].strip
				code = row[1]
				name = row[2]
				buy = row[4]
				sell = row[5]
				wholesale = row[6]
				box = row[7]
				brand = row[2].split[0]
				category = find_cat cat_name
				cat_id = category.id
	 			insert_prod code, name, buy, sell, wholesale, box, cat_id, brand, file
			end
		end
	end

	def insert_department
		GrocerItem.delete_all
		TransferItem.delete_all
		Transfer.delete_all
		Item.delete_all
		ItemCat.delete_all
		Department.delete_all

		xlsx = Roo::Spreadsheet.open('./DEPARTMENTS.xlsx', extension: :xlsx)
		xlsx.each do |row|
			department_name = row[0].upcase.strip
			department = Department.create name: department_name
			ItemCat.create name: department_name, department: department
			if row[1].present?
				sub_department_name = row[1].upcase.strip.split('-')
				sub_department_name.each do |item_cat_name|
					ItemCat.create name: item_cat_name, department: department
				end
			end
		end
	end

	def insert_prod code, name, buy, sell, wholesale, box, cat_id, brand, file
		item = Item.create code: code, name: name, buy: buy, 
		sell: sell, wholesale: wholesale, box: box, 
		item_cat_id: cat_id, brand: brand
		StoreItem.create store: Store.first, stock: 0, item: item
	end

	def find_cat cat_name
		cat = ItemCat.find_by(name: cat_name)
		if cat.present?
			return cat
		else
			binding.pry
		end
	end
end