module ::MItamae
  module Plugin
    module ResourceExecutor
      class Mount < ::MItamae::ResourceExecutor::Base
        def apply
          entry = [desired.device, desired.point]

          if !desired.type.nil? and !desired.type.empty?
            entry << desired.type
          end

          if !desired.options.nil? and !desired.options.empty?
            entry << desired.options
          end

          if !desired.dump.nil? and desired.dump != 0
            entry << desired.dump
          end

          if !desired.pass.nil? and desired.pass != 0
            entry << desired.pass
          end

          entry = entry.join(' ')

          if desired.mount && current.mount
            # nothing...
          elsif desired.mount && !current.mount
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] entry: '#{entry}'"
            mount(desired)
          elsif !desired.mount && current.mount
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] entry: '#{entry}'"
            unmount(desired)
          elsif !desired.mount && !current.mount
            # nothing...
          end
        end

        private

        def set_current_attributes(current, action)
          mounts = parse(File.read('/proc/mounts'))

          points = mounts.map do |m|
            m[:point]
          end

          current.mount = points.include?(desired.point)
        end

        def set_desired_attributes(desired, action)
          case action
          when :present
            desired.mount = true
          when :absent
            desired.mount = false
          end
        end

        def parse(lines)
          mounts = []
          lines.each_line do |line|
            if line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)$/
              mount = {}
              mount[:device] = $1
              mount[:point] = $2
              mount[:type] = $3
              mount[:options] = $4.split(',')
              mount[:dump] = $5.to_i
              mount[:pass] = $6.to_i
              mounts << mount
            end
          end
          mounts
        end

        def mount(entry)
          if !Dir.exist?(entry.point)
            MItamae.logger.error "not found mount directory: #{entry.point}"
            exit 1
          end

          command = ['mount', '-f']

          if !entry.type.nil? and !entry.type.empty?
            command << '-t'
            command << entry.type
          end

          if !entry.options.nil? and !entry.options.empty?
            command << '-o'
            command << entry.options.join(',')
          end

          command << entry.device
          command << entry.point

          result = run_command(command.join(' '), error: false)

          if result.success?
            result = run_command(command.reject{|v| v == '-f'}.join(' '))

            if !result.success?
              MItamae.logger.error "failed mount: #{entry.device} -> #{entry.point}"
              exit 1
            end
          else
            MItamae.logger.error "failed fake mount: #{entry.device} -> #{entry.point}"
            exit 1
          end
        end

        def unmount(entry)
          result = run_command(['umount',entry.point].join(' '), error: false)

          if !result.success?
            MItamae.logger.error "failed umount: #{entry.point}"
            exit 1
          end
        end
      end
    end
  end
end
