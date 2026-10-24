# frozen_string_literal: true

module Kernel
  def models
    Monq::App.instance.environments.flat_map { |env| env.models }
  rescue StandardError
    []
  end

  def model_names
    models.map(&:name)
  end

  def within_namespace(pattern, &block)
    if pattern.is_a?(Module)
      pattern.module_eval(&block)
      return
    end

    env = find_environment { |candidate| name_matches?(candidate.namespace, pattern) }
    unless env
      $stderr.puts "Namespace #{pattern.inspect} not found"
      return
    end

    env.namespace_module.module_eval(&block)
  end

  def within_env(pattern, &block)
    env = find_environment { |candidate| name_matches?(candidate.name, pattern) }
    unless env
      $stderr.puts "Environment #{pattern.inspect} not found"
      return
    end

    env.namespace_module.module_eval(&block)
  end

  def env_config(regexp)
    env = find_environment { |candidate| candidate.name.to_s =~ regexp }
    env&.config
  end

  def q(doc)
    environments = Monq::App.instance.environments
    if environments.size != 1
      $stderr.puts "use Namespace.q"
      return nil
    end

    environments.first.client.database.command(doc)
  end

  private

  def find_environment(&block)
    Monq::App.instance.environments.find(&block)
  end

  def name_matches?(value, pattern)
    case pattern
    when Symbol, String
      value.to_s == pattern.to_s
    when Regexp
      value.to_s =~ pattern
    else
      false
    end
  end
end
