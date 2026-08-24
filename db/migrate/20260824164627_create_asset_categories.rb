class CreateAssetCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_categories do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :asset_categories, :name, unique: true
    add_index :asset_categories, :slug, unique: true
  end
end
