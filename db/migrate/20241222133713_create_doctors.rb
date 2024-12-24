class CreateDoctors < ActiveRecord::Migration[7.2]
  def change
    create_table :doctors do |t|
      t.string :name
      t.string :email
      t.string :password
      t.string :password_token
      t.datetime :password_token_expires_at

      t.timestamps
    end
  end
end
