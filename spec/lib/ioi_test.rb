require File.dirname(__FILE__) + '/../../lib/judge/init'

def submit(problem_path, file_name)
  judge = Dir.pwd + '/lib/judge/ioi.rb'
  Dir.chdir(problem_path) do
    exec_command(judge + ' subs/' + file_name).exitstatus
  end
end

describe 'IOI Judge' do
  describe 'without special judge' do
    before(:each) do
      @problem_path = File.dirname(File.expand_path(__FILE__)) + '/../resources/problem/'
    end

    describe 'C++ submission' do
      it 'get accepted' do
        IOI.judge(@problem_path, 'subs/ac/ac.cpp').should eql(Submission::ANS_ACCEPTED)
      end

      it 'get wrong answer' do
        IOI.judge(@problem_path, 'subs/wa/wa.cpp').should eql(Submission::ANS_WRONG)
      end

      it 'get time limit' do
        IOI.judge(@problem_path, 'subs/tl/tl.cpp').should eql(Submission::ANS_TIME_LIMIT)
      end

      it 'get runtime error' do
        IOI.judge(@problem_path, 'subs/re/re.cpp').should eql(Submission::ANS_RUNTIME_ERROR)
      end

      it 'get memory limit exceded' do
        pending
        IOI.judge(@problem_path, 'subs/ml/ml.cpp').should eql(Submission::ANS_MEMORY_LIMIT)
      end

      it 'get compile error' do
        IOI.judge(@problem_path, 'subs/ce/ce.cpp').should eql(Submission::ANS_COMPILE_ERROR)
      end
    end

    describe 'Java submission' do
      it 'get accepted' do
        IOI.judge(@problem_path, 'subs/ac/Main.java').should eql(Submission::ANS_ACCEPTED)
      end
      
      it 'get wrong answer' do
        IOI.judge(@problem_path, 'subs/wa/Main.java').should eql(Submission::ANS_WRONG)
      end
  
      it 'get time limit' do
        IOI.judge(@problem_path, 'subs/tl/Main.java').should eql(Submission::ANS_TIME_LIMIT)
      end

      it 'get runtime error' do
        IOI.judge(@problem_path, 'subs/re/Main.java').should eql(Submission::ANS_RUNTIME_ERROR)
      end

      it 'get memory limit exceded' do
        pending
      end

      it 'get compile error' do
        IOI.judge(@problem_path, 'subs/ce/Main.java').should eql(Submission::ANS_COMPILE_ERROR)
      end
    end
  end
end
