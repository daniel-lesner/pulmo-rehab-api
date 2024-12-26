class AddDoctorToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :doctor, foreign_key: true
  end
end
