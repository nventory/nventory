class CreateNodeGroups < ActiveRecord::Migration
  def self.up
    create_table :node_groups do |t|
      t.column :name,           :string, :null => false
      t.column :description,    :text
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
      t.column :deleted_at,     :datetime
    end
    add_index :node_groups, :name, :unique => true
    add_index :node_groups, :deleted_at

    create_table :node_group_notes do |t|
      t.column :node_group_id,         :integer, :null => false
      t.column :note,                  :string, :null => false
      t.column :created_at,            :datetime
    end
    add_index :node_group_notes, :node_group_id
  end

  def self.down
    drop_table :node_groups
    drop_table :node_group_notes
  end
end
