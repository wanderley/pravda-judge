class ProblemController < ApplicationController
  skip_before_filter :verify_authenticity_token
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

    name     = Time.new.strftime('%Y%m%d%H%M%S' + rand(1000000).to_s) + '.' + @nick
    folder   = 'db/problems/' + @problem[:path] + '/subs/' + name + '/'
    filename = case @language
               when 'C'   : 'sol.c'
               when 'C++' : 'sol.cpp'
               when 'Java': 'Main.java'
               else         'sol.cpp'
               end

    FileUtils.mkdir_p(folder)
    File.open(folder + filename, 'w') do |sol|
      sol.puts @code
    end
    File.open(folder + 'WAIT', 'w') do
    end
    FileUtils.ln_s('../../' + folder, 'db/wait_subs/' + name)
  
    render :text => %Q{<html><body onload='window.location="/status/#{name}?problem_path=#{@problem_path}";'>\n#{name}?problem_path=#{@problem_path}\n</body></html>}
  end


  def status
    output = '<pre>'
    folder = 'db/problems/' + @problem_path + '/subs/' + params[:date] + '.' + params[:nick]
    if @problem_path.blank? || !File.directory?(folder)
      output += 'It is not a valid submition!'
    elsif
      if File.file?(folder + '/WAIT')
        output += 'waiting'
        enqueue_submission(@problem_path, params[:date], params[:nick])
      else
        output += File.read(folder + '/status')
      end
    end
    render :text => output
  end

  def exitstatus
    output = ''
    folder = 'db/problems/' + @problem_path + '/subs/' + params[:date] + '.' + params[:nick]
    if @problem_path.blank? || !File.directory?(folder)
      output += '-2'
    elsif
      if File.file?(folder + '/WAIT')
        output += '-1'
        enqueue_submission(@problem_path, params[:date], params[:nick])
      else
        output += File.read(folder + '/exitstatus')
      end
    end
    render :text => output
  end

  def enqueue_submission(problem_path, date, nick)
    name = date + '.' + nick
    folder = 'db/problems/' + problem_path + '/subs/' + name
    if File.file?(folder + '/WAIT') && !File.file?('db/wait_subs/' + name)
      FileUtils.ln_s('../../' + folder, 'db/wait_subs/' + name)
    end
  end


  def load_problems
    @problems = $problems
    @problems_grouped = $problems_grouped
  end

  def refresh_variables
    @problem_path     = params[:problem_path]
    @problem_code     = nil
    @problem_source   = nil
    @problem          = nil
    @problems.each do |p|
      if p[:path] == @problem_path
        @problem        = p
        @problem_code   = p[:code]
        @problem_source = p[:source]
        break
      end
    end
    @code     = params[:code]
    @language = params[:language]
    @nick     = session[:nick] = params[:nick] if params[:nick]
    @nick   ||= session[:nick]
    session[:nick] = nil
  end
end
