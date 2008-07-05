class CreateStatuses < ActiveRecord::Migration
  def self.up
    create_table :statuses do |t|
      t.column :name,            :string
      t.column :notes,           :text
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :statuses, :id
    add_index :statuses, :name
    add_index :statuses, :deleted_at
    
    # add a column to node so it can have a status
    add_column "nodes", "status_id", :integer
    add_index :nodes, :status_id

  end

  def self.down
    drop_table :statuses
    remove_column "nodes", "status_id"
  end
end
