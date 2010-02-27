class ProblemController < ApplicationController
  before_filter :load_problems
  before_filter :refresh_variables, :except => [:index]

  def index
  end

  def submit
    unless @problem_path
      flash[:error] = 'You must select a problem before!'
      redirect_to '/problems'
    end
  end

  def submited
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

    if @problem.blank?
      flash[:error] = 'It\'s not a valid problem!'
      redirect_to '/problems'
      return
    end

    name   = Time.new.strftime('%Y%m%d%H%M%S') + '.' + @nick
    folder = 'db/problems/' + @problem[:path] + '/subs/' + name + '/'

    FileUtils.mkdir_p(folder)

    File.open(folder + 'sol.cpp', 'w') do |sol|
      sol.puts @code
    end

    File.open(folder + 'WAIT', 'w') do
    end

    FileUtils.ln_s('../../' + folder, 'db/wait_subs/' + name)

    # Wait to change id of submition :P
    sleep(2)

    redirect_to "/status/#{name}?problem_path=#{@problem_path}"
  end


  def status
    output = '<pre>'
    folder = 'db/problems/' + @problem_path + '/subs/' + params[:date] + '.' + params[:nick]
    if @problem_path.blank? || !File.directory?(folder)
      output += 'It is not a valid submition!'
    elsif
      if File.file?(folder + '/WAIT')
        output += 'waiting'
      else
        output += File.read(folder + '/status')
      end
    end
    render :text => output
  end

  def exitstatus
    output = '<pre>'
    folder = 'db/problems/' + @problem_path + '/subs/' + params[:date] + '.' + params[:nick]
    if @problem_path.blank? || !File.directory?(folder)
      output += 'It is not a valid submition!'
    elsif
      if File.file?(folder + '/WAIT')
        output += 'waiting'
      else
        output += File.read(folder + '/exitstatus')
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
      path   = path.sub('db/problems/', '')
      @problems_grouped[source] ||= []
      @problems << { :source => source, :code => code, :path => path }
      @problems_grouped[source] << { :source => source, :code => code, :path => path }
    end
  end

  def refresh_variables
    @problem_path   = params[:problem_path]
    @problem_code   = nil
    @problem_source = nil
    @problem        = nil
    @problems.each do |p|
      if p[:path] == @problem_path
        @problem        = p
        @problem_code   = p[:code]
        @problem_source = p[:source]
        break
      end
    end
    @code   = params[:code]
    @nick   = session[:nick] = params[:nick] if params[:nick]
    @nick ||= session[:nick]
    session[:nick] = nil
  end
end
