problems = []
Dir.glob('db/problems/**/config.rb').each do |problem|
  path = problem.gsub('/config.rb', '')
  code = source = ""
  File.read(problem).each_line do |line|
    if line.start_with?('$name')
      code = line.gsub(/^[^"]*"/, '').gsub(/"$/, '').chomp
    elsif line.start_with?('$source')
      source = line.gsub(/^[^"]*"/, '').gsub(/"$/, '').chomp
    end
  end
  problems << [source, code, path]
end

problems.sort!
File.open('db/problems.txt', 'w') do |file|
  problems.each do |p|
    file.puts p.join("\t")
  end
end
