class CreateHealthData < ActiveRecord::Migration[7.2]
  def change
    create_table :health_data do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :age
      t.string :gender
      t.integer :weight
      t.integer :height
      t.boolean :smoker
      t.string :primary_diagnosis
      t.string :copd_stage
      t.boolean :respiratory_failure
      t.string :angina
      t.string :hypertension
      t.boolean :venous_insufficiency
      t.integer :spo2
      t.string :bp
      t.integer :heart_rate
      t.float :fev1
      t.float :ipb
      t.float :fvc
      t.string :biseptol
      t.boolean :laba_lama
      t.boolean :ics
      t.string :acc
      t.string :ventolin

      t.timestamps
    end
  end
end
