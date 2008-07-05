class CreateDatacenterEnvironmentAssignments < ActiveRecord::Migration
  def self.up
    create_table :datacenter_environment_assignments do |t|
      t.column :datacenter_id,    :integer
      t.column :environment_id,   :integer
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :datacenter_environment_assignments, :id
    add_index :datacenter_environment_assignments, :datacenter_id
    add_index :datacenter_environment_assignments, :environment_id
    add_index :datacenter_environment_assignments, :assigned_at
    add_index :datacenter_environment_assignments, :deleted_at
  end

  def self.down
    drop_table :datacenter_environment_assignments
  end
end
