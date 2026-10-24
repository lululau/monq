# frozen_string_literal: true

require "optparse"
require "ostruct"

module Monq
  class Cli
    CONNECTION_KEYS = %i[uri host port database username password auth_source].freeze

    class << self
      def start
        App.new(parse!(ARGV)).run!
      end

      def parse!(argv)
        options = OpenStruct.new(babel_compatable: false, ssh: {})

        parser = OptionParser.new do |opts|
          opts.banner = <<~BANNER
            Usage: monq [options] [ruby file]

              If neither [ruby file] nor -E is given, and STDIN is a tty, a Pry REPL is launched.
              Otherwise the ruby file, -E code, or STDIN is evaluated and no REPL is started.
          BANNER

          opts.on("-cCONFIG_FILE", "--conf=CONFIG_FILE", "Specify config file") do |config_file|
            options.config_file = config_file
          end

          opts.on("-iINITIALIZER", "--initializer=INITIALIZER", "Specify initializer ruby file") do |initializer|
            options.initializer = initializer
          end

          opts.on("-eENVIRON", "--env=ENVIRON", "Environments, separated by comma, plus, or colon") do |env_names|
            options.environments = env_names.split(/[,\+:]/).reject(&:empty?)
          end

          opts.on("-ECODE", "--eval=CODE", "Evaluate CODE") do |code|
            options.code = code
          end

          opts.on("-b", "--babel", "Enable compatibility for Org-Mode Babel") do
            options.babel_compatable = true
          end

          opts.on("-S", "--show-sql", "Show Mongo commands on STDOUT") do
            options.show_sql = true
          end

          opts.on("-wOUTPUT", "--write-sql=OUTPUT", "Write Mongo commands to OUTPUT") do |file|
            options.write_sql = file
          end

          opts.on("-AOUTPUT", "--append-sql=OUTPUT", "Append Mongo commands to OUTPUT") do |file|
            options.append_sql = file
          end

          opts.on("--uri=URI", "MongoDB connection URI") do |uri|
            options.uri = uri
          end

          opts.on("--db-host=HOST", "Database host") do |host|
            options.host = host
          end

          opts.on("--db-port=PORT", "Database port") do |port|
            options.port = port.to_i
          end

          opts.on("--db-name=NAME", "Database name") do |name|
            options.database = name
          end

          opts.on("--db-user=USER", "Database user") do |user|
            options.username = user
          end

          opts.on("--db-password=PASSWORD", "Database password") do |password|
            options.password = password
          end

          opts.on("--auth-source=SOURCE", "Authentication database") do |source|
            options.auth_source = source
          end

          opts.on("--ssh-host=HOST", "SSH jump host") do |host|
            options.ssh[:host] = host
          end

          opts.on("--ssh-port=PORT", "SSH port") do |port|
            options.ssh[:port] = port.to_i
          end

          opts.on("--ssh-user=USER", "SSH user") do |user|
            options.ssh[:user] = user
          end

          opts.on("--ssh-password=PASSWORD", "SSH password") do |password|
            options.ssh[:password] = password
          end

          opts.on("--ssh-local-port=PORT", "Local forwarded port") do |port|
            options.ssh[:local_port] = port.to_i
          end

          opts.on("-V", "--version", "Prints version") do
            puts "Monq #{Monq::VERSION}"
            exit
          end

          opts.on("--help", "Prints this help") do
            puts opts
            exit
          end
        end

        remaining = argv.dup
        parser.parse!(remaining)
        options.args = remaining
        reject_multi_env_connection!(options)
        options
      end

      private

      def reject_multi_env_connection!(options)
        return unless options.environments&.size.to_i > 1
        return unless connection_flag?(options)

        raise Error, "Connection CLI flags are not allowed with multiple -e environments"
      end

      def connection_flag?(options)
        CONNECTION_KEYS.any? do |key|
          value = options.public_send(key)
          value && !(value.respond_to?(:empty?) && value.empty?)
        end || (options.ssh && !options.ssh.empty?)
      end
    end
  end
end
