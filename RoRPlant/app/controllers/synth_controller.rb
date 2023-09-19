class SynthController < ActionController::API

  SYNTH_THREAD_STYLES = ['EASE_OF_USE', 'EXTERNAL_PROCESS'];

  USE_SYNTH_THREAD_STYLE = 'EASE_OF_USE';

  def restart_synth
    # SynthesiseDataJob.new().run_in_thread()
    if (USE_SYNTH_THREAD_STYLE == 'EASE_OF_USE')
    	Rails.logger.info("Starting job workers as child process in this web server.");
        SynthesiseDataJob.new().run_as_new_process();
    elsif (USE_SYNTH_THREAD_STYLE == 'EXTERNAL_PROCESS')
    	Rails.logger.info("Use of external job worker process is assumed.");
    	SynthesiseDataJob.perform_later();
    else 
    	Rails.logger.error("Unknown job thread style!");    
    end
    # redirect_to root_path, status: :see_other
  end

  def stop_synth
  end
  
end
