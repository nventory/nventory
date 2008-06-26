class DatacenterRackAssignment < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  belongs_to :datacenter
  belongs_to :rack 
  
  validates_presence_of :datacenter_id, :rack_id
  validates_uniqueness_of :rack_id
  
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
