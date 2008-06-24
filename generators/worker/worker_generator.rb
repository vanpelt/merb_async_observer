class WorkerGenerator < Merb::GeneratorBase
  attr_reader :worker
   
  def initialize(args, runtime_args = {})
    super
    @worker = args[0]
  end
  
  def manifest
    record do |m|
      m.file "#{worker}.rb", File.join('lib', "worker.rb"), { :chmod => 0755 }
    end
  end
  
  protected
  def banner
    <<-EOS.split("\n").map{|x| x.strip}.join("\n")
      Creates a worker script

      USAGE: #{spec.name}"
    EOS
  end
      
end