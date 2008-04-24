class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.column :name,              :string
      t.column :login,             :string
      t.column :password_hash,     :string
      t.column :password_salt,     :string
      t.column :email_address,     :string
      t.column :admin,             :bool, :default => false
      t.column :created_at,        :datetime
      t.column :updated_at,        :datetime
      t.column :deleted_at,        :datetime
    end
    add_index :accounts, :id
    add_index :accounts, :name
    add_index :accounts, :deleted_at
    Account.create_versioned_table
    
    # Need to refresh column info for this object since `create_versioned_table` added some stuff
    Account.reset_column_information
    
    # Some System Install Defaults
    Account.create(:name => 'admin', :login => 'admin', :password => 'admin', :email_address => 'admin@domain.com', :admin => true)
    
  end

  def self.down
    drop_table :accounts
    Account.drop_versioned_table
  end
end
