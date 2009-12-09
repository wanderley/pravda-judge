
# Configuration file {{{
#
# name            = Problem name.
# time_limit      = Time limit per case.
# memory_limit    = Memory limit per case.
# points_per_test = Points per case.
# number_of_tests = Number of tests case.
# $special_judge   = Special judge's file.
# source          = Info about origin of the problem.
# }}}

$name            = "test"
$time_limit      = 1
$memory_limit    = 128
$points_per_test = 1
$source          = "test"

$number_of_tests = 2
$tests = []
(1..$number_of_tests).to_a.each do |i|
   $tests << [{:in => "tests/#{i}.in", :out => "tests/#{i}.out"}]
   $number_of_tests = $number_of_tests + 1
end
