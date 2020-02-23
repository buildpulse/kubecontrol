require 'open3'
require_relative 'pod'
require_relative 'deployment'
require_relative 'stateful_set'
require_relative 'service'
require_relative 'secret'

module Kubecontrol
  class Client
    DEFAULT_NAMESPACE = 'default'.freeze

    attr_accessor :namespace

    def initialize(namespace = DEFAULT_NAMESPACE)
      @namespace = namespace
    end

    def apply(file_path: nil, kustomization_dir: nil)
      raise ArgumentError.new('Must pass a file_path or kustomization_dir keyword argument') if (file_path.nil? && kustomization_dir.nil?) || (file_path && kustomization_dir)

      if file_path
        kubectl_command("apply -f #{file_path}")
      else
        kubectl_command("apply -k #{kustomization_dir}")
      end
    end

    def pods
      get_resource(Pod, 5)
    end

    def deployments
      get_resource(Deployment, 5)
    end

    def stateful_sets
      get_resource(StatefulSet, 3)
    end

    def services
      get_resource(Service, 6)
    end

    def secrets
      get_resource(Secret, 4)
    end

    def find_secret_by_name(name_regex)
      secrets.find { |secret| secret.name.match?(name_regex) }
    end

    def find_service_by_name(name_regex)
      services.find { |service| service.name.match?(name_regex) }
    end

    def find_pod_by_name(name_regex)
      pods.find { |pod| pod.name.match?(name_regex) }
    end

    def find_deployment_by_name(name_regex)
      deployments.find { |deployment| deployment.name.match?(name_regex) }
    end

    def find_stateful_set_by_name(name_regex)
      stateful_sets.find { |stateful_set| stateful_set.name.match?(name_regex) }
    end

    def kubectl_command(command)
      stdout_data, stderr_data, status = Open3.capture3("kubectl -n #{namespace} #{command}")
      exit_code = status.exitstatus

      [stdout_data, stderr_data, exit_code]
    end

    private

    def get_resource(klass, number_of_columns)
      get_result, _stderr, _exit_code = kubectl_command("get #{klass::RESOURCE_NAME}")
      return [] if get_result.empty?

      resources_array = get_result.split
      resources_array.shift number_of_columns # remove output table headers
      resources_array.each_slice(number_of_columns).map do |resource_data|
        klass.new(*resource_data, namespace, self)
      end
    end
  end
end
