class CreateAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :assets do |t|
      t.references :asset_category, null: false, foreign_key: true
      t.string :brand, null: false
      t.string :model, null: false
      t.text :description

      t.timestamps
    end

    add_index :assets, %i[brand model], unique: true
  end
end
