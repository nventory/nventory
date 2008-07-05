class DatacenterEnvironmentAssignment < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :datacenter
  belongs_to :environment 
  
  validates_presence_of :datacenter_id, :environment_id
  validates_uniqueness_of :environment_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end

end
