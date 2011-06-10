#!/usr/bin/env ruby
# Possible flags are:
#   --debug       this builds distribuition with debug flags enabled
#   --root DIR    install the binary into this directory. If this flag is not set - the script
#                 redeploys kext to local machine and restarts it

CWD = File.dirname(__FILE__)
KEXT_DIR = '/System/Library/Extensions/'
Dir.chdir(CWD)

debug = ARGV.include?('--debug')
root_dir = ARGV.index('--root') ? ARGV[ARGV.index('--root') + 1] : nil

abort("root directory #{root_dir} does not exist") if ARGV.index('--root') and not File.exists?(root_dir)

unless File.exists?('Makefile') then
  system("autoreconf -f -i -Wall,no-obsolete") or abort
  system("./configure") or abort
end

system("make -s -j3") or abort

cmd = 'sudo make install'
if root_dir
  cmd = cmd + ' DESTDIR=' + root_dir
end

system(cmd)
