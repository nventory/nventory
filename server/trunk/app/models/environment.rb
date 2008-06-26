class Environment < ActiveRecord::Base
  
  acts_as_paranoid_versioned
  
  has_one :datacenter_environment_assignment, :dependent => :destroy
  
  has_many :environment_program_assignments, :dependent => :destroy
  has_many :programs, :through => :environment_program_assignments, :conditions => 'environment_program_assignments.deleted_at IS NULL'
  
  has_many :environment_node_assignments, :dependent => :destroy
  has_many :nodes, :through => :environment_node_assignments, :conditions => 'environment_node_assignments.deleted_at IS NULL'
  
  validates_presence_of :name
  
  def customers
    customer_list = []
    self.programs.each { |p|
      customer_list << p.customer
    }
    customer_list.uniq
  end
  
  def estimated_investment
    investment = 0
    self.nodes.each { |node|
      investment = investment + node.hardware_profile.estimated_cost
    }
    return investment
  end
  
  def count_for_function_type(type)
    count = 0
    self.nodes.each do |n|
      n.functions.each do |f|
        if f.function_type == type
          count = count + 1
        end
      end
    end
    return count
  end
  
end
