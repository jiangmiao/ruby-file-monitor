#!/usr/bin/env ruby
# coding: utf-8

require 'rubygems'

lib_dir = File.join File.dirname(__FILE__), '../lib'
$:.unshift lib_dir unless $:.include? lib_dir

require 'file-monitor'
require 'sinatra'
require 'getoptlong'

class AjaxF5 < FileMonitor
  attr_reader :updated_at, :js
  def initialize(dir)
    super dir
    @updated_at = Time.now.to_f
    # ajax library from http://code.google.com/p/miniajax/
    @js = <<EOT
(function() {
  var ajax;
  function $(e){if(typeof e=='string')e=document.getElementById(e);return e};
  function collect(a,f){var n=[];for(var i=0;i<a.length;i++){var v=f(a[i]);if(v!=null)n.push(v)}return n};

  ajax={};
  ajax.x=function(){try{return new ActiveXObject('Msxml2.XMLHTTP')}catch(e){try{return new ActiveXObject('Microsoft.XMLHTTP')}catch(e){return new XMLHttpRequest()}}};
  ajax.serialize=function(f){var g=function(n){return f.getElementsByTagName(n)};var nv=function(e){if(e.name)return encodeURIComponent(e.name)+'='+encodeURIComponent(e.value);else return ''};var i=collect(g('input'),function(i){if((i.type!='radio'&&i.type!='checkbox')||i.checked)return nv(i)});var s=collect(g('select'),nv);var t=collect(g('textarea'),nv);return i.concat(s).concat(t).join('&');};
  ajax.send=function(u,f,m,a){var x=ajax.x();x.open(m,u,true);x.onreadystatechange=function(){if(x.readyState==4)f(x.responseText)};if(m=='POST')x.setRequestHeader('Content-type','application/x-www-form-urlencoded');x.send(a)};
  ajax.get=function(url,func){ajax.send(url,func,'GET')};
  var now = Date.now();
  function checkStatus() {
    ajax.get("/f5_status", function(rt) {
      if (now < parseFloat(rt)) {
        location.reload(true);
      }
      setTimeout(checkStatus, 500);
    });
  }
  checkStatus();
})();
EOT
  end

  # simple mark the last updated time
  def check(events)
    @updated_at = Time.now.to_f
    puts "updated at #{@updated_at}"
  end

  def run
    # use new thread to monitor the file
    Thread.new do
      begin
        super
      rescue
        puts $!.message
      end
    end

    f5 = self
    set :logging, false
    get '/f5_status' do
      (f5.updated_at*1000).to_s
    end

    get '/f5.js' do
      f5.js
    end

    get '*' do
      host = env['SERVER_NAME']
      path = env['REQUEST_PATH']
      begin
        data = open('http://' + host + path) {|f|
          content_type f.meta['content-type']
          f.read
        }
        data.gsub Regexp.new('</body>', Regexp::IGNORECASE), '<script type="text/javascript" src="/f5.js"></script></body>'
      rescue
        $!.message.match /\d+/
          [$&.to_i, {}, '']
      end
    end
  end
end

dir = ARGV[0] || '.'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT]
)

opts.each do|opt, arg|
  case opt
  when '--help'
    puts 'ruby f5.rb [project-directory]'
    exit
  end
end

require 'sinatra'
require 'open-uri'
f5 = AjaxF5.new dir
f5.ignored_dirs = /\.git|\.svn/
f5.ignored_files = /\.sw.*|\~/
f5.run
