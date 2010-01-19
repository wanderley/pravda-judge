require 'fileutils'

IOI_JUDGE = File.expand_path(File.dirname(__FILE__)) + '/judge/ioi.rb'

while true
  Dir.glob('db/wait_subs/*').each do |sub|
    path = nil
    FileUtils.cd(sub) do
      path = FileUtils.pwd
    end
    puts 'Processing ' + sub
    FileUtils.cd(sub + '/../../') do
      `#{IOI_JUDGE} #{path}/sol.cpp > #{path}/status 2> /dev/null; echo $? > #{path}/exitstatus`
    end
    FileUtils.cd(sub) do
      FileUtils.rm('WAIT')
    end
    FileUtils.rm(sub)
  end
  sleep(10)
end
