class AddModelToBracelets < ActiveRecord::Migration[7.2]
  def change
    add_column :bracelets, :model, :string
  end
end
