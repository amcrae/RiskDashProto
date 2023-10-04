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

## Optionally Reconfigure Job Processing
There are two ways to run the queued jobs: within the web server or in an external worker pool process.  
By default this project is configured to make starting the demo slightly easier by requiring only one process (the 'puma' web server) to be executed. However starting the job workers inside the web server means both puma processes have to be killed (with `kill -9`) to stop ruby, which is less convenient.

 * Edit the file `RoRPlant/app/controllers/synth_controller.rb`
 * Set the constant `USE_SYNTH_THREAD_STYLE` to one of the strings in the `SYNTH_THREAD_STYLES` array.
 * If you choose `EXTERNAL_PROCESS` you need to execute `delayed_job run` in a separate terminal window before running the rails server. `RoRPlant/bin/delayed_job run`

## Start

1. `cd RiskDashProto/RoRPlant`

2. If you configured SynthController with `EXTERNAL_PROCESS`, start Delayed Job in a separate console (see above).

3. `bin/rails server`

4. Browse to http://127.0.0.1:3000

## View the example system

1. Note the assets can be failed or repaired by clicking the bomb or wrench buttons respectively.
2. Start the Synthesise Data task to begin generated fake motor data from Perlin noise.
3. After the front end has subscribed (takes a few seconds the first time) the live data will be charted in a moving window.
4. Failing the 1stMotor asset results in nulls being sent as the data.
5. The data synthesis is coded to stop by itself after a while.

