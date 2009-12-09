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
    status = exec_command("safeexec -F10 -t#{time} -n0 -R. ./#{@exec_file} < #{input_file_path} > #{output_path}/stdout")
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
    exec_command("rm #{@exec_file} *.o *.s stdout compile.log")
  end

  def compile!
    return false unless File.exists?(@file_path)

    @rand_name   = (1..5).map { i = rand(62); (i + (i < 10 ? 48 : i < 36 ? 55 : 61)).chr } * ''
    @exec_file   = @rand_name + '.exec'

    exec = lambda { |command| 
      status = exec_command(command) { |pid, stdin, stdout, stderr|
        if !stdout.eof? || !stderr.eof?
          puts 'STDOUT:'
          puts stdout.readlines
          puts 'STDERR:'
          puts stderr.readlines
        end
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
      exec.call("gcc #{@file_path} -o #{@exec_file} -O2 -Wall -O3 -lm")
    when /.*\.cpp$/
      exec.call("g++ #{@file_path} -o #{@exec_file} -O2 -Wall -O3 -lm")
    when /.*\.pas$/
      exec.call("fpc #{@file_path} -o./#{@exec_file} -a -O2")
    else
      @exit_status = ANS_COMPILE_ERROR
      false
    end 
  end
end
