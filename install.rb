#! /usr/bin/env ruby
Dir.chdir(File.dirname($0))

install = '../site-lisp'
compileonly = $*[0] == '--compile' && $*.shift

dir = []
if $*[0]
  dir.push($*.shift)
else
  Dir.glob('*/'){|d| dir.push(d)}
end

dir.each do |d|
  unless compileonly
    puts("pull")
    puts(`cd #{d}; git pull`)
    puts("install from #{d}")
  else
    puts("compile for #{d}")
  end
  puts('')

  Dir.glob(File.join(d, '*.el')) do |f|
    target = File.join(install, File.basename(f))
    source = File.expand_path(f)
    unless compileonly
      File.unlink(target) if File.exist?(target)
      File.symlink(source, target)
      puts("make link from #{source} to #{target}")
    end
    puts(`emacs -batch -f batch-byte-compile #{target}`)
  end
end
