class CreateEnvironmentNodeAssignments < ActiveRecord::Migration
  def self.up
    create_table :environment_node_assignments do |t|      
      t.column :environment_id,   :integer
      t.column :node_id,          :integer
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :environment_node_assignments, :id
    add_index :environment_node_assignments, :node_id
    add_index :environment_node_assignments, :environment_id
    add_index :environment_node_assignments, :assigned_at
    add_index :environment_node_assignments, :deleted_at
    EnvironmentNodeAssignment.create_versioned_table
  end

  def self.down
    drop_table :environment_node_assignments
    EnvironmentNodeAssignment.drop_versioned_table
  end
end
