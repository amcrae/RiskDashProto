# RiskDashProto
*An output of learning Ruby On Rails*

The application domain chosen for this mini project is a prototype industrial plant risk monitoring dashboard.

* `plan/` contains basically just requirements.
* `rails_scaffolding.sh` is a list of rails generation tasks done to set up first versions of a lot of files.
* `RoRPlant/` contains the implementation in Ruby on Rails.

<img src='./screenshots/RiskDashProto%20Screenshot%20from%202023-09-22%2014-35.png' alt="Recent screenshot showing a live graph and a motor disabled">


## Install

1. `git clone "https://github.com/amcrae/RiskDashProto.git" RiskDashProto`

2. `cd RiskDashProto/RoRPlant`

3. `bin/bundle install`

4. `bin/rails db:create db:migrate db:seed`


## Start

1. `cd RiskDashProto/RoRPlant`

2. `bin/rails server`

3. Browse to http://127.0.0.1:3000

