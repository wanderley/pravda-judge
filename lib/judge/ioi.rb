#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/init'

module IOI
  def self.judge(problem_path, file_path)
    Dir.chdir(problem_path) do
      require './config.rb'

      Log.header($name, $time_limit, $memory_limit, $points_per_test, $number_of_tests, $source)
      submission = Submission.new(file_path)

      unless submission.compile!
        Log.compile_error
        submission.clear!
        return Submission::ANS_COMPILE_ERROR
      end

      total_cases    = 0
      accepted_cases = 0
      exit_code      = Submission::ANS_ACCEPTED
      better_time    = 999999
      worst_time     = -1
      wrong_cases    = 0
      
      if $tests.nil?
        $number_of_tests = 0
        $tests           = []
        test_in  = Dir.glob(File.join('tests/**', '*.i*')).sort
        test_out = Dir.glob(File.join('tests/**', '*.o*')).sort
        if test_out.size == 0
          test_out = Dir.glob(File.join('tests/**', '*.a*')).sort
        end
        0.upto test_in.size-1 do |i|
          $tests << [ {:in => test_in[i], :out => test_out[i]} ]
        end
        $number_of_tests = $tests.size
        $points_per_test = 100.0 / $number_of_tests
      end

      $tests.each do |test|
        total_cases = total_cases + 1
        test        = test[0]
        time_start  = Time.new
        status      = submission.execute!(test[:in], $time_limit)
        time_end    = Time.new
        time_total  = time_end - time_start
        worst_time  = [worst_time, time_total].max 
        better_time = [better_time, time_total].min

        if status == Submission::ANS_ACCEPTED
          if $special_judge
            status = exec_command("#{$special_judge} 3< #{test[:in]} 4< stdout 5< #{test[:out]}").exitstatus
          elsif
            #status = exec_command("diff -B -b stdout
            ##{test[:out]}").exitstatus
            status = if File.read('stdout').gsub(/\s+/, '') != File.read(test[:out]).gsub(/\s+/, '')
                       Submission::ANS_WRONG
                     else 
                       Submission::ANS_ACCEPTED
                     end
          end
          unless status == Submission::ANS_ACCEPTED
            status = Submission::ANS_WRONG
          end
        end

        Log.test(total_cases, status, test[:in], test[:out], 'stdout')
        accepted_cases += 1 if status == Submission::ANS_ACCEPTED
        exit_code = status if exit_code == Submission::ANS_ACCEPTED
      end

      Log.resume(accepted_cases, $points_per_test, better_time, worst_time)
      submission.clear!

      return exit_code
    end
  end
end

if __FILE__ == $0
  if ARGV.size != 1
    puts "ERRO: use: judge.ioi.rb arquivo.c"
    exit 1
  end
  exit IOI.judge('.', ARGV[0])
end

