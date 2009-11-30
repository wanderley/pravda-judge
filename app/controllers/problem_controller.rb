class ProblemController < ApplicationController
  def index
    load_problems()
  end

  def submit
    unless params[:problem_code] && params[:problem_source]
      flash[:error] = 'You must select a problem before!'
      redirect_to '/problems'
    end
    refresh_variables()
  end

  def submited
    refresh_variables()
    if @problem_code.blank? || @problem_source.blank?
      flash[:error] = 'You must select a problem before!'
      redirect_to '/problems'
      return
    end

    if @nick.blank?
      flash[:error] = 'You must inform your nick! Use the same the archive your solutions!'
      render 'submit'
      return
    end
    if @code.blank?
      flash[:error] = 'You must paste your code!'
      render 'submit'
      return
    end

    load_problems()
    problem = nil
    @problems.each do |p|
      if p[:code] == @problem_code && p[:source] == @problem_source
        problem = p
        break
      end
    end

    if problem.nil?
      flash[:error] = 'It\'s not a valid problem!'
      redirect_to '/problems'
      return
    end

    name   = Time.new.strftime('%Y%m%d%H%M%S') + '.' + @nick
    folder = problem[:path] + '/subs/' + name + '/'
    FileUtils.mkdir_p(folder)
    File.open(folder + 'sol.cpp', 'w') do |sol|
      sol.puts @code
    end
    File.open(folder + 'WAIT', 'w') do
    end
    FileUtils.ln_s('../../' + folder, 'db/wait_subs/' + name)

    # Wait to change id of submition :P
    sleep(2)
    redirect_to '/status/' + name
  end


  def status
    output = '<pre>'

    folder = Dir.glob('db/problems/**/subs/' + params[:date] + '.' + params[:nick])
    if folder.blank?
      output += 'It is not a valid submition!'
    elsif
      folder = folder[0]
      if File.file?(folder + '/WAIT')
        output += 'waiting'
      else
        output += File.read(folder + '/status')
      end
    end

    render :text => output
  end

  def load_problems
    @problems = []
    @problems_grouped = {}
    File.read('db/problems.txt').each_line do |line|
      source, code, path = line.split("\t").map { |x| x.chomp }
      source = '(none)' if source == '' or source.nil? == true
      @problems_grouped[source] ||= []
      @problems << { :source => source, :code => code, :path => path }
      @problems_grouped[source] << { :source => source, :code => code, :path => path }
    end
  end

  def refresh_variables
    @problem_code = params[:problem_code]
    @problem_source = params[:problem_source]
    @code = params[:code]
    if params[:nick]
      @nick = session[:nick] = params[:nick]
    end
    @nick ||= session[:nick]
    session[:nick] = nil
  end
end
