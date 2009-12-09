require File.dirname(__FILE__) + '/../../lib/judge/submission.rb'

def get_submission(file)
  Submission.new(File.dirname(__FILE__) + "/../resources/problem/subs/#{file}")
end

describe 'Submission class' do
  it 'should compile C++ accepted file' do
    submission = get_submission('ac.cpp')
    submission.compile!.should be_true
    submission.clear!
  end

  it 'should not compile C++ compile_error file' do
    submission = get_submission('ce.cpp')
    submission.compile!.should be_false
    submission.clear!
  end
end
