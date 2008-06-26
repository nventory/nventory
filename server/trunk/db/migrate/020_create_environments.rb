class CreateEnvironments < ActiveRecord::Migration
  def self.up
    create_table :environments do |t|
      t.column :name,            :string
      t.column :notes,           :text
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :environments, :id
    add_index :environments, :name
    add_index :environments, :deleted_at
    Environment.create_versioned_table
  end

  def self.down
    drop_table :environments
    Environment.drop_versioned_table
  end
end
