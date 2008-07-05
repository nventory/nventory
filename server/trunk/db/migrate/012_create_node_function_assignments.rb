class CreateNodeFunctionAssignments < ActiveRecord::Migration
  def self.up
    create_table :node_function_assignments do |t|
      t.column :node_id,          :integer
      t.column :function_id,      :integer
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :node_function_assignments, :id
    add_index :node_function_assignments, :node_id
    add_index :node_function_assignments, :function_id
    add_index :node_function_assignments, :assigned_at
    add_index :node_function_assignments, :deleted_at
  end

  def self.down
    drop_table :node_function_assignments
  end
end
