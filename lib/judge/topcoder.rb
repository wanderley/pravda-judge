#!/usr/bin/env ruby

require "shell"

MAQUINA = :wanderley
#MAQUINA = :bombonera

# Constantes {{{
if MAQUINA == :wanderley
   $UNLIMIT_TIME_LIMIT    = 152
   $UNLIMIT_RUNTIME_LIMIT = 138
   $UNLIMIT_MEMORY_LIMIT  = 127
else
   # usando safeexec
   $UNLIMIT_TIME_LIMIT    = 3
   $UNLIMIT_RUNTIME_LIMIT = 2
   $UNLIMIT_MEMORY_LIMIT  = 127
end

$ANS_COMPILE_ERROR = 2
$ANS_RUNTIME_ERROR = 3
$ANS_TIME_LIMIT    = 4
$ANS_MEMORY_LIMIT  = 5
$ANS_WRONG         = 6
$ANS_ACCEPTED      = 0
# }}}

# Parâmetros {{{
#   $1 Pasta onde estão as classes de teste
#   $2 Nome do arquivo que será julgado
#   $3 Nome da classe
#   $4 Time Limit do problema
folder, source, name, time_limit = ARGV[0], ARGV[1], ARGV[2], ARGV[3]
# }}}

# Verificando parâmetros {{{
if ARGV.size != 4
   puts "ERRO: use: judge.topcoder.rb [pasta da classe] [nome do arquivo que será julgado] [nome da classe] [time limit]"
   exit 1
end
# }}}

# Cabeçalho {{{
puts   "----------------------------------------------------------------------"
puts   "PROBLEMA :: #{name} ::"
puts   "----------------------------------------------------------------------"
printf "   %20s: #{name}\n", "Nome da classe"
printf "   %20s: #{time_limit}\n", "Limite de tempo"
printf "   ** TopCoder **\n"
puts   "----------------------------------------------------------------------"
# }}}

# Copiando a submissão {{{
source_orig = File.open source, "r"
source_new  = File.open "#{folder}/#{name}.cpp", "w"

flag_cut = false
source_orig.each_line do |line|
   if !flag_cut and line.index('BEGIN CUT HERE')
      flag_cut = true
      next
   elsif flag_cut and line.index('END CUT HERE')
      flag_cut = false
      next
   elsif flag_cut
      next
   end
   source_new.puts line
end
source_new.close
# }}}

# Compilando {{{
cmd  = ""
exec = (1..5).map{i=rand(62);(i+(i<10?48:i<36?55:61)).chr}*''

puts "Compilando classe [#{name}] ..."

cmd = "g++ #{folder}/#{name}Test.cpp -o #{exec} -Wall -W -O2 -s -pipe -lm"

puts "  Comando: #{cmd}"
if !system(cmd)
   puts "ERRO: Código não compila!"
   exit $ANS_COMPILE_ERROR
end

# }}}

# Roda testes {{{

puts "----------------------------------------------------------------------"
puts "Executando os testes ..."
casos_total   = 0
casos_aceitos = 0
exit_code     = 0
time_better   = -1
time_worst    = -1

while true
   casos_total = casos_total + 1
   time_start  = Time.new
   exitstatus  = 0

   if MAQUINA == :wanderley
      system "ulimit -t #{time_limit}; ./#{exec} #{casos_total-1} > /dev/null 2> /dev/null"
      exitstatus = $?.exitstatus
   else
      system "safeexec -t#{time_limit} -R. -n0 #{exec} #{casos_total-1} > /dev/null 2> /dev/null"
      exitstatus  = $?.exitstatus
      exitstatus -= 10 if $?.exitstatus > 9
   end
   break if exitstatus == 100

   printf "Teste %3d: ", casos_total

   time_end   = Time.new
   time_total = time_end - time_start

   time_better = time_total if time_better == -1 or time_better > time_total
   time_worst  = time_total if time_worst  == -1 or time_total  > time_worst

   case
   when exitstatus == $UNLIMIT_TIME_LIMIT
      puts "Limite de tempo excedido!"
      exit_code = $ANS_TIME_LIMIT
   when exitstatus == $UNLIMIT_MEMORY_LIMIT
      puts "Limite de memória excedido!"
      exit_code = $ANS_MEMORY_LIMIT
   when exitstatus == $ANS_WRONG
      printf "Resposta errada! (%.3fs)\n", time_total
      exit_code = $ANS_WRONG
   when exitstatus == $ANS_ACCEPTED
      printf "OK (%.3fs)\n", time_total
      casos_aceitos += 1
   when exitstatus != 0
      puts "Erro em tempo de execução!"
      exit_code = $ANS_RUNTIME_ERROR
   end

   break if exit_code != 0
end

puts "----------------------------------------------------------------------"
printf "%20s: %d\n", "Respostas corretas", casos_aceitos
printf "%20s: %.3fs\n", "Melhor tempo", time_better
printf "%20s: %.3fs\n", "Pior tempo", time_worst
puts "----------------------------------------------------------------------"

# }}}

# Limpando {{{
#system "rm #{exec} #{name}.cpp tmp"
# }}}

exit exit_code

