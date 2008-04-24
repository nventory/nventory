class Node < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_one :rack_node_assignment, :dependent => :destroy
  
  has_many :environment_node_assignments, :dependent => :destroy
  has_many :environments, :through => :environment_node_assignments, :conditions => 'environment_node_assignments.deleted_at IS NULL'

  belongs_to :hardware_profile
  belongs_to :operating_system
  belongs_to :status
  
  has_many :node_function_assignments, :dependent => :destroy
  has_many :functions, :through => :node_function_assignments, :conditions => 'node_function_assignments.deleted_at IS NULL'
  
  has_many :node_database_instance_assignments
  has_many :database_instances, :through => :node_database_instance_assignments, :conditions => 'node_database_instance_assignments.deleted_at IS NULL'
  
  has_many :produced_outlets, :class_name => "Outlet", :foreign_key => "producer_id", :order => "name"
  has_many :consumed_outlets, :class_name => "Outlet", :foreign_key => "consumer_id", :order => "name"

  validates_presence_of :name, :hardware_profile_id, :status_id
  
  validates_uniqueness_of :name
  
  after_save :update_outlets
  
  def consumed_network_outlets
    network_outlets = []
    self.consumed_outlets.each { |outlet| network_outlets << outlet if outlet.producer.hardware_profile.outlet_type == "Network" }
    return network_outlets
  end
  
  def consumed_power_outlets
    network_outlets = []
    self.consumed_outlets.each { |outlet| network_outlets << outlet if outlet.producer.hardware_profile.outlet_type == "Power" }
    return network_outlets
  end
  
  def is_database_server?
    answer = false
    self.functions.each { |f| answer = true if f.function_type.enables_database_instance_access?}
    return answer
  end
  
  def visualization_summary
    # This is the text we'll show in a node box when we visualize a rack
    delimiter = ' | '
    function_names = []
    self.functions.each { |f| function_names << f.name }
    if function_names.include?("PDU") or function_names.include?("Network Switch")
      # PDUs and switches should display: name, IP, hwprofile, # of total outlets, free outlets
      active_outlet_count = 0
      self.outlets.each { |o|
        active_outlet_count = active_outlet_count + 1 unless o.consumer.nil?
      }
      return self.name + delimiter + ipaddresses_as_string_list + delimiter + self.hardware_profile.name + delimiter + active_outlet_count.to_s + '/' + self.hardware_profile.outlet_count.to_s
    else
      return self.name + delimiter + ipaddresses_as_string_list + delimiter + self.hardware_profile.name + delimiter + self.functions_as_string_list + delimiter + environments_as_string_list
    end
  end
  
  def ipaddresses_as_string_list
    self.ipaddresses_as_array * ', '
  end
  
  def ipaddresses_as_array
    # Currently ipaddresses as stored in a text field and we tell users to put each address on it's own line
    # This method will filter that string and return the list as an array
    array_list = []
    if !self.ipaddresses.nil?
      self.ipaddresses.each_line { |line| array_list << line.strip }
    end
    return array_list
  end
  
  def functions_as_string_list
    function_names = []
    self.functions.each { |f| function_names << f.name }
    function_names * ', '
  end
  
  def environments_as_string_list
    env_names = []
    self.environment_node_assignments.each { |e| env_names << e.environment.name }
    env_names * ', '
  end
  
  def update_outlets
    # this method will look at our hardware profile and make sure we have the correcnt number of outlets realized in the database.
    if self.hardware_profile.outlet_count > 0 and self.produced_outlets.length != self.hardware_profile.outlet_count
      if self.produced_outlets.length < self.hardware_profile.outlet_count
        # We need to add outlets
        how_many_to_add = self.hardware_profile.outlet_count - self.produced_outlets.length
        how_many_to_add.times { self.add_new_outlet }
      else
        # We need to remove outlets
        how_many_to_remove = self.produced_outlets.length - self.hardware_profile.outlet_count
        how_many_to_remove.times { self.remove_bottom_outlet }
      end
    end
  end
  
  def add_new_outlet
    # Find out how many outlets we currently have
    count = self.produced_outlets(true).length + 1
    o = Outlet.new
    o.name = count.to_s
    o.producer = self
    o.save
  end
  
  def remove_bottom_outlet
    self.produced_outlets.last.destroy
  end
  
  def before_destroy
    raise "A node can not be destroyed that has database instances assigned to it." if self.node_database_instance_assignments.count > 0
  end
  
end
