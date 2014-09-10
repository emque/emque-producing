require "logger"

module Emque
  module Producing
    class Logging
      def self.initialize_logger(log_target = STDOUT)
        @logger = Logger.new(log_target)
        @logger.level = Logger::INFO
        @logger
      end

      def self.logger
        defined?(@logger) ? @logger : initialize_logger
      end

      def self.logger=(log)
        @logger = log || Logger.new("/dev/null")
      end

      def logger
        Emque::Producing::Logging.logger
      end
    end
  end
end
