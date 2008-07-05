class CreateFunctionTypes < ActiveRecord::Migration
  def self.up
    create_table :function_types do |t|
      t.column :name,                              :string
      t.column :notes,                             :text
      t.column :enables_database_instance_access,  :bool, :default => false
      t.column :created_at,                        :datetime
      t.column :updated_at,                        :datetime
      t.column :deleted_at,                        :datetime
    end
    add_index :function_types, :id
    add_index :function_types, :name
    add_index :function_types, :deleted_at
  end

  def self.down
    drop_table :function_types
  end
end
