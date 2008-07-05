class Program < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :customer
  belongs_to :status
  
  has_many :environment_program_assignments, :dependent => :destroy
  has_many :environments, :through => :environment_program_assignments, :conditions => 'environment_program_assignments.deleted_at IS NULL'

  validates_presence_of :name, :customer_id, :status_id
  
  def self.all_programs_ordered_by_customer_name_program_name
    Program.find(:all).sort_by { |p| p.customer.name + p.name }
  end
  
  def self.default_search_attribute
    'name'
  end
 
end
