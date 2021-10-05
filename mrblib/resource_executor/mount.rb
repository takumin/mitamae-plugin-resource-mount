module ::MItamae
  module Plugin
    module ResourceExecutor
      class Mount < ::MItamae::ResourceExecutor::Base
        def apply
          MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] desired: '#{desired.sort}'"
          MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] current: '#{current.sort}'"

          if desired.action == :present && current.action == :present
            diff_desired = desired.select{|k,v| k.to_s.match(/^(?:device|point|type)$/)}
            diff_current = current.select{|k,v| k.to_s.match(/^(?:device|point|type)$/)}

            unless diff_desired == diff_current
              umount
              mount
            end
          elsif desired.action == :present && current.action == :absent
            mount
          elsif desired.action == :absent && current.action == :present
            umount
          elsif desired.action == :absent && current.action == :absent
            # nothing...
          end
        end

        private

        def set_current_attributes(current, action)
          mounts = parse(File.read('/proc/mounts')).select do |m|
            m[:point] === attributes['point']
          end

          if mounts.length >= 1
            current.action = :present
            current.device = mounts[0][:device]
            current.point  = mounts[0][:point]
            current.type   = mounts[0][:type]
          else
            current.action = :absent
          end
        end

        def set_desired_attributes(desired, action)
          # nothing...
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

        def mount
          if !Dir.exist?(desired.point)
            raise "not found mount directory: #{desired.point}"
          end

          command = ['mount', '-f']

          if !desired.type.nil? and !desired.type.empty?
            command << '-t'
            command << desired.type
          end

          if !desired.options.nil? and !desired.options.empty?
            command << '-o'
            command << desired.options.join(',')
          end

          command << desired.device
          command << desired.point

          fake_mount = run_command(command.join(' '), error: false)

          unless fake_mount.success?
            raise "failed fake mount: '#{command.join(' ')}'"
          end

          mount = run_command(command.reject{|v| v == '-f'}.join(' '))

          unless mount.success?
            raise "failed mount: '#{command.join(' ')}'"
          end
        end

        def umount
          command = ['umount']

          if desired.force
            command << '-f'
          end

          if desired.lazy
            command << '-l'
          end

          command << desired.point

          umount = run_command(command.join(' '), error: false)

          unless umount.success?
            raise "failed umount: '#{command.join(' ')}'"
          end
        end
      end
    end
  end
end
