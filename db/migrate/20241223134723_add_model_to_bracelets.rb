class AddModelToBracelets < ActiveRecord::Migration[6.0]
  def change
    add_column :bracelets, :model, :string
  end
end
