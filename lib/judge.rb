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
      filename = 'sol.cpp'
      ['sol.c', 'Main.java'].each do |i|
        filename = i if File.exist?("#{path}/#{i}")
      end
      `ruby #{IOI_JUDGE} #{path}/#{filename} > #{path}/status 2> /dev/null; echo $? > #{path}/exitstatus`
    end
    FileUtils.cd(sub) do
      FileUtils.rm('WAIT')
    end
    FileUtils.rm(sub)
  end
  sleep(10)
end
