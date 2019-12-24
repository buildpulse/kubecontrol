module Kubecontrol
  class Pod
    RUNNING = 'Running'.freeze

    attr_reader :name, :ready, :status, :restarts, :age, :namespace, :client

    def initialize(name, ready, status, restarts, age, namespace:, client:)
      @name = name
      @ready = ready
      @status = status
      @restarts = restarts
      @age = age
      @namespace = namespace
      @client = client
    end

    def stopped?
      @status != RUNNING
    end

    def running?
      @status == RUNNING
    end

    def exec(command)
      stdout_data, stderr_data, exit_code = @client.kubectl_command("exec -i #{name} -- sh -c \"#{command.gsub('"', '\"')}\"")
      [stdout_data, stderr_data, exit_code]
    end
  end
end
