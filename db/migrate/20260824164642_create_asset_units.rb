class CreateAssetUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_units do |t|
      t.references :asset, null: false, foreign_key: true
      t.string :asset_tag, null: false
      t.string :serial_number, null: false
      t.string :status, null: false, default: "available"
      t.string :condition, null: false, default: "good"
      t.text :notes

      t.timestamps
    end

    add_index :asset_units, :asset_tag, unique: true
    add_index :asset_units, :serial_number, unique: true
    add_index :asset_units, :status
  end
end
