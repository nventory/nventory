xml.instruct! :xml, :version=>"1.0"
xml.environment(:name => @environment.name) do
  xml.customers do
    @environment.programs.each do |program|
    xml.customers(:name => program.customer.name, :program => program.name)
    end
  end
  xml.servers do
    FunctionType.find(:all, :order => 'name').each do |function_type|
      xml.tag!(function_type.gsub(/ /, '').tableize) do
        Node.find(:all).each do |node|
          node.functions.each do |function|
            xml.tag!(function_type.gsub(/ /, '').tableize.singularize, :name => node.name) if function.function_type == function_type
          end
        end
      end
    end
  end
end