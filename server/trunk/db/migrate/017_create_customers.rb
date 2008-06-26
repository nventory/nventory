class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.column :name,            :string
      t.column :notes,           :text
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :customers, :id
    add_index :customers, :name
    add_index :customers, :deleted_at
    Customer.create_versioned_table
  end

  def self.down
    drop_table :customers
    Customer.drop_versioned_table
  end
end
