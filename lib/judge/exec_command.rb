require File.dirname(__FILE__) + '/init'

def exec_command(command)
  Open4::popen4(command) { |pid, stdin, stdout, stderr|
    yield(pid, stdin, stdout, stderr) if block_given?
  }
end
