class Datacenter < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_many :datacenter_rack_assignments
  has_many :racks, :through => :datacenter_rack_assignments, :conditions => 'datacenter_rack_assignments.deleted_at IS NULL'
  
  has_many :datacenter_environment_assignments
  has_many :environments, :through => :datacenter_environment_assignments, :conditions => 'datacenter_environment_assignments.deleted_at IS NULL'
  
  validates_presence_of :name
  
  def before_destroy
    raise "A datacenter can not be destroyed that has racks assigned to it." if self.datacenter_rack_assignments.count > 0
    raise "A datacenter can not be destroyed that has environments assigned to it." if self.datacenter_environment_assignments.count > 0
  end
  
end
