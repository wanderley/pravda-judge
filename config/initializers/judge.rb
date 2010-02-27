$problems = []
$problems_grouped = {}
File.read('db/problems.txt').each_line do |line|
  source, code, path = line.split("\t").map { |x| x.chomp }
  source = '(none)' if source == '' or source.nil? == true
  path   = path.sub('db/problems/', '')
  $problems_grouped[source] ||= []
  $problems << { :source => source, :code => code, :path => path }
  $problems_grouped[source] << { :source => source, :code => code, :path => path }
end

