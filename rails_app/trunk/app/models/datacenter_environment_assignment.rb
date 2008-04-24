class DatacenterEnvironmentAssignment < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  belongs_to :datacenter
  belongs_to :environment 
  
  validates_presence_of :datacenter_id, :environment_id
  validates_uniqueness_of :environment_id
  
  def before_create 
    self.assigned_at ||= Time.now 
  end

end
