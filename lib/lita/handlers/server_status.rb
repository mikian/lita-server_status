module Lita
  module Handlers
    class ServerStatus < Handler
      def self.default_config(config)
        config.regex = /(.+) is starting deploy of '(.+)' from branch '(.+)' to (.+)/i
      end

      # route(Lita.config.handlers.server_status.regex, :save_status)
      route(/server status/i, :list_statuses, command: true,
            help: { "server status" => "List out the current server statuses." }
      )

      def initialize(robot)
        super

        # Define dynamically our route
        class << self
          route(config.regex, :save_status)
        end
      end

      def save_status(response)
        message = response.message.body
        user, application, branch, environment = message.match(MESSAGE_REGEX).captures
        Lita.logger.debug "#{application} #{environment}: #{branch} (#{user} @ #{formatted_time})"

        apply_status = { id: "#{application}:#{environment}",
                         message: "#{application} #{environment}: #{branch} (#{user} @ #{formatted_time})" }

        redis.set("server_status:#{apply_status[:id]}", apply_status[:message])
      end

      def list_statuses(response)
        response.reply status_message
      end

      def status_message
        messages = redis.keys("server_status*").sort.map { |key| redis.get(key) }
        messages << "I don't know what state the servers are in." if messages.empty?
        messages.join("\n")
      end

      def formatted_time
        Time.now.strftime("%Y-%m-%d %H:%M")
      end
    end

    Lita.register_handler(ServerStatus)
  end
end
