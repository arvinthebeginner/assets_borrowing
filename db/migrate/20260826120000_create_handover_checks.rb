class CreateHandoverChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :handover_checks do |t|
      t.references :borrow_request, null: false, foreign_key: true
      t.references :checked_by, null: false, foreign_key: { to_table: :users }

      t.string :kind, null: false
      t.string :condition, null: false
      t.text :notes
      t.datetime :checked_at, null: false

      t.timestamps
    end

    # 1 peminjaman hanya punya 1 catatan pengambilan dan 1 pengembalian.
    add_index :handover_checks, %i[borrow_request_id kind], unique: true
  end
end
