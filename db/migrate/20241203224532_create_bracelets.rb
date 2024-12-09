class CreateBracelets < ActiveRecord::Migration[7.2]
  def change
    create_table :bracelets do |t|
      t.string :name
      t.string :brand
      t.string :api_key
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
