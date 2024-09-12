require 'open3'
require_relative 'resources'

module Kubecontrol
  class Client
    DEFAULT_NAMESPACE = 'default'.freeze

    attr_accessor :namespace

    def initialize(kubeconfig_path, binary='kubectl', namespace = DEFAULT_NAMESPACE)
      @binary = binary
      @kubeconfig_path = kubeconfig_path
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
      get_resource(Resources::Pod, 5)
    end

    def deployments
      get_resource(Resources::Deployment, 5)
    end

    def stateful_sets
      get_resource(Resources::StatefulSet, 3)
    end

    def services
      get_resource(Resources::Service, 6)
    end

    def secrets
      get_resource(Resources::Secret, 4)
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

    def kubectl_command_dry(command, include_namespace = true)
      namespace_option = include_namespace ? "--namespace '#{@namespace}'" : ''
      "#{@binary} --kubeconfig '#{@kubeconfig_path}' #{namespace_option} #{command}"
    end

    def kubectl_command(command, include_namespace = true, print_cmd = true)
      namespace_option = include_namespace ? "--namespace '#{@namespace}'" : ''
      cmd = "#{@binary} --kubeconfig '#{@kubeconfig_path}' #{namespace_option} #{command}"
      puts cmd if print_cmd
      stdout_data, stderr_data, status = Open3.capture3(cmd)
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
