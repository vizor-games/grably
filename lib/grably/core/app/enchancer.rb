module Grably
  module Core
    # Wraps top_level method. To hook start/finish
    module ApplicationEnchancer
      class << self
        def included(other_class) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          other_class.class_eval do
            alias_method :old_top, :top_level

            def top_level(*_args)
              puts 'Building profile '.yellow.bright + c.profile.join('/')
              if Grably.export?
                old_top
                export(Grably.export_path)
              else
                measure_time { old_top }
              end
            end
          end
        end
      end

      def export(path)
        return unless path
        save_obj(Grably.export_path, Grably.exports)
      end

      def measure_time
        ts = Time.now
        yield
        te = Time.now
        puts "Total time: #{te - ts} seconds (#{ts} -> #{te})".yellow.bright
      end
    end
  end
end
