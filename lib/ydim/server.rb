#!/usr/bin/env ruby
# Server -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'logger'
require 'needle'
require 'odba/id_server'
require 'rrba/server'
require 'ydim/autoinvoicer'
require 'ydim/client'
require 'ydim/currency_converter'
require 'ydim/currency_updater'
require 'ydim/debitors'
require 'ydim/factory'
require 'ydim/root_user'
require 'ydim/util'

module YDIM
	class Server
		SECONDS_IN_DAY = 24*60*60
		def initialize(config, logger)
			@serv = Needle::Registry.new
			@serv.register(:auth_server) { 
				auth = RRBA::Server.new
				root = RootUser.new(:root)
				root.name = config.root_name
				root.email = config.root_email
				root_key = config.root_key
				path = File.expand_path(root_key, config.conf_dir)
				path_or_key = File.exist?(path) ? path : root_key
				root.public_key = Util.load_key(path_or_key)
				auth.root = root
				auth
			}
			@serv.register(:clients) {
				ClientHandler.new(@serv)
			}
			@serv.register(:config) {
				config
			}
			@serv.register(:currency_converter) {
				ODBA.cache.fetch_named('currency_converter', self) { 
					CurrencyConverter.new	
				}
			}
			@serv.register(:debitors) {
				ODBA.cache.fetch_named('companies', self) {
					Debitors.new
				}
			}
			@serv.register(:factory) {
				Factory.new(@serv)
			}
			@serv.register(:id_server) { 
				ODBA.cache.fetch_named('id_server', self) {
					ODBA::IdServer.new
				}
			}
			@serv.register(:invoices) {
				ODBA.cache.fetch_named('invoices', self) { {} }
			}
			@serv.register(:logger) {
				logger
			}
			if(hour = config.autoinvoice_hour)
				repeat_at(hour, 'AutoInvoicer') {
					AutoInvoicer.new(@serv).run
				}
			end
			if(hour = config.currency_update_hour)
				if(@serv.currency_converter.known_currencies \
					 < @serv.config.currencies.size)
					CurrencyUpdater.new(@serv).run
				end
				repeat_at(hour, 'CurrencyUpdater') {
					CurrencyUpdater.new(@serv).run
				}
			end
			@sessions = []
      migrate_hosting_items
		end
		def login(client, name=nil, &block)
			@serv.logger.debug(client.__drburi) { 'attempting login' }
			session = @serv.auth_server.authenticate(name, &block)
			session.serv = @serv
			session.client = client
			@serv.logger.info(session.whoami) { 'login' }
			@sessions.push(session)
			session
		rescue Exception => error
			@serv.logger.error('unknown user') { 
				[error.class, error.message].join(' - ') }
			raise
		end
		def logout(session)
			@serv.logger.info(session.whoami) { 'logout' }
			@sessions.delete(session)
			nil
		end
		def ping
			true
		end
		private
    def migrate_hosting_items
      invoicer = AutoInvoicer.new(@serv)
      @serv.debitors.each_value { |deb|
        if(deb.debitor_type == 'dt_hosting' \
          && invoicer.hosting_autoinvoice(deb))
          deb.meta_eval { 
            define_method(:migrate_hosting_items) { 
              remove_instance_variable('@hosting_invoice_date')
              remove_instance_variable('@hosting_invoice_interval')
              remove_instance_variable('@hosting_items')
              remove_instance_variable('@hosting_price')
            }
          }
          deb.migrate_hosting_items
          deb.odba_store
        end
      }
    end
		def repeat_at(hour, thread_name)
			@autoinvoicer = Thread.new { 
				Thread.current.abort_on_exception = true
				loop {
					now = Time.now
					next_run = Time.local(now.year, now.month, now.day, hour)
					sleepy_time = next_run - now
					if(sleepy_time < 0)
						sleepy_time += SECONDS_IN_DAY
						next_run += SECONDS_IN_DAY
					end
					@serv.logger.info(thread_name) {
						sprintf("next run %s, sleeping %i seconds", 
										next_run.strftime("%c"), sleepy_time)
					}
					sleep(sleepy_time)
					yield
				}
			}
		end
	end
end
