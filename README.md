# Carteiras

## About This Project

Carteiras is a personal Rails application I built and used between 2020 and 2023 to track investment portfolios for myself and close family members. It was created as a practical tool for consolidating brokerage activity, cash balances, portfolio positions, dividends, taxes, and performance across different accounts and asset classes.

This was not built as a commercial product or professional financial platform. It was a long-running personal software project: useful enough to support real financial tracking workflows, but developed primarily for my own needs, with the tradeoffs and rough edges that come from a tool built incrementally over several years.

The application includes features for registering assets, brokers, portfolios, operations, cash movements, dividends and other proceeds; importing brokerage statements; calculating current positions and historical profitability; comparing portfolio allocation against reference targets; fetching market prices from external sources; and supporting tax-related views for investment operations.

The public version of this repository has been sanitized to remove private financial data, credentials, and personal statement fixtures.

## Historical Project Notes

The notes below are preserved from the original personal project documentation.

Guia incompleto, mas quase

## Sugestão de setup em produção para Ubuntu 20.04

Guia inspirado em https://gorails.com/deploy/ubuntu/20.04

### Preparando o terreno
1. `adduser deploy`
1. `adduser deploy sudo` (adiciona ao grupo `sudo`)
1. Mudar para usuário `deploy` a partir daqui
1. Node.js repository
   `curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -`
1. Yarn repository e redis server 
```
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -`
   `echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list`
   `sudo add-apt-repository ppa:chris-lea/redis-server
```
1. Refresh our packages list with the new repositories `sudo apt-get update`
1. Install dependencies for compiiling Ruby along with Node.js and Yarn
```
   sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev dirmngr gnupg apt-transport-https ca-certificates redis-server redis-tools nodejs yarn
```

### Instalar Ruby
```
   git clone https://github.com/rbenv/rbenv.git ~/.rbenv
   echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
   echo 'eval "$(rbenv init -)"' >> ~/.bashrc
   git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
   echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
   git clone https://github.com/rbenv/rbenv-vars.git ~/.rbenv/plugins/rbenv-vars
   exec $SHELL
   rbenv install 3.0.1
   rbenv global 3.0.1
   ruby -v
   # ruby 3.0.1
```

`gem install bundler`

### Installing NGINX & Passenger
```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger focal main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update
sudo apt-get install -y nginx-extras libnginx-mod-http-passenger
if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then sudo ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ; fi
```

Now that we have NGINX and Passenger installed, we need to point Passenger to the correct version of Ruby.
```
# If you want to use the Vim for editing
sudo vim /etc/nginx/conf.d/mod-http-passenger.conf

# We simply want to change the passenger_ruby line to match the following:
passenger_ruby /home/deploy/.rbenv/shims/ruby;
```
Save this file and we'll start NGINX.

`sudo service nginx start`

Arquivo de configuração para nginx. Adiciona-lo em `/etc/nginx/sites-enabled/carteiras`

```
server {
 listen 80;
 listen [::]:80;
 
 server_name _;
 root /home/deploy/carteiras/current/public;

 passenger_enabled on;
 passenger_app_env production;

 # Allow uploads up to 100MB in size
 client_max_body_size 100m;

 location ~ ^/(assets|packs) {
   expires max;
   gzip_static on;
 }
  
}
```

### Banco de dados
```
# Pacote 'postgresql-server-dev-all' é necessário para instalar gem 'pg'
sudo apt-get install postgresql postgresql-contrib libpq-dev postgresql-server-dev-all
sudo su - postgres
createuser --pwprompt carteiras
createdb -O carteiras carteiras_production
exit
```

### Deploy code

Adicionar quaisquer variáveis de ambiente:
```
mkdir /home/deploy/carteiras
vi /home/deploy/carteiras/.rbenv-vars

# For Postgres
DATABASE_URL=postgresql://carteiras:PASSWORD@127.0.0.1/carteiras_production

SMTP_USERNAME=XXX
SMTP_PASSWORD=XXX

RAILS_MASTER_KEY=<rails-master-key>
SECRET_KEY_BASE=<secret-key-base>

RAPIDAPI_KEY=<rapidapi-key>
MARKETSTACK_ACCESS_KEY=<marketstack-key>

```

1. Criação de primeiro usuário com permissão de 'admin'
    1. Acesse `http://meuhost.com/users/sign_up`
    1. No rails console (`rails c -e production`):
        1. `user = User.find_by(email: 'meuemail@email.com')`
        1. `user.role = 'admin'`
        1. `user.save`
1. Para permitir que a integração com o MailChimp funcione, é necessário iniciar o Sidekiq
    1. Em um terminal `screen` próprio, iniciar o serviço executando `RAILS_ENV=production bundle exec sidekiq`



## Informações em mais detalhes

### Integração com um "SMTP em cloud" para envio de emails do sistema

E-mails para reset de senha ou possíveis notificações sobre atividades no sistema dependem da configuração de
um servidor SMTP, seja em servidor próprio ou usando um serviço em Cloud. Recomendamos o uso do serviço em cloud
[mailgun](http://mailgun.com) por ser simples de usar e permitir o envio de muitos emails mesmo na conta gratuita.

### Sidekiq e Redis

Sidekiq é uma biblioteca para Ruby/Rails que permite a execução de jobs de maneira asyncrona em segundo plano
e para funcionar usa o [redis](http://redis.io) como "backend". No momento o sidekiq é usado para interagir com a API do
MailChimp para adição/remoção de emails da lista de divulgação.
