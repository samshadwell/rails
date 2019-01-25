module ActiveSupport
  module Dependencies
    module ZeitwerkIntegration
      module Decorations
        def clear
          Dependencies.unload_interlock do
            Rails.autoloader.reload
          end
        end

        def constantize(cpath)
          Inflector.constantize(cpath)
        end

        def safe_constantize(cpath)
          Inflector.safe_constantize(cpath)
        end

        def autoloaded_constants
          Rails.autoloaders.flat_map do |autoloader|
            autoloader.loaded.to_a
          end
        end

        def autoloaded?(object)
          cpath = object.is_a?(Module) ? object.name : object.to_s
          Rails.autoloaders.any? { |autoloader| autoloader.loaded?(cpath) }
        end
      end

      class << self
        def take_over
          setup_autoloaders
          freeze_autoload_paths
          decorate_dependencies
        end

        private

          def setup_autoloaders
            Dependencies.autoload_paths.each do |path|
              if File.directory?(path)
                if autoload_once?(path)
                  Rails.once_autoloader.push_dir(path)
                else
                  Rails.autoloader.push_dir(path)
                end
              end
            end

            Rails.autoloaders.each(&:setup)
          end

          def autoload_once?(path)
            Dependencies.autoload_once_paths.include?(path) ||
            Gem.path.any? { |gem_path| path.start_with?(gem_path) }
          end

          def freeze_autoload_paths
            Dependencies.autoload_paths.freeze
            Dependencies.autoload_once_paths.freeze
          end

          def decorate_dependencies
            Dependencies.singleton_class.prepend(Decorations)
            Object.class_eval { alias_method :require_dependency, :require }
          end
      end
    end
  end
end
