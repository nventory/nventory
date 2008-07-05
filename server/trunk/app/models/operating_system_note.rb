class OperatingSystemNote < ActiveRecord::Base
  
  belongs_to :operating_system
  
  validates_presence_of :operating_system_id, :note
  
  # operating_system.name would be cooler
  def self.default_search_attribute
    'operating_system_id'
  end
 
end
