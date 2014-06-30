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

module ScopedFinders

  def self.included( base ) #:nodoc:
    base.extend( ClassMethods )
  end

  module ClassMethods

    def scope_user

      extend SingletonMethods

      class << self
        alias_method_chain :find, :scope
        alias_method_chain :paginate, :scope
      end

    end

  end

  module SingletonMethods
    # Convenient scoped finder method that restricts lookups to the specified
    # :user. If the user has an admin role, the scoping is discarded totally,
    # since an admin _is a admin_.
    #
    # Example:
    #
    #   Domain.find(:all) # Normal behavior
    #   Domain.find(:all, :user => user_instance) # Will scope lookups to the user
    #
    def find_with_scope( *args )
      options = args.extract_options!
      user = options.delete( :user )

      unless user.nil? || user.has_role?( 'admin' )
        with_scope( :find => { :conditions => [ 'user_id = ?', user.id ] } ) do
          find_without_scope( *args << options )
        end
      else
        find_without_scope( *args << options )
      end
    end

    # Paginated find with scope. See #find.
    def paginate_with_scope( *args, &block )
      options = args.pop
      user = options.delete( :user )

      unless user.nil? || user.has_role?( 'admin' )
        with_scope( :find => { :conditions => [ 'user_id = ?', user.id ] } ) do
          paginate_without_scope( *args << options, &block )
        end
      else
        paginate_without_scope( *args << options, &block )
      end
    end

    # For our lookup purposes
    def search( params, page, user = nil )
      paginate :per_page => 5, :page => page,
        :conditions => ['name LIKE ?', "%#{params.chomp}%"],
        :user => user
    end
  end

end

ActiveRecord::Base.send( :include, ScopedFinders )
