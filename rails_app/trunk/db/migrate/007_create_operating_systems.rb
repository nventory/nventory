class CreateOperatingSystems < ActiveRecord::Migration
  def self.up
    create_table :operating_systems do |t|
      t.column :name,            :string
      t.column :vendor,          :string
      t.column :variant,         :string
      t.column :version_number,  :string
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :operating_systems, :id
    add_index :operating_systems, :name
    add_index :operating_systems, :deleted_at
    
    OperatingSystem.create_versioned_table
    
    # add a column to node so it can have a hardware profile
    add_column "nodes", "operating_system_id", :integer
    add_column "node_versions", "operating_system_id", :integer
    
    # Need to refresh column info for this object since `create_versioned_table` added some stuff
    OperatingSystem.reset_column_information
    
    # Some System Install Defaults
    os1 = OperatingSystem.new
    os1.name = 'Linux: FC5'
    os1.vendor = 'Fedora'
    os1.variant = 'Fedora Core'
    os1.version_number = '5'
    os1.save
    
  end

  def self.down
    drop_table :operating_systems
    OperatingSystem.drop_versioned_table
    remove_column "nodes", "operating_system_id"
    remove_column "node_versions", "operating_system_id"
  end
end
