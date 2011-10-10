#!/usr/bin/env ruby
# Possible flags are:
#   --release     build this module for final distribution
#   --root DIR    install the binary into this directory. If this flag is not set - the script
#                 redeploys kext to local machine and restarts it

require 'fileutils'

CWD = File.dirname(__FILE__)
KEXT_DIR = '/System/Library/Extensions/'
Dir.chdir(CWD)

release = ARGV.include?('--release')
root_dir = ARGV.index('--root') ? ARGV[ARGV.index('--root') + 1] : nil

abort("root directory #{root_dir} does not exist") if ARGV.index('--root') and not File.exists?(root_dir)

system('git clean -xdf') if release

unless File.exists?('Makefile') then
  flags = ''
  if release then
    flags += "CFLAGS='-mmacosx-version-min=10.5'"
  end

  system("autoreconf -f -i -Wall,no-obsolete") or abort
  system("./configure #{flags}") or abort
end

tmp_dir = "/tmp/sshfsbuild-#{Process.pid}"
Dir.mkdir(tmp_dir)

ld_flags = ''
dylibs = %w(iconv gthread-2.0 glib-2.0 intl)
if release
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
