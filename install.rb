#! /usr/bin/env ruby
require 'fileutils'

if $*.delete('-h') || $*.delete('--help')
  print <<"EOM"
Usage: #{$0} [OPTIONS] source...
Options:
  -p, --do-not-pull   Suppress pull action. (no)
  -o, --compile-only  Suppress pull and link action. (no)
  -c, --copy          Make copy instead of link. (no)
  -v, --verbose       Ask when override. (no)
  -s, --silent        Supress messages. (no)
  --install=<dir>     Target directory. (../site-lisp)
  --emacs=<bin>       Emacs binary path. (emacs)
EOM
  exit
end

class Info
  def initialize(silent, verbose) @s = silent; @v = verbose end
  def puts(msg) Kernel.puts(msg) unless @s end
  def ask(msg) return !@v || print(msg) || $stdin.gets =~ /^y/ end
end

dontpull = $*.delete('-p') || $*.delete('--do-not-pull')
compileonly = $*.delete('-o') || $*.delete('--compile-only')
copy = $*.delete('-c') || $*.delete('--copy')
verbose = $*.delete('-v') || $*.delete('--verbose')
s = $*.delete('-s') || $*.delete('--silent')
verbose = verbose && !s
info = Info.new(s, verbose)

install = $*.reject!{|x|x=~/^--install=(.*)$/} && $1 || '../site-lisp'
emacs = $*.reject!{|x|x=~/^--emacs=(.*)$/} && $1 || 'emacs'

source = $*
source.push('*/') if source.size < 1

Dir.chdir(File.dirname($0))
source.map!{|dir|Dir.glob(dir)}.each do |dir|
  unless compileonly || dontpull
    info.puts("pull")
    info.puts(`cd #{dir}; git pull`)
    info.puts("install from #{dir}")
  end
  info.puts('')

  Dir.glob(File.join(dir, '*.el')) do |f|
    target = File.join(install, File.basename(f))
    src = File.expand_path(f)
    unless compileonly
      ovw_msg = proc{|name| "#{name} already exists. overwrite? (y/n) "}
      write = [ target, target+'c' ].all? do |t|
        !File.exist?(t) || info.ask(ovw_msg.call(t)) && File.unlink(t)
      end
      if write
        if copy
          info.puts("copy from #{source} to #{target}")
          FileUtils.copy(src, target)
        else
          info.puts("make link from #{source} to #{target}")
          File.symlink(src, target)
        end
      end
    end
    info.puts("compile for #{dir}")
    info.puts(`#{emacs} -batch -f batch-byte-compile #{target}`)
  end
end
