class CreateDatabaseInstances < ActiveRecord::Migration
  def self.up
    create_table :database_instances do |t|
      t.column :name,            :string
      t.column :notes,           :text
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :database_instances, :id
    add_index :database_instances, :name
    add_index :database_instances, :deleted_at
    DatabaseInstance.create_versioned_table
  end

  def self.down
    drop_table :database_instances
    DatabaseInstance.drop_versioned_table
  end
end
