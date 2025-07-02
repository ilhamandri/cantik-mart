class AddColSupplierLocal < ActiveRecord::Migration[7.2]
  def change
    add_column :suppliers, :local, :boolean, default: false
  end
end
