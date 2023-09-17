# used only during initial development and kept for posterity
exit   # not meant to be run. documentation only.

rails new RoRPlant
cd RoRPlant

bin/bundle install

bin/rails generate model Asset uuid:string shortname:string asset_type:string readiness:string pof:float

bin/rails generate model Segment uuid:string shortname:string segtype:string segment:references operational:string asset:references

bin/rails generate model SegmentConnection uuid:string shortname:string segtype:string from_segment:integer to_segment:integer

bin/rails generate model MLocation uuid:string segment:references shortname:string

bin/rails generate model Measurement uuid:string mlocation:references timestamp:datetime qtype:string 'v:decimal{16,6}' uom:string 

bin/rails db:migrate

bin/rails generate scaffold_controller Asset
bin/rails generate scaffold_controller Segment
bin/rails generate scaffold_controller SegmentConnection
bin/rails generate scaffold_controller MLocation
bin/rails generate scaffold_controller Measurement

bin/rails generate delayed_job:active_record
bin/rails db:migrate

bin/rails generate job SynthesiseData
bin/rails generate controller Plant index start_synth stop_synth

