class CreateEnvironmentProgramAssignments < ActiveRecord::Migration
  def self.up
    create_table :environment_program_assignments do |t|
      t.column :environment_id,   :integer
      t.column :program_id,       :integer
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :environment_program_assignments, :id
    add_index :environment_program_assignments, :program_id
    add_index :environment_program_assignments, :environment_id
    add_index :environment_program_assignments, :assigned_at
    add_index :environment_program_assignments, :deleted_at
    EnvironmentProgramAssignment.create_versioned_table
  end

  def self.down
    drop_table :environment_program_assignments
    EnvironmentProgramAssignment.drop_versioned_table
  end
end
