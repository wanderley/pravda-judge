require File.dirname(__FILE__) + '/init.rb'

class Submission
  UNLIMIT_TIME_LIMIT    = 3
  UNLIMIT_RUNTIME_LIMIT = 2
  UNLIMIT_MEMORY_LIMIT  = 9
  ANS_COMPILE_ERROR     = 2
  ANS_RUNTIME_ERROR     = 3
  ANS_TIME_LIMIT        = 4
  ANS_MEMORY_LIMIT      = 5
  ANS_WRONG             = 6
  ANS_ACCEPTED          = 0

  def initialize(file_path)
    @file_path   = file_path 
    @exit_status = nil
  end

  def execute!(input_file_path, time=1, output_path=nil)
    output_path = '.' if output_path == nil
    if @type == :java
      java = `which java`.chomp
      status = exec_command("safeexec -F10 -t#{(time * 1.5).ceil} -T#{(time * 1.5 * 4).ceil} -n0 #{java} #{@exec_file} < #{input_file_path} > #{output_path}/stdout 2> /dev/null")
    else
      status = exec_command("safeexec -F10 -t#{time} -T#{time * 4} -n0 -R. ./#{@exec_file} < #{input_file_path} > #{output_path}/stdout 2> /dev/null")
    end
    @exit_status = case status.exitstatus
                   when UNLIMIT_TIME_LIMIT
                     ANS_TIME_LIMIT
                   when UNLIMIT_MEMORY_LIMIT
                     ANS_MEMORY_LIMIT
                   when 0
                     ANS_ACCEPTED
                   else
                     ANS_RUNTIME_ERROR
                   end
  end

  def clear!
    exec_command("rm #{@exec_file} *.o *.s stdout compile.log *.class")
  end

  def compile!
    return false unless File.exists?(@file_path)

    @rand_name   = (1..5).map { i = rand(62); (i + (i < 10 ? 48 : i < 36 ? 55 : 61)).chr } * ''
    @exec_file   = @rand_name + '.exec'

    exec = lambda { |command| 
      status = exec_command(command) { |pid, stdin, stdout, stderr|
          #puts('STDOUT:', stdout.readlines) raise nil unless stdout.eof?
          puts('STDERR:', stderr.readlines) unless stderr.eof?
      }
      if status.exitstatus != 0
        @exit_status = ANS_COMPILE_ERROR
        false
      else
        true
      end
    }

    case @file_path
    when /.*\.c$/
      @type = :c
      exec.call("gcc #{@file_path} -o #{@exec_file} -O2 -Wall -O3 -lm")
    when /.*\.cpp$/
      @type = :cpp
      exec.call("g++ #{@file_path} -o #{@exec_file} -O2 -Wall -O3 -lm")
    when /.*\.pas$/
      @type = :pas
      exec.call("fpc #{@file_path} -o./#{@exec_file} -a -O2")
    when /.*\.java$/
      @type = :java
      @exec_file = File.basename(@file_path, '.java')
      if @exec_file!= 'Main'
        @exit_status = ANS_COMPILE_ERROR
        puts 'STDERR:',  'O arquivo fonte e a classe devem se chamar Main.java e Main, respectivamente.', File.basename(@file_path, 'java')
        false
      else
        exec.call("javac -d . #{@file_path}")
      end
    else
      @exit_status = ANS_COMPILE_ERROR
      false
    end 
  end
end
