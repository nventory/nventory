class Function < ActiveRecord::Base
  
  acts_as_paranoid
  
  has_many :node_function_assignments
  has_many :nodes, :through => :node_function_assignments, :conditions => 'node_function_assignments.deleted_at IS NULL'
  
  belongs_to :function_type
  
  validates_presence_of :name, :function_type_id
  validates_uniqueness_of :name
  
  def self.default_search_attribute
    'name'
  end
 
  def before_destroy
    raise "A function can not be destroyed that has nodes assigned to it." if self.node_function_assignments.count > 0
  end
  
end
