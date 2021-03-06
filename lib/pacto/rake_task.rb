require 'pacto'

unless String.respond_to?(:colors)
  class String
    def colorize(*args)
      self
    end
  end
end

module Pacto
  class RakeTask
    include Rake::DSL

    def initialize
      @exit_with_error = false
    end

    def install
      desc "Tasks for Pacto gem"
      namespace :pacto do
        validate_task
      end
    end

    def validate_task
      desc "Validates all contracts in a given directory against a given host"
      task :validate, :host, :dir do |t, args|
        if args.to_a.size < 2
          fail "USAGE: rake pacto:validate[<host>, <contract_dir>]".colorize(:yellow)
        end

        validate_contracts(args[:host], args[:dir])
      end
    end

    def validate_contracts(host, dir)
      WebMock.allow_net_connect!

      contracts = Dir[File.join(dir, '*{.json.erb,.json}')]
      if contracts.empty?
        fail "No contracts found in directory #{dir}".colorize(:yellow)
      end

      puts "Validating contracts in directory #{dir} against host #{host}\n\n"

      total_failed = 0
      contracts.sort.each do |contract_file|
        print "#{contract_file.split('/').last}:"
        contract = Pacto.build_from_file(contract_file, host)
        errors = contract.validate

        if errors.empty?
          puts " OK!".colorize(:green)
        else
          @exit_with_error = true
          total_failed += 1
          puts " FAILED!".colorize(:red)
          errors.each do |error|
            puts "\t* #{error}".colorize(:light_red)
          end
          puts ""
        end
      end

      if @exit_with_error
        fail "#{total_failed} of #{contracts.size} failed. Check output for detailed error messages.".colorize(:red)
      else
        puts "#{contracts.size} valid contract#{contracts.size > 1 ? 's' : nil}".colorize(:green)
      end
    end
  end
end

Pacto::RakeTask.new.install
