require 'fileutils'

while true
  Dir.glob('db/wait_subs/*').each do |sub|
    path = nil
    FileUtils.cd(sub) do
      path = FileUtils.pwd
    end
    puts 'Processing ' + sub
    FileUtils.cd(sub + '/../../') do
      `judge.ioi.rb #{path}/sol.cpp > #{path}/status 2> /dev/null`
    end
    FileUtils.cd(sub) do
      FileUtils.rm('WAIT')
    end
    FileUtils.rm(sub)
  end
  puts FileUtils.pwd

  sleep(10)
end
