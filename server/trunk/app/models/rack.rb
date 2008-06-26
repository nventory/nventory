class Rack < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_one :datacenter_rack_assignment, :dependent => :destroy
  
  has_many :rack_node_assignments, :order => "position"
  has_many :nodes, :through => :rack_node_assignments, :conditions => 'rack_node_assignments.deleted_at IS NULL'
  
  validates_presence_of :name
  
  def u_height
    42
  end
  
  def used_u_height
    n = 0
    self.nodes.each do |node|
      n = n + node.hardware_profile.rack_size
    end
    return n
  end
  
  def free_u_height
    self.u_height - self.used_u_height
  end
  
  def datacenter
    if self.datacenter_rack_assignment
     return self.datacenter_rack_assignment.datacenter
    else
      return nil
    end
  end
  
  def before_destroy
    raise "A rack can not be destroyed that has nodes assigned to it." if self.rack_node_assignments.count > 0
  end
  
end
