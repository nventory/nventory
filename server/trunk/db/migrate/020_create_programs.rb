class CreatePrograms < ActiveRecord::Migration
  def self.up
    create_table :programs do |t|
      t.column :customer_id,     :integer
      t.column :status_id,       :integer
      t.column :name,            :string
      t.column :notes,           :text
      t.column :main_url,        :string
      t.column :stream_url,      :string
      t.column :analytics_url,   :string
      t.column :reporting_url,   :string
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :programs, :id
    add_index :programs, :customer_id
    add_index :programs, :status_id
    add_index :programs, :name
    add_index :programs, :deleted_at
  end

  def self.down
    drop_table :programs
  end
end
