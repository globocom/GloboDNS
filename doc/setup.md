## Requirements

The requirements to install Dns-Api:

* ruby >= 1.9.2
* rvm >= 1.11.3.5 (it's not mandatory)
* http server apache >= 2.2.17
* mysql server >= 5.6.10
* and all gems in Gemfile (bundle install)

The requirements to run bind server:

* bind >= 9.9.2

## Installing

#### In order to install dnsapi into your enviroment you'll need to:

1. Clone the project into the desired path.

        $ git clone https://github.com/globocom/Dns-Api.git dnsapi

2. Install all dependencies with bundle, if you don't to use rvm, please skip next 4 comands

        $ rvm install ruby-1.9.2
        $ rvm 1.9.2
        $ rvm gemset create dnsapi
        $ rvm use 1.9.2@dnsapi
        $ cd dnsapi
        $ bundle install

3. Into the "config/globodns.yml" file you will find all the configurantion parameters to make DNSAPI properly work with your own Bind specifications.

        development: &devconf
            bind_master_user:            'named'
            bind_master_host:            'my_bind_server'
            bind_master_ipaddr:          'my_bind_ip_address'
        ... (cont.) ...

4. Thus, still on globodns.yml file, you have a parameter called "export_(master|slave)_chroot_dir". This path need to be created manually, to handle version control and tmp file holder. Run this command as 'dnsapi' user:

        $ mkdir -p tmp/named/chroot_{master,slave}

5. In config/database.yml you can set the suitable database for you.

        development:
          adapter:  mysql2
          database: dnsapi
          hostname: localhost
          username: root
          password:

6. On the bind server, the user running the api, need to have the same uid and gid and also be member of the Bind (named daemon) group.
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


7. Additionally you have to generate a public/private rsa key pair (ssh-keygen) for 'dnsapi' user in DNSAPI server. Copy this public key ($HOME/.ssh/id_rsa.pub) to 'dnsapi' user in BIND server ($HOME/.ssh/authorized_keys).


8. Then you can setup up your favourite webserver and your preferred plugin (i.e. apache + passenger).