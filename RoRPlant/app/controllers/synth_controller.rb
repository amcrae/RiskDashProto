class SynthController < ActionController::API
  def restart_synth
    SynthesiseDataJob.new().run_in_thread()
    redirect_to root_path, status: :see_other  
  end

  def stop_synth
  end
  
end
