module Log
  def self.read_file(file)
    return '' if file == nil or not File.exist? file
    f = File.open(file, 'r')
    ret = ""
    cnt = 0
    f.each_byte { |c|
      ret += c.chr
      cnt = cnt + 1
      if cnt > 2000
        ret += "... (arquivo muito grande)"
        break
      end
    }
    ret
  end

  def self.header(name, time_limit, memory_limit, points_per_test, number_of_tests, source)
    puts "----------------------------------------------------------------------"
    puts "PROBLEMA :: #{$name} ::"
    puts "----------------------------------------------------------------------"
    puts "  Limite de tempo...: #{time_limit}"
    puts "  Limite de memória.: #{memory_limit}"
    puts "  Pontos por teste..: #{points_per_test}"
    puts "  Número de testes..: #{number_of_tests}"
    puts "  Fonte.............: #{source}"
    puts "----------------------------------------------------------------------"
  end

  def self.compile_error
    #puts File.read('compile.log')
  end
  
  def self.test(test_case, exitstatus, input, expected_output, output)
    printf "  Teste %3d: ", test_case
    case exitstatus
    when Submission::ANS_TIME_LIMIT
      puts "Limite de tempo excedido!"
    when Submission::ANS_MEMORY_LIMIT
      puts "Limite de memória excedido!"
    when Submission::ANS_RUNTIME_ERROR
      puts "Erro em tempo de execução!"
    when Submission::ANS_WRONG
      puts "Resposta errada!"
    when Submission::ANS_ACCEPTED
      puts "Ok!"
    end
    unless exitstatus == Submission::ANS_ACCEPTED
      puts <<EOF

ENTRADA:
----------------------------------------------------------------------
#{read_file(input)}

SAÍDA ESPERADA:
----------------------------------------------------------------------
#{read_file(expected_output)}

SAÍDA DO COMPETIDOR:
----------------------------------------------------------------------
#{read_file(output)}

EOF
    end
  end

  def self.resume(accepted_cases, points_per_test, better_time, worst_time)
    puts "----------------------------------------------------------------------"
    puts "  Respostas corretas.: #{accepted_cases}"
    puts "  Pontuação..........: #{accepted_cases * points_per_test}"
    puts "  Melhor tempo.......: #{better_time}"
    puts "  Pior tempo.........: #{worst_time}"
    puts "----------------------------------------------------------------------"
  end

  def self.failed_test_html(test_case, input, expected_output, output)
    File.open("log/#{test_case}.html", 'w') do |log|
      log.puts <<EOF
<html><title>Log da submissão #{test_case}</title>
<body>
<h1>Entrada</h1>
<span onclick=\"e = document.getElementById('input'); e.style.display = (e.style.display == 'none') ? 'inline' : 'none';\">+ Mostrar/ocultar a input</span>
<div id=\"input\" style=\"display: none\"><pre>
    #{read_file(input)}
</pre></div>

<h2>Saídas</h2>
<span onclick=\"e = document.getElementById('output'); e.style.display = (e.style.display == 'none') ? 'inline' : 'none';\">+ Mostrar/ocultar a saída</span>
<div id=\"output\" style=\"display: none\">
<table border='1'>
<tr><td><b>Saída esperada</b></td><td><b>Saída do competidor</b></td></tr>
<tr><td><pre>
    #{read_file(expected_output)}
</pre></td>
<td><pre>
    #{read_file(output)}
</pre></td></tr>
</table></div>
</body>
</html>
EOF
    end
  end
end
