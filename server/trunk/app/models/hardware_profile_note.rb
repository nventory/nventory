class HardwareProfileNote < ActiveRecord::Base
  
  belongs_to :hardware_profile
  
  validates_presence_of :hardware_profile_id, :note
  
  def self.default_search_attribute
    'name'
  end
 
end
