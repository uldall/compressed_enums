#!/usr/bin/ruby

require 'optparse'
require "socket"
require "fileutils"

options = {}

OptionParser.new do |opts|
    opts.banner = "Usage: version.rb [options]"

    opts.on("-n", "--name <name>", "Name of project") do |v|
        options[:name] = v
    end

    opts.on("-p", "--path <path>", "Root path of project (where to find .git)") do |v|
        options[:path] = File.expand_path(v)
    end

    opts.on("-h", "--header <path>", "Write c-style header file with version number") do |v|
        options[:header] = File.expand_path(v)
    end

    opts.on("-s", "--cfile <path>", "Write c-style source file with version number") do |v|
        options[:cfile] = File.expand_path(v)
    end

    opts.on("-C", "--cmake <path>", "Write cmake file with version number") do |v|
        options[:cmake] = File.expand_path(v)
    end

    opts.on("-t", "--touch <path>", "Touch this file") do |v|
        options[:touch] = File.expand_path(v)
    end

    opts.on("-f", "--file <path>", "Write version string in file") do |v|
        options[:file] = File.expand_path(v)
    end

    opts.on("-c", "--conf <path>", "Conf file path") do |v|
        options[:conf] = File.expand_path(v)
    end

end.parse!

if options[:name].nil?
    p "A project name must be supplied"
    exit
end

if not options[:path].nil?
    Dir.chdir options[:path]
end

if options[:conf].nil?
    options[:conf] = ENV['HOME'] + "/." + options[:name] + ".yaml"
end

begin
    conf = YAML.load(File.read(options[:conf]))
rescue
    conf = {}
end

githash = %x[git rev-parse HEAD]
gitrev  = %x[git describe --tags --dirty --long]
gitrev.strip!
githash.strip!

conf[:name] = options[:name]

if conf[:localcnt].nil?
    conf[:localcnt]  = 1
else
    conf[:localcnt] += 1
end

conf[:time]     = Time.now.to_i
conf[:user]     = ENV['USER']
conf[:hostname] = Socket.gethostname

dirty = false
if $?.exitstatus == 0
    if gitrev =~ /.*-dirty$/
        dirty = true
        if conf[:gitrev] != gitrev
            conf[:localcnt] = 1
        end

    end
    conf[:gitrev]   = gitrev
else
    conf[:gitrev]   = "NO_GIT_REPOS"
end

# should come from tag
if conf[:gitrev] =~ /^(\d+)/
    version1 = $1;
else
    version1 = 99999;
end
version_major = version1;

# should come from tag
if conf[:gitrev] =~ /^(\d+)\.(\d+)/
    version2 = "#{$1}.#{$2}";
    version_minor = $2;
else
    version2 = "#{version1}.99999";
    version_minor = "99999";
end

# number of commits since tag
if conf[:gitrev] =~ /^(\d+\.\d+)-(\d+)/
    version3 = "#{$1}.#{$2}";
    version_patch = "#{$2}";
else
    version3 = "#{version3}.99999";
    version_patch = "99999";
end

# number of build since commit
if dirty
    version4 = "#{version3}.#{conf[:user]}#{conf[:localcnt]}";
    version_patch += ".#{conf[:user]}#{conf[:localcnt]}";
else
    version4 = "#{version3}.0";
end


if options[:header]
    content  = "#ifndef __RUBY_AUTOGENERATED_VERSION_FILE_FOR_#{conf[:name].upcase}\n"
    content += "#define __RUBY_AUTOGENERATED_VERSION_FILE_FOR_#{conf[:name].upcase}\n"
    content += "extern const char git_version1[];\n"
    content += "extern const char git_version2[];\n"
    content += "extern const char git_version3[];\n"
    content += "extern const char git_version4[];\n"
    content += "extern const char git_major[];\n"
    content += "extern const char git_minor[];\n"
    content += "extern const char git_patch[];\n"
    content += "extern const char git_hash[];\n"
    content += "extern const char build_time[];\n"
    content += "extern const char build_user[];\n"
    content += "extern const char build_hostname[];\n"
    content += "#endif\n"

    _file_content = nil
    begin
        File.open(options[:header], "rb") do |f|
            _file_content = f.read
        end

    rescue
        _file_content = ""

    ensure
        if( _file_content != content )
            File.open(options[:header], 'w') do |f|
                f.write(content)
            end
        end
    end

end

if options[:cfile]
    content  = "const char git_version1[] = \"#{version1}\";\n"
    content += "const char git_version2[] = \"#{version2}\";\n"
    content += "const char git_version3[] = \"#{version3}\";\n"
    content += "const char git_version4[] = \"#{version4}\";\n"
    content += "const char git_major[] = \"#{version_major}\";\n"
    content += "const char git_minor[] = \"#{version_minor}\";\n"
    content += "const char git_patch[] = \"#{version_patch}\";\n"
    content += "const char git_hash[] = \"#{githash}\";\n"
    content += "const char build_time[] = \"#{conf[:time]}\";\n"
    content += "const char build_user[] = \"#{conf[:user]}\";\n"
    content += "const char build_hostname[] = \"#{conf[:hostname]}\";\n"

    _file_content = nil
    begin
        File.open(options[:cfile], "rb") do |f|
            _file_content = f.read
        end

    rescue
        _file_content = ""

    ensure
        if( _file_content != content )
            File.open(options[:cfile], 'w') do |f|
                f.write(content)
            end
        end
    end
end

if options[:cmake]
    File.open(options[:cmake], 'w') do |f|
        f.puts "set(#{conf[:name]}_VERSION  \"#{version4}\")"
        f.puts "set(#{conf[:name]}_VERSION1 \"#{version1}\")"
        f.puts "set(#{conf[:name]}_VERSION2 \"#{version2}\")"
        f.puts "set(#{conf[:name]}_VERSION3 \"#{version3}\")"
        f.puts "set(#{conf[:name]}_VERSION4 \"#{version4}\")"
        f.puts "set(#{conf[:name]}_VERSION_MAJOR \"#{version_major}\")"
        f.puts "set(#{conf[:name]}_VERSION_MINOR \"#{version_minor}\")"
        f.puts "set(#{conf[:name]}_VERSION_PATCH \"#{version_patch}\")"
        f.puts "set(#{conf[:name]}_HASH     \"#{githash}\")"
        f.puts "set(#{conf[:name]}_BUILD_TIME \"#{conf[:time]}\")"
        f.puts "set(#{conf[:name]}_BUILD_USER \"#{conf[:user]}\")"
        f.puts "set(#{conf[:name]}_BUILD_HOSTNAME \"#{conf[:hostname]}\")"
    end
end

File.open(options[:conf], 'w') {|f| f.write(YAML::dump(conf)) }


if options[:touch]
    sleep( 0.01 )
    FileUtils.touch(options[:touch])
end

