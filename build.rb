#!/usr/bin/env ruby
# Possible flags are:
#   --debug       this builds distribuition with debug flags enabled
#   --root DIR    install the binary into this directory. If this flag is not set - the script
#                 redeploys kext to local machine and restarts it
#   --static      build static sshfs binary, it dynamically links only with fuse4x library
#   --clean       clean before build

require 'fileutils'

CWD = File.dirname(__FILE__)
KEXT_DIR = '/System/Library/Extensions/'
Dir.chdir(CWD)

debug = ARGV.include?('--debug')
clean = ARGV.include?('--clean')
static = ARGV.include?('--static')
root_dir = ARGV.index('--root') ? ARGV[ARGV.index('--root') + 1] : nil

abort("root directory #{root_dir} does not exist") if ARGV.index('--root') and not File.exists?(root_dir)

system('git clean -xdf') if clean

unless File.exists?('Makefile') then
  system("autoreconf -f -i -Wall,no-obsolete") or abort
  system("./configure") or abort
end

tmp_dir = "/tmp/sshfsbuild-#{Process.pid}"
Dir.mkdir(tmp_dir)

ld_flags = ''
dylibs = %w(iconv gthread-2.0 glib-2.0 intl)
if static
  # In case if we build the distribution we need statically link against
  # macports libraries from the 'dylibs' list above.
  # To do it - we trick the build system by adding temp path with static libraries.
  for lib in dylibs do
    `ln -s /opt/local/lib/lib#{lib}.a #{tmp_dir}/`
  end

  ld_flags = "LDFLAGS='-L#{tmp_dir} -framework CoreFoundation -framework CoreServices'"
end

system("make -s -j3 #{ld_flags}") or abort

cmd = 'sudo make install'
if root_dir
  cmd = cmd + ' DESTDIR=' + root_dir
end

system(cmd)

FileUtils.rm_rf(tmp_dir)
