class CreateUsers < ActiveRecord::Migration
  def change
    create_table(:users, id: false) do |t|
      t.integer :id, :options => 'PRIMARY KEY'
      t.timestamps
    end

    add_index :users, :id
  end
end
