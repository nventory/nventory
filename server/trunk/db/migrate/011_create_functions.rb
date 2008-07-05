class CreateFunctions < ActiveRecord::Migration
  def self.up
    create_table :functions do |t|
      t.column :name,               :string
      t.column :function_type_id,   :integer
      t.column :notes,              :text
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
      t.column :deleted_at,         :datetime
    end
    add_index :functions, :id
    add_index :functions, :name
    add_index :functions, :deleted_at
    add_index :functions, :function_type_id
  end

  def self.down
    drop_table :functions
  end
end
