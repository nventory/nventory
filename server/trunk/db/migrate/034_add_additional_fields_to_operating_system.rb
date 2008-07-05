class AddAdditionalFieldsToOperatingSystem < ActiveRecord::Migration
  def self.up
    add_column "operating_systems", "architecture", :string

    add_column "operating_systems", "description", :text
    create_table :operating_system_notes do |t|
      t.column :operating_system_id,  :integer, :null => false
      t.column :note,                  :string, :null => false
      t.column :created_at,            :datetime
    end
    add_index :operating_system_notes, :operating_system_id
  end

  def self.down
    remove_column "operating_systems", "architecture"

    remove_column "operating_systems", "description"
    drop_table :operating_system_notes
  end
end
