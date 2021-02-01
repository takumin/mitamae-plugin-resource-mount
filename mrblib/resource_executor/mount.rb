module ::MItamae
  module Plugin
    module ResourceExecutor
      class Mount < ::MItamae::ResourceExecutor::Base
        def apply
          MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] desired: '#{desired.sort}'"
          MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] current: '#{current.sort}'"

          if desired.mount && current.mount
            diff_desired = desired.select{|k,v| k.to_s.match(/^(?:device|point|type)$/)}
            diff_current = current.select{|k,v| k.to_s.match(/^(?:device|point|type)$/)}

            unless diff_desired == diff_current
              umount
              mount
            end
          elsif desired.mount && !current.mount
            mount
          elsif !desired.mount && current.mount
            umount
          elsif !desired.mount && !current.mount
            # nothing...
          end
        end

        private

        def set_current_attributes(current, action)
          mounts = parse(File.read('/proc/mounts')).select do |m|
            m[:point] === attributes['point']
          end

          case mounts.length
          when 1
            current.action = :present
            current.device = mounts[0][:device]
            current.point  = mounts[0][:point]
            current.type   = mounts[0][:type]
          when 0
            current.action = :absent
          else
            raise "there are multiple mount targets: #{attributes['point']}"
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

          if fake_mount.success?
            mount = run_command(command.reject{|v| v == '-f'}.join(' '))

            if !mount.success?
              raise "failed mount: #{desired.device} -> #{desired.point}"
            end
          else
            raise "failed fake mount: #{desired.device} -> #{desired.point}"
          end
        end

        def umount
          umount = run_command(['umount',desired.point].join(' '), error: false)

          if !umount.success?
            raise "failed umount: #{desired.point}"
          end
        end
      end
    end
  end
end
