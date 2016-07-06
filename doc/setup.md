## Requirements

**GloboDNS server**:

* git >= 1.7
* openssl
* openssl-devel
* openssh-server
* openssh-client
* rsync
* mysql-server >= 5.1.73
* mysql-devel >= 5.1.73
* mysql-shared >= 5.1.73
* bind >= 9.9.2
* ruby >= 1.9.3
   * rvm >= 1.11.3.5 (it's not mandatory)
   * rubygems >= 1.3.7
   * bundler >= 1.0.0
   * all gems in Gemfile (bundle install)
* http server
* sudo
* gcc
* gcc-c++
* gnupg

**Bind server**:

* bind >= 9.9.2 (already configured and running)
* bind-chroot
* rsync

## Installing

In order to install GloboDNS in your enviroment you'll need to follow the steps bellow, please don't skip any step!

**1. User and groups**

On the bind server, the user running the API needs to have the same uid and gid and also be member of the Bind (named daemon) group.
    * Note: GloboDNS processes the files on your own machine and then transfer the desired files already modified through rsync to the bind server. So you need to make this access possible and take care of your specific file permissions.

    my GloboDNS server:

        $ id globodns
        uid=12386(globodns) gid=12386(globodns) groups=25(named),12386(globodns)
        $ id named
        uid=25(named) gid=25(named) groups=25(named)
        $groups globodns named
        globodns : globodns named
        named : named
        $

    my bind server:

        $id globodns
        uid=12386(globodns) gid=12386(globodns) groups=12386(globodns),25(named)
        $id named
        uid=25(named) gid=25(named) groups=25(named)
        $ groups globodns named
        globodns : globodns named
        named : named
        $

**2. Copy project**

Clone the project into the desired path.

    $ git clone https://github.com/globocom/GloboDNS.git globodns

**3. Install all requirements gems**

Install all dependencies with bundle, if you don't use rvm, please skip next 2 comands

    # rvm install 1.9.3
    $ rvm --create use 1.9.3@globodns
    $ cd globodns
    $ bundle install --deployment --without=test,development 

**4. Setup your bind configurations**

In the "config/globodns.yml" file, you will find all configurations parameter to make GloboDNS work properly with your own Bind specifications.

    development: &devconf
        bind_master_user:            'named'
        bind_master_host:            'my_bind_server'
        bind_master_ipaddr:          'my_bind_ip_address'
    ... (cont.) ...

**5. Database configuration**

In config/database.yml you can set the database suitable for you.

    development:
      adapter:  mysql2
      database: globodns
      hostname: localhost
      username: root
      password:

**6. Sudoers file**

GloboDNS uses 'named-checkconf' command to verify configuration file syntax, this command has to be called as 'root' user. For that reason, we need to allow user 'globodns' to run this command as root on sudoers file.

    # visudo

And insert this line on that

    globodns          ALL=(ALL) NOPASSWD: /usr/sbin/named-checkconf
TIP:Not at the end of the file (just above root configuration)

**7. Bind Server pre requisites**

  * **ssh keys**

  Additionally you have to generate a public/private rsa key pair (ssh-keygen) for 'globodns' user in GloboDNS server. Copy this public key ($HOME/.ssh/id_rsa.pub) to 'globodns' user in BIND server ($HOME/.ssh/authorized_keys).

  This step is necessary to transfer files from GloboDNS to Bind server without the need to enter a password.

TIP: To do this task easily use the command ssh-copy-id :)

  * **bind confs**

    Logged in as 'root' user on bind server, run these following commands:

        # mv /etc/named.conf /etc/named
        # ln -s /etc/named/named.conf /etc/named.conf
        # rndc-confgen -s <BIND_ADDRESS>

    After run 'rndc-confgen' command, you have to follow the instructions from the 'rndc-confgen' command output.

    The referred files from 'rndc-confgen' are:
     - create '/etc/named/rndc.conf'
     - edit '/etc/named/named.conf'

  * **file permissions**

        # chown -R globodns.named /etc/named


Finally, you have to start your bind server:

    # service named start


**8. Prepare the database**

Now, you have to create the database schema, migrate and populate it.

An admin user will be create: *admin@example.com/password*
TIP: Check if the mysql server is UP before the rake command 

    $ rake db:setup
    $ rake db:migrate
    $ rake globodns:chroot:create

**9. Import bind files to GloboDNS**

Given your bind server is already up and running and your "config/globodns.yml" was setup correctly, let's import
all bind configurations into GloboDNS: 

    $ ruby script/importer --remote

**10. Generating rndc key on GloboDNS**

You have to generate a keyfile on GloboDNS to run 'rndc reload'. As root, run the following command on GloboDNS server:

    # rndc-confgen -a -u globodns

**11. Setup the webserver**

Then you can setup up your favourite webserver and your preferred plugin (i.e. apache + passenger).

Use the 'public' directory as your DocumentRoot path on httpd server.

for your test, you can run:

     $ bundle exec unicorn_rails

TIP: Problems ? SELinux and/or iptables are running ? 

**12. Using OAuth login**

1) First you have to enable the use of OmniAuth at file [config/application.rb](./config/application.rb).

         config.omniauth = true



2) Add the provider settings at file [config/initializers/omniauth.rb](./config/initializers/omniauth.rb).

3) Set the logout path at [app/controllers/application_controller.rb](./app/controllers/application_controller.rb)

        def logout
            sign_out current_user
            path = new_user_session_url
            client_id = Rails.application.secrets.oauth_provider_client_id
            redirect_to "https://oauthprovider.com/logout"+ "?client_id=#{client_id}&redirect_uri=#{path}" # set providers logout uri
        end


4) Add the provider configured in step 2 at the [User model](./app/models/user.rb).
    
        ...
        devise :omniauthable, :omniauth_providers => [:oauth_provider] # change ':oauth_provider'
        ...
        def self.from_api(auth)
            ...
            if user.nil?
                ...
                provider: :oauth_provider, # also change 
                ...    
            else
                ...
                provider: :oauth_provider, # also change 
            ...


5) Change the [routes](config/routes.rb) settings. Uncomment the following line and change 'oauthprovider' to the name of the OAuth provider.

        # get 'auth/sign_in' => redirect('users/auth/oauthprovider'), :as => :new_user_session

6) Finally, you need to change the [OmniauthCallbacksController](https://github.com/globocom/GloboDNS/blob/production/app/controllers/omniauth_callbacks_controller.rb).

    Uncomment the whole function and do the necessary changes, such ass:
    
        def <YOUR_PROVIDER> 
    
    Also change 
    
        set_flash_message(:notice, :success, :kind => "<YOUR PROVIDER HERE>") if is_navigational_format?

    Lastly

        session["devise.<YOUR_PROVIDER>_data"] = request.env["omniauth.auth"]



**NOTE**: You probably will need to add the OAuth provider gem at Gemfile.