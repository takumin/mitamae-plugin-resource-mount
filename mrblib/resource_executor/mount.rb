module ::MItamae
  module Plugin
    module ResourceExecutor
      class Mount < ::MItamae::ResourceExecutor::Base
        def apply
          if desired.exist && current.exist
            # nothing...
          elsif desired.exist && !current.exist
            MItamae.logger.debug "mount: '#{desired.device} #{desired.point} #{desired.type} #{desired.options.join(',')} #{desired.dump} #{desired.pass}'"
          elsif !desired.exist && current.exist
            MItamae.logger.debug "unmount: '#{desired.device} #{desired.point} #{desired.type} #{desired.options.join(',')} #{desired.dump} #{desired.pass}'"
          elsif !desired.exist && !current.exist
            # nothing...
          end

          if desired.fstab && current.fstab
            # nothing...
          elsif desired.fstab && !current.fstab
            MItamae.logger.debug "fstab append: '#{desired.device} #{desired.point} #{desired.type} #{desired.options.join(',')} #{desired.dump} #{desired.pass}'"
          elsif !desired.fstab && current.fstab
            MItamae.logger.debug "fstab remove: '#{desired.device} #{desired.point} #{desired.type} #{desired.options.join(',')} #{desired.dump} #{desired.pass}'"
          elsif !desired.fstab && !current.fstab
            # nothing...
          end
        end

        private

        def set_current_attributes(current, action)
          mounts = parse(File.read('/proc/mounts'))
          fstabs = parse(File.read('/etc/fstab'))

          mount = {
            :device => desired.device,
            :point => desired.point,
            :type => desired.type,
            :options => desired.options,
            :dump => desired.dump,
            :pass => desired.pass,
          }

          if mounts.include?(mount)
            current.exist = true
          else
            current.exist = false
          end

          if fstabs.include?(mount)
            current.fstab = true
          else
            current.fstab = false
          end
        end

        def set_desired_attributes(desired, action)
          case action
          when :mount
            desired.exist = true
          when :unmount
            desired.exist = false
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

              case mount[:type]
              when 'tmpfs'
                if mount[:options].include?('defaults')
                  mount[:options].delete('defaults')
                  mount[:options] << 'rw'
                  mount[:options] << 'relatime'
                end
              end

              mounts << mount
            end
          end

          mounts
        end
      end
    end
  end
end
