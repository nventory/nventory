class DatabaseInstance < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_one :node_database_instance_assignment, :dependent => :destroy
  
  validates_presence_of :name
  
end
