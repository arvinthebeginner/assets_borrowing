class CreateBorrowRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :borrow_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :asset_unit, null: false, foreign_key: true
      t.references :decided_by, foreign_key: { to_table: :users }

      t.text :purpose, null: false
      t.date :start_on, null: false
      t.date :end_on, null: false
      t.string :status, null: false, default: "pending"

      t.datetime :decided_at
      t.text :rejection_reason
      t.datetime :picked_up_at
      t.datetime :returned_at

      t.timestamps
    end

    add_index :borrow_requests, :status
    # Index untuk mempercepat pencarian peminjaman yang mengunci unit di rentang tanggal tertentu.
    add_index :borrow_requests, %i[asset_unit_id start_on end_on]
  end
end
