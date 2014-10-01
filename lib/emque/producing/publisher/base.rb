module Emque
  module Producing
    module Publisher
      class Base
        def host_name
          Socket.gethostbyname(Socket.gethostname).first
        end

        def handle_error(e)
          Emque::Producing.configuration.error_handlers.each do |handler|
            begin
              handler.call(e, nil)
            rescue => ex
              Emque::Producing.logger.error "Producer error hander raised an error"
              Emque::Producing.logger.error ex
              Emque::Producing.logger.error Array(ex.backtrace).join("\n")
            end
          end
        end
      end
    end
  end
end
