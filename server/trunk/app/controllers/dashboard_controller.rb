class DashboardController < ApplicationController

  def index
    @function_type_counts = Hash.new
    Node.find(:all).each do |n|
      n.functions.each do |f|
        if @function_type_counts[f.function_type].nil?
          @function_type_counts[f.function_type] = 1
        else
          @function_type_counts[f.function_type] = @function_type_counts[f.function_type] + 1
        end
      end
    end
  end
  
  def setup_sample_data
    if Datacenter.find(:all).length < 1
      
      # Some System Install Defaults
      hp1 = HardwareProfile.new
      hp1.name = 'SunFireX4100'
      hp1.manufacturer = 'Sun MicroSystems'
      hp1.rack_size = 1
      hp1.memory = '1GB'
      hp1.disk = '80GB'
      hp1.nics = 3
      hp1.processor_type = 'Opteron'
      hp1.processor_speed = '3GHZ'
      hp1.processor_count = 1
      hp1.cards = ''
      hp1.notes = 'Test Node Type'
      hp1.save
      
      # Some System Install Defaults
      hp2 = HardwareProfile.new
      hp2.name = 'PowerEdge1950'
      hp2.manufacturer = 'Dell'
      hp2.rack_size = 1
      hp2.memory = '1GB'
      hp2.disk = '80GB'
      hp2.nics = 3
      hp2.processor_type = 'Opteron'
      hp2.processor_speed = '3GHZ'
      hp2.processor_count = 1
      hp2.cards = ''
      hp2.notes = 'Test Node Type 2'
      hp2.save
      
      ft_web = FunctionType.create(:name => 'Web Server')
      ft_file = FunctionType.create(:name => 'File Server')
      ft_firewall = FunctionType.create(:name => 'Firewall')
      ft_dbserver = FunctionType.create(:name => 'Database Server', :enables_database_instance_access => true)
      ft_pdu = FunctionType.create(:name => 'PDU')
      ft_switch = FunctionType.create(:name => 'Network Switch')

      f1 = Function.new(:name => 'Apache Web Server', :function_type => ft_web, :notes => 'Web Server')
      f1.save
      f11 = Function.new(:name => 'lighttpd Web Server', :function_type => ft_web, :notes => 'Web Server')
      f11.save
      f4 = Function.new(:name => 'Primary Firewall', :function_type => ft_firewall, :notes => 'Security Server')
      f4.save
      f5 = Function.new(:name => 'MySQL Master DB Server', :function_type => ft_dbserver, :notes => 'Database Server')
      f5.save
      f6 = Function.new(:name => 'PDU', :function_type => ft_pdu, :notes => 'Power Distribution Unit')
      f6.save
      f7 = Function.new(:name => 'Primary Network Switch', :function_type => ft_switch, :notes => 'Network Switch')
      f7.save

      # Set the color and U height of PDU
      sunny = HardwareProfile.find_by_name('SunFireX4100')
      sunny.visualization_color = 'purple'
      sunny.rack_size = 2
      sunny.estimated_cost = 8561
      sunny.save
      
    
      ny = Datacenter.new
      ny.name = "New York"
      ny.save
      
      hardware_profiles = HardwareProfile.find(:all)
      
      node_count = 0
      
      rack = Rack.new(:name => "NY-Rack 001")
      rack.save
      dra = DatacenterRackAssignment.new(:datacenter => ny, :rack => rack)
      dra.save
      
      (1..42).to_a.each { |i|
        node_count = node_count + 1
        node = Node.new(:name => "cc" + node_count.to_s)
        status = Status.find_by_name('Active')
        node.status = status
        node.serial_number = rand(999999)
        node.ipaddresses = rand(255).to_s + '.' + rand(255).to_s + '.' + rand(255).to_s + '.' + rand(255).to_s
        node.hardware_profile = HardwareProfile.find_by_name('SunFireX4100')
        node.operating_system = OperatingSystem.find(:first)
        node.save
        rna = RackNodeAssignment.new(:rack => rack, :node => node)
        rna.save
      }      
      
      (2..9).to_a.each { |n|
        rack = Rack.new(:name => "NY-Rack 00"+n.to_s)
        rack.save
        dra = DatacenterRackAssignment.new(:datacenter => ny, :rack => rack)
        dra.save
        
        (1..9).to_a.each { |i|
          node_count = node_count + 1
          node = Node.new(:name => "host" + node_count.to_s)
          status = Status.find_by_name('Active')
          node.status = status
          node.serial_number = rand(999999)
          node.ipaddresses = rand(255).to_s + '.' + rand(255).to_s + '.' + rand(255).to_s + '.' + rand(255).to_s
          node.hardware_profile = hardware_profiles[rand(hardware_profiles.length)]
          node.operating_system = OperatingSystem.find(:first)
          node.save
          rna = RackNodeAssignment.new(:rack => rack, :node => node)
          rna.save
        }
        
      }
      
      # Create some customers
      apple = Customer.create(:name => 'Apple')
      google = Customer.create(:name => 'Google')
      
      running = Status.find_by_name('Running')
      
      apple_quicktime_trailers = Program.create(:name => 'QuickTime Trailers', :customer => apple, :status => running)
      apple_developer_training = Program.create(:name => 'ADC Training', :customer => apple, :status => running)
      apple_wwdc_2006_archive = Program.create(:name => 'WWDC 2006 Archive', :customer => apple, :status => running)
      
      google_you_tube = Program.create(:name => 'YouTube', :customer => google, :status => running)
      google_google_video = Program.create(:name => 'Google Video', :customer => google, :status => running)
      google_you_tube = Program.create(:name => 'YouTube', :customer => google, :status => running)

      env1 = Environment.create(:name => 'env1')
      EnvironmentProgramAssignment.create(:environment => env1, :program => apple_quicktime_trailers)
      EnvironmentProgramAssignment.create(:environment => env1, :program => apple_developer_training)
      EnvironmentProgramAssignment.create(:environment => env1, :program => apple_wwdc_2006_archive)
      
      (1..9).to_a.each { |i|
        node = Node.find_by_name('host'+i.to_s)
        EnvironmentNodeAssignment.create(:environment => env1, :node => node)
      }
      

    end
  end

end
