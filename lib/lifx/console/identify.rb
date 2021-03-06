require 'abbrev'

module LIFX
  class Console
    class Identify
      COLORS = {
        'red' => LIFX::Color.red.with_brightness(0.7),
        'green' => LIFX::Color.green.with_brightness(0.7),
        'blue' => LIFX::Color.blue.with_brightness(0.7),
        'yellow' => LIFX::Color.yellow.with_brightness(0.7),
        'purple' => LIFX::Color.purple.with_brightness(0.7),
      }

      def run(lights)
        candidates = lights.to_a.shuffle
        mapping = {}

        if lights.respond_to?(:set_color)
          lights.set_color(LIFX::Color.white, duration: 0)
        else
          lights.each { |l| l.set_color(LIFX::Color.white, duration: 0) }
        end

        while candidates.count > 1
          puts "Searching through #{candidates.count} devices..."
          partitions = partition(candidates, COLORS.values.count)
            COLORS.keys.each_with_index do |color_name, index|
              color = COLORS[color_name]
              mapping[color_name] = partitions[index]
              next if partitions[index].nil?
              partitions[index].each do |l|
                l.pulse(color, period: 10, duty_cycle: 1.0)
              end
            end
          puts "What color did the light change to? (#{COLORS.keys.join(', ')}. Press enter to retry)"
          resp = gets.strip
          abbrev = Abbrev.abbrev(COLORS.keys)
          if mapping.has_key?(abbrev[resp])
            candidates = mapping[abbrev[resp]]
          else
            puts "Color not found. Pulsing again."
          end
        end

        if candidates.count == 1
          result = candidates.first
          puts "Light identified: #{result}"
          result.pulse(LIFX::Color.green, cycles: 3, period: 1)
          return candidates.first
        else
          puts "No lights matched."
        end
      end

      def partition(list, partition_count)
        [].tap do |array|
          list.each_slice((list.count.to_f / partition_count).ceil) do |chunk|
            array << chunk
          end
        end
      end

      def client
        LIFX::Console.client
      end
    end

    Pry::Commands.create_command "identify", keep_retval: true, use_shellwords: false do
      description "identify a light visually: identify [Array, LightCollection]"

      def process
        Identify.new.run(lights)
      end

      def lights
        arg_string.length > 0 ? target.eval(arg_string) : target.eval('lights')
      end
    end
  end
end
