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

        def max_length(list)
          length = 0
          list.each do |v|
            if v.to_s.length > length
              length = v.length
            end
          end
          length += 1
          length
        end

        def fstab(entry, action)
          column_size = 6

          device_head  = '# <file system>'
          point_head   = '<dir>'
          type_head    = '<type>'
          options_head = '<options>'
          dump_head    = '<dump>'
          pass_head    = '<pass>'

          device_list  = [device_head ].concat(@fstabs.map {|m| m[:device]})
          point_list   = [point_head  ].concat(@fstabs.map {|m| m[:point]})
          type_list    = [type_head   ].concat(@fstabs.map {|m| m[:type]})
          options_list = [options_head].concat(@fstabs.map {|m| m[:options].join(',')})
          dump_list    = [dump_head   ].concat(@fstabs.map {|m| m[:dump]})
          pass_list    = [pass_head   ].concat(@fstabs.map {|m| m[:pass]})

          if action
            device_list  << entry[:device]
            point_list   << entry[:point]
            type_list    << entry[:type]
            options_list << entry[:options].join(',')
            dump_list    << entry[:dump]
            pass_list    << entry[:pass]
          end

          device_just  = max_length(device_list)
          point_just   = max_length(point_list)
          type_just    = max_length(type_list)
          options_just = max_length(options_list)
          dump_just    = max_length(dump_list)
          pass_just    = 0 # Ignore Last Entry...

          fstab = ''

          fstab << device_head.ljust(device_just)
          fstab << point_head.ljust(point_just)
          fstab << type_head.ljust(type_just)
          fstab << options_head.ljust(options_just)
          fstab << dump_head.ljust(dump_just)
          fstab << pass_head.ljust(pass_just)
          fstab << "\n"

          p fstab
        end
      end
    end
  end
end
