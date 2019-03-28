module ::MItamae
  module Plugin
    module ResourceExecutor
      class Mount < ::MItamae::ResourceExecutor::Base
        def apply
          entry = "#{desired.device} #{desired.point} #{desired.type} #{desired.options.join(',')} #{desired.dump} #{desired.pass}"

          if desired.mount && current.mount
            # nothing...
          elsif desired.mount && !current.mount
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] mount: '#{desired.mount}' entry: '#{entry}'"
            mount(desired)
          elsif !desired.mount && current.mount
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] mount: '#{desired.mount}' entry: '#{entry}'"
            unmount(desired)
          elsif !desired.mount && !current.mount
            # nothing...
          end

          if desired.fstab && current.fstab
            # nothing...
          elsif desired.fstab && !current.fstab
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] fstab: '#{desired.fstab}' entry: '#{entry}'"
          elsif !desired.fstab && current.fstab
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] fstab: '#{desired.fstab}' entry: '#{entry}'"
          elsif !desired.fstab && !current.fstab
            # nothing...
          end
        end

        private

        @mounts = []
        @fstabs = []

        def set_current_attributes(current, action)
          @mounts = parse(File.read('/proc/mounts'))
          @fstabs = parse(File.read('/etc/fstab'))

          mount = {
            :device => desired.device,
            :point => desired.point,
            :type => desired.type,
            :options => desired.options,
            :dump => desired.dump,
            :pass => desired.pass,
          }

          if mount[:options].include?('defaults') then
            @mounts.map! do |m|
              m.reject! do |k, v|
                k == :options
              end
            end

            mount.reject! do |k,_|
              k == :options
            end
          end

          if action == :unmount then
            @mounts.map! do |m|
              m.select! do |k, v|
                k == :point
              end
            end

            mount.select! do |k,_|
              k == :point
            end
          end

          if @mounts.include?(mount)
            current.mount = true
          else
            current.mount = false
          end

          if @fstabs.include?(mount)
            current.fstab = true
          else
            current.fstab = false
          end
        end

        def set_desired_attributes(desired, action)
          case action
          when :mount
            desired.mount = true
          when :unmount
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
          unless Dir.exist?(entry.point)
            Dir.mkdir(entry.point, 0755)
          end

          result = run_command([
            'mount',
            '-f',
            '-t', entry.type,
            '-o', entry.options.join(','),
            entry.device,
            entry.point,
          ], error: false)

          if result.success?
            run_command([
              'mount',
              '-t', entry.type,
              '-o', entry.options.join(','),
              entry.device,
              entry.point,
            ])
          else
            raise ArgumentError, "failed fake mount: #{entry.device} -> #{entry.point}"
          end
        end

        def unmount(entry)
          result = run_command([
            'umount',
            entry.point,
          ], error: false)

          unless result.success?
            raise ArgumentError, "failed umount: #{entry.point}"
          end
        end
      end
    end
  end
end
