class SubnetNote < ActiveRecord::Base
  
  belongs_to :subnet
  
  validates_presence_of :subnet_id, :note
  
  # subnet.network would be cooler
  def self.default_search_attribute
    'subnet_id'
  end
 
end
