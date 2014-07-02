## Requirements

**Dns-Api server**:

* git >= 1.7.12.2
* openssl
* openssl-devel
* openssh-server
* openssh-client
* rsync
* mysql-server >= 5.6.10
* mysql-devel >= 5.6.10
* mysql-shared >= 5.6.10
* bind >= 9.9.2
* ruby >= 1.9.3
   * rvm >= 1.11.3.5 (it's not mandatory)
   * rubygems >= 1.3.7
   * bundler >= 1.0.0
   * all gems in Gemfile (bundle install)
* http server
* sudo

**Bind server**:

* bind >= 9.9.2 (already configured and running)
* bind-chroot

## Installing

In order to install dnsapi into your enviroment you'll need to follow the steps bellow, please don't skip any step!

**1. User and groups**

On the bind server, the user running the api, need to have the same uid and gid and also be member of the Bind (named daemon) group.
    * Note: DNSAPI process the files on your own machine and then transfer the desired files already modified through rsync to the bind server. So you need to make this access possible and take care with your specific file permissions.

    my dnsapi server:

        $ id dnsapi
        uid=12386(dnsapi) gid=12386(dnsapi) groups=25(named),12386(dnsapi)
        $ id named
        uid=25(named) gid=25(named) groups=25(named)
        $groups dnsapi named
        dnsapi : dnsapi named
        named : named
        $

    my bind server:

        $id dnsapi
        uid=12386(dnsapi) gid=12386(dnsapi) groups=12386(dnsapi),25(named)
        $id named
        uid=25(named) gid=25(named) groups=25(named)
        $ groups dnsapi named
        dnsapi : dnsapi named
        named : named
        $

**2. Copy project**

Clone the project into the desired path.

    $ git clone https://github.com/globocom/Dns-Api.git dnsapi

**3. Install all requirements gems**

Install all dependencies with bundle, if you don't to use rvm, please skip next 2 comands

    $ rvm install 1.9.3
    $ rvm --create use 1.9.3@dnsapi
    $ cd dnsapi
    $ bundle install --deployment --without=test,development 

**4. Setup your bind configurations**

Into the "config/globodns.yml" file you will find all the configurantion parameters to make DNSAPI properly work with your own Bind specifications.

    development: &devconf
        bind_master_user:            'named'
        bind_master_host:            'my_bind_server'
        bind_master_ipaddr:          'my_bind_ip_address'
    ... (cont.) ...

**5. Database configuration**

In config/database.yml you can set the suitable database for you.

    development:
      adapter:  mysql2
      database: dnsapi
      hostname: localhost
      username: root
      password:

**6. Sudoers file**

Dns-Api uses 'named-checkconf' command to verify configuration file syntax, this command has to be called as 'root' user. For that reason, we need to allow the user 'dnsapi' can run this command as root on sudoers file.

    # visudo

And insert this line on that

    dnsapi          ALL=(ALL) NOPASSWD: /usr/sbin/named-checkconf

**7. Bind Server pre requisites**

  * **ssh keys**

  Additionally you have to generate a public/private rsa key pair (ssh-keygen) for 'dnsapi' user in DNSAPI server. Copy this public key ($HOME/.ssh/id_rsa.pub) to 'dnsapi' user in BIND server ($HOME/.ssh/authorized_keys).

  This step is necessary for transfer files from Dns-Api to Bind server with no password.

  * **bind confs**

    Logged in as 'root' user on bind server, run these following commands:

        # mv /etc/named.conf /etc/named
        # ln -s /etc/named/named.conf /etc/named.conf
        # rndc-confgen

    After run 'rndc-confgen' command, you have to follow the instructions from the 'rndc-confgen' command output.

    The referred files from 'rndc-confgen' are:
     - create '/etc/named/rndc.conf'
     - edit '/etc/named/named.conf'.

Finally, you have to start your bind server:

    # service named start


**8. Prepare the database**

Now, you have to create the database schema, migrate and populate it.

An admin user will be create: *admin@example.com/password*

    $ RAILS_ENV=test rake db:setup
    $ RAILS_ENV=test rake db:migrate
    $ RAILS_ENV=test rake globodns:chroot:create

**9. Import bind files to Dns-Api**

Given your bind server is already up and running, your "config/globodns.yml" was setup correctly, let's import
all bind configurations into Dns-Api: 

    $ RAILS_ENV=test ruby script/importer --remote


**10. Setup the webserver**

Then you can setup up your favourite webserver and your preferred plugin (i.e. apache + passenger).

Use the 'public' directory as your DocumentRoot path on httpd server.
