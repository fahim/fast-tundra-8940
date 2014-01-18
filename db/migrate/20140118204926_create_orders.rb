class CreateOrders < ActiveRecord::Migration
  def change
    create_table(:orders, id: false) do |t|
      t.integer :id, :options => 'PRIMARY KEY'
      t.integer :order_num, :user_id
      t.timestamps
    end

    add_index :orders, :id
    add_index :orders, :order_num
    add_index :orders, :user_id
  end
end
