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

class Bind9Controller < ApplicationController
    include GloboDns::Config

    respond_to :html, :json
    responders :flash

    before_filter :admin?,             :except => :schedule_export
    before_filter :admin_or_operator?, :only   => :schedule_export

    def index
        get_current_config
    end

    def configuration
        get_current_config
        respond_with(@current_config) do |format|
            format.html { render :text => @current_config if request.xhr? }
        end
    end

    def export
        if params['now'].try(:downcase) == 'true'
            @output, status = run_export
        else
            scheduled = Schedule.run_exclusive :schedule do |s|
                s.date
            end

            if scheduled.nil?
                @output = I18n.t('no_export_scheduled')
                status  = :ok
            elsif scheduled <= DateTime.now
                @output, status = run_export
            else
                @output = I18n.t('export_scheduled', :timestamp => scheduled)
                status  = :ok
            end
        end

        respond_to do |format|
            format.html { render :status => status, :layout => false } if request.xhr?
            format.json { render :status => status, :json   => { ((status == :ok) ? 'output' : 'error') => @output } }
        end
    end

    def schedule_export
        # clear schedule, because will run now
        schedule_date = Schedule.run_exclusive :schedule do |s|
            # round up to the nearest round minute, as it's the smallest time grain
            # supported by cron jobs
            s.date ||= Time.at(((DateTime.now + EXPORT_DELAY.seconds).to_i / 60.0 + 1).round * 60)
            # sleep 20   # Keep this commented. Only for tests
        end

        @output = I18n.t('export_scheduled', :timestamp => schedule_date.to_formatted_s(:short))
        respond_to do |format|
            format.html { render :status => status, :layout => false } if request.xhr?
            format.json { render :status => status, :json   => { 'output' => @output } }
        end
    end

    private

    def get_current_config
        bind_config = GloboDns::Config::Bind
        @master_named_conf = GloboDns::Exporter.load_named_conf(bind_config::Master::EXPORT_CHROOT_DIR, bind_config::Master::NAMED_CONF_FILE)
        @slaves_named_confs = bind_config::Slaves.map do |slave|
          GloboDns::Exporter.load_named_conf(slave::EXPORT_CHROOT_DIR, slave::NAMED_CONF_FILE) if SLAVE_ENABLED?
        end
    end

    def run_export
        # create exporter before everything because it's necesary in rescue block
        exporter = GloboDns::Exporter.new

        # clear schedule, because will run now
        Schedule.run_exclusive :schedule do |s|
            s.date = nil
        end

        # I can't keep lock during all export because can cause troubles
        # if export is too long. So, I fill date field and clear in the end.
        Schedule.run_exclusive :export do |s|
            if not s.date.nil?
                logger.warn "There are another process running. To run export again, remove row #{s.id} in schedules table"
                raise "There are another process running"
            end
            # register last execution in schedule
            s.date = DateTime.now
        end
        begin
            # sleep 60   # Keep this commented. Only for tests
            exporter.export_all(params['master-named-conf'], params['slave-named-conf'], :all => params['all'] == 'true', :keep_tmp_dir => true) # :abort_on_rndc_failure => false,
            [ exporter.logger.string, :ok ]
        ensure
            Schedule.run_exclusive :export do |s|
                s.date = nil
            end
        end

    rescue Exception => e
        logger.error "[ERROR] export failed: #{e}\n#{exporter.logger.string}\nbacktrace:\n#{e.backtrace.join("\n")}"
        [ e.to_s, :unprocessable_entity ]
    end

end
