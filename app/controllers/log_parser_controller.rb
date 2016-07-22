require 'json'
require 'request_log_analyzer'
require 'http_log_parser'
require 'pp'

class LogParserController < ApplicationController
  protect_from_forgery

  def index


  end

  def log_file_parser

    sio = StringIO.new
    file = params[:input_file].path

    # trigger the log parse
    @stdout, @stderr = capture_stdout_and_stderr_with_warnings_on do
      RequestLogAnalyzer::Controller.build(
          no_progress: true,
          output: 'HTML',#EmbeddedHTML,#You can use this custom cleaner for the output
          email:  params[:email],
          file:   sio,
          source_files: file,#'/home/joan/Documents/Log_From_Prod/production.log.1',
          format: params['file_type']#'rails3'
      ).run!
    end
    # read the resulting output
    @analysis = sio.string

    @analysis

  end

  private

  def capture_stdout_and_stderr_with_warnings_on
    $stdout, $stderr, warnings, $VERBOSE =
        StringIO.new, StringIO.new, $VERBOSE, true
    yield
    return $stdout.string, $stderr.string
  ensure
    $stdout, $stderr, $VERBOSE = STDOUT, STDERR, warnings
  end

  class EmbeddedHTML < RequestLogAnalyzer::Output::Base
    def print(str)
      @io << str
    end
    alias_method :<<, :print

    def puts(str = '')
      @io << "#{str}<br/>\n"
    end

    def title(title)
      @io.puts(tag(:h2, title))
    end

    def line(*_font)
      @io.puts(tag(:hr))
    end

    def link(text, url = nil)
      url = text if url.nil?
      tag(:a, text, href: url)
    end

    def table(*columns, &_block)
      rows = []
      yield(rows)

      @io << tag(:table, cellspacing: 0) do |content|
        if table_has_header?(columns)
          content << tag(:tr) do
            columns.map { |col| tag(:th, col[:title]) }.join("\n")
          end
        end

        odd = false
        rows.each do |row|
          odd = !odd
          content << tag(:tr) do
            if odd
              row.map { |cell| tag(:td, cell, class: 'alt') }.join("\n")
            else
              row.map { |cell| tag(:td, cell) }.join("\n")
            end
          end
        end
      end
    end

    def header
    end

    def footer
      @io << tag(:hr) << tag(:p, "Powered by request-log-analyzer v#{RequestLogAnalyzer::VERSION}")
    end

    def tag(tag, content = nil, attributes = nil)
      if block_given?
        attributes = content.nil? ? '' : ' ' + content.map { |(key, value)| "#{key}=\"#{value}\"" }.join(' ')
        content_string = ''
        content = yield(content_string)
        content = content_string unless content_string.empty?
        "<#{tag}#{attributes}>#{content}</#{tag}>"
      else
        attributes = attributes.nil? ? '' : ' ' + attributes.map { |(key, value)| "#{key}=\"#{value}\"" }.join(' ')
        if content.nil?
          "<#{tag}#{attributes} />"
        else
          if content.class == Float
            "<#{tag}#{attributes}><div class='color_bar' style=\"width:#{(content * 200).floor}px;\"/></#{tag}>"
          else
            "<#{tag}#{attributes}>#{content}</#{tag}>"
          end
        end
      end
    end
  end

  def log_parser_params
    params.require(:log_parser).permit(:email, :file_type, :input_file)

  end

end
