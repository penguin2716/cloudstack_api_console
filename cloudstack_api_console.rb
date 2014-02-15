#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), 'api_console'))
require File.expand_path(File.join(File.dirname(__FILE__), 'rexml_hash'))

con = CloudStack::APIConsole.new
con.console

