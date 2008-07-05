class VipNote < ActiveRecord::Base
  
  belongs_to :vip
  
  validates_presence_of :vip_id, :note
  
  # vip.name would be cooler
  def self.default_search_attribute
    'vip_id'
  end
 
end
