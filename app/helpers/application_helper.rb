# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def last_export_timestamp
    @last_export_timestamp ||= GloboDns::Util::last_export_timestamp
  end

  def num_pending_updates
    @num_pending_updates ||= Audited::Adapters::ActiveRecord::Audit.where('created_at > ?', last_export_timestamp).count
  end

  # Outputs a page title with +@page_title+ appended
  def page_title
    title = t(:layout_main_title)
    title << ' - ' + @page_title unless @page_title.nil?
    title
  end

  # Output the flashes if they exist
  def show_flash
    html = ''
    [ :alert, :notice, :info, :warning, :error ].each do |f|
      options = { :id => "flash-#{f}", :class => "flash-#{f}" }
      options.merge!( :style => 'display:none' ) if flash[f].nil?
      html << content_tag( 'div', options ) { flash[f] || '' }
    end
    html.html_safe
  end

  # Link to Zytrax
  def dns_book( text, link )
    link_to text, "http://www.zytrax.com/books/dns/#{link}", :target => '_blank'
  end

  # Add a cancel link for shared forms. Looks at the provided object and either
  # creates a link to the index or show actions.
  def link_to_cancel(object, options = {})
    path = object.class.name.tableize
    path = if object.new_record?
             send( path.pluralize + '_path' )
           else
             send( path.singularize + '_path', object )
           end
    link_to "Cancel", path, options
  end

  # Add a cancel link for shared forms. Looks at the provided object and either
  # creates a link to the index or show actions.
  def cancel_button(options = {})
    # path = object.class.name.tableize
    # path = if object.new_record?
    #          send(path.pluralize + '_path')
    #        else
    #          send(path.singularize + '_path', object)
    #        end
    # button_to_function(t(:generic_cancel), 'history.back()', options)
    button_tag(t(:generic_cancel), options.merge({:onclick => 'history.back()'}))
  end

  def help_icon( dom_id )
    # image_tag('help.png', :id => "help-icn-#{dom_id}", :class => 'help-icon', "data-help" => dom_id )
    content_tag(:span, '', :id => "help-icn-#{dom_id}", :class => 'help-icon ui-icon-question-sign', "data-help" => dom_id)
  end

  def info_icon( image, dom_id )
    image_tag( image , :id => "help-icn-#{dom_id}", :class => 'help-icn', "data-help" => dom_id )
  end
  
  def form_errors object
    html = ""
    if object.errors.any?
      html << '<div class="alert alert-error">'
      html << '<h4 class="alert-heading">' + pluralize(object.errors.count, "error(s)") + '</h4>'
      html << '<ul>'
      object.errors.full_messages.each do |msg|
      html << '<li>'+ msg +'</li>'
      end
      html << '</ul>'
      html << '</div>'
    end
    raw html
  end

  def app_version
    Rails.configuration.app_version
  end

end
