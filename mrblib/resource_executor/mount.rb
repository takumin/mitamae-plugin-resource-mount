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
            fstab(desired, desired.fstab)
          elsif !desired.fstab && current.fstab
            MItamae.logger.debug "#{@resource.resource_type}[#{@resource.resource_name}] fstab: '#{desired.fstab}' entry: '#{entry}'"
            fstab(desired, desired.fstab)
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

          mounts = @mounts.map do |m|
            m[:point]
          end
          fstabs = @fstabs.map do |m|
            m[:point]
          end

          if mounts.include?(desired.point)
            current.mount = true
          else
            current.mount = false
          end

          if fstabs.include?(desired.point)
            current.fstab = true
          else
            current.fstab = false
          end
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
          unless Dir.exist?(entry.point)
            raise AttributeMissingError, "not found mount directory: #{entry.point}"
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

        def fstab_max_length(symbol, current)
          length = current
          @fstabs.each do |v|
            case v
            when Array
              v[symbol].join(',').length
            when Integer
              v[symbol].to_s.length
            when String
              v[symbol].length
            end
          end
          length += 1
          length
        end

        def fstab(entry, action)
          device_head  = '# <file system>'
          point_head   = '<dir>'
          type_head    = '<type>'
          options_head = '<options>'
          dump_head    = '<dump>'
          pass_head    = '<pass>'

          device_len  = device_head.length
          point_len   = point_head.length
          type_len    = type_head.length
          options_len = options_head.length
          dump_len    = dump_head.length
          pass_len    = pass_head.length

          if !action
            @fstabs.map do |m|
              m.reject! do |k, v|
                k == :point && v == entry.point
              end
            end
          end

          device_len  = fstab_max_length(:device, device_len)
          point_len   = fstab_max_length(:point, point_len)
          type_len    = fstab_max_length(:type, type_len)
          options_len = fstab_max_length(:options, options_len)
          dump_len    = fstab_max_length(:dump, dump_len)
          pass_len    = fstab_max_length(:pass, pass_len)

          pass_len = 0 # Ignore last column...

          if action
            @fstabs << {
              :device  => entry.device,
              :point   => entry.point,
              :type    => entry.type,
              :options => entry.options,
              :dump    => entry.dump,
              :pass    => entry.pass,
            }
          end

          p @fstabs
        end
      end
    end
  end
end
