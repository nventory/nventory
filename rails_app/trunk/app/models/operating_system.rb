class OperatingSystem < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_many :nodes
  
  validates_presence_of :name

end
