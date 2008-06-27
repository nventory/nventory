class AddRelevantModelToStatusObject < ActiveRecord::Migration
  def self.up
    # add a column to status that will use to limit what status can be applied to which models
    add_column "statuses", "relevant_model", :string
    add_column "status_versions", "relevant_model", :string
    
    # Need to refresh column info for this object since `create_versioned_table` added some stuff
    Status.reset_column_information
    
    # Some System Install Defaults
    s1 = Status.new
    s1.name = 'Active'
    s1.relevant_model = 'Node'
    s1.notes = 'In use.'
    s1.save
    s2 = Status.new
    s2.name = 'Available'
    s2.relevant_model = 'Node'
    s2.notes = 'Ready to use.'
    s2.save
    s3 = Status.new
    s3.name = 'Broken'
    s3.relevant_model = 'Node'
    s3.notes = 'Not in use, needs repair.'
    s3.save
    
    s4 = Status.new
    s4.name = 'Running'
    s4.relevant_model = 'Program'
    s4.notes = 'This program is running.'
    s4.save
    
    s5 = Status.new
    s5.name = 'Down'
    s5.relevant_model = 'Program'
    s5.notes = 'This program is not running.'
    s5.save
    
  end

  def self.down
    remove_column "statuses", "relevant_model"
    remove_column "status_versions", "relevant_model"
  end
end
