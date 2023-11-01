require 'rails_helper'
require 'misc_util'

# Current problem: Only a :request -type spec
#  will drive the whole Rack middleware chain, which is
#  needed for running the header authentication step.
#  But only a :controller -type spec will get access to
#  a controller as a subject and this type does not run the
#  whole request chain (the results of which are expected
#  to be mocked such as injecting request headers as part
#  of the setup prior to a GET call.)
# There is no out-of-the-box RSpec standard spec type which
#  can start with an HTTP request and end with the result
#  of the final controller object as the test subject.

# Use Request-type spec since it is the simplest type that drives middleware.
RSpec.describe "authn middleware request", type: :request do
  # fixtures :users # does not work because 'password' is a property not a DB column

  let!(:u_two) { 
    u2 = User.new(
      auth_type: "EXTERNAL",
      email: "user2@example.com", password: "abc_123", 
      full_name: "User McTwo", role_name: "TECHNICIAN"
    );
    u2.save();
    return u2
  }

  it "contains no User when given no auth headers" do
    get root_path # "http://127.0.0.1:3000/"
    expect(session['warden.user.user.key']).to be_nil
    expect(response.body).to include("You are not logged in.")
  end

  it "returns the novel user2 User via Devise when given user2 tokens" do
    Rails.logger.debug "Request-type test 1"
    get(root_path + "?a=/MOCKPROXY/user2")
    puts "session == #{session.to_json}"
    expect(session['warden.user.user.key']).not_to be_nil
    u2 = User.find_by(email: "user2@example.com")
    expect(u2).not_to be_nil
    expect(u2.auth_type).to eq("EXTERNAL")
    expect(response.status).to eq(200)
    expect(response.body).to include("User McTwo")
  end

  it "returns the old user2 User via Devise when given user2 tokens" do
    Rails.logger.debug "Request-type test 2"
    # users(:u_two)
    u_two()

    get(root_path + "?a=/MOCKPROXY/user2")

    puts "session == #{session.to_json()}"
    expect(session['warden.user.user.key']).not_to be_nil
    expect(response.status).to eq(200)
    expect(response.body).to include("User McTwo")
  end

  it "updates User attributes via Devise when given user2 tokens" do
    Rails.logger.debug "Request-type test 3"
    # users(:u_two)
    u_two()
    u2_0 = User.find_by(email: "user2@example.com")
    u2_csi0 = u2_0.current_sign_in_at
    u2_sic0 = u2_0.sign_in_count
    puts "last_sign_in_at #{u2_csi0}"
    expect(u2_sic0).not_to be_nil

    get(root_path + "?a=/MOCKPROXY/user2")
    
    puts "lookup user id #{u2_0.id}"
    u2_1 = User.find(u2_0.id)
    u2_csi1 = u2_1.current_sign_in_at
    u2_sic1 = u2_1.sign_in_count
    puts "CSI ts #{u2_csi0} was updated #{u2_csi1}"
    expect(u2_sic1).to satisfy("count incremented by 1") { |x| x == u2_sic0 + 1 }
    expect(u2_csi1).not_to be_nil
  end

  it "logs the authenticated user2 actions when given user2 tokens" do
    Rails.logger.debug "Request-type test 4"
    # users(:u_two)
    u_two()

    logfile = Rails.logger.instance_variable_get("@logdev").instance_variable_get("@dev")
    logname = logfile.path

    first_count = 0
    File.open(logname, "r") do |file|
      until file.eof
        file.readline
        first_count += 1
      end
    end

    get(root_path + "?a=/MOCKPROXY/user2")
    
    counter = 0
    find_goals = [
      "HeaderAuthentication replied to Warden with account for user2@example.com",
      "*** User user2@example.com executing"
    ]
    progress = ToDoList.new(find_goals)
    File.open(logname, "r") do |file|
      puts "resuming log from line #{first_count}..."
      until file.eof || counter == first_count
        file.readline
        counter += 1
      end
      until file.eof || progress.todo.size() == 0
        line = file.readline
        for item in progress.todo 
          if line.include?(item)
            progress.complete_item(item)
            puts line
          end
        end
      end
    end
    expect(progress.todo.size()).to eq(0)
  end
  
end

RSpec.describe "Page authn results", type: :system do
  before do
    driven_by(:selenium_headless);
  end

  let!(:u_one) { 
    u1 = User.new(
      auth_type: "LOCAL",
      email: "user1@example.com", password: "scoTTY", full_name: "Montgomery Scott", role_name: "TECHNICIAN"
    );
    u1.save();
    return u1
  }

  it "returns the user2 User via Devise when given user2 tokens", driver: :selenium_headless do
    Rails.logger.debug "Browser test 1"
    visit(root_path + "?a=/MOCKPROXY/user2");
    # User should have been created from tokens at this point
    expect(page).to have_text("User McTwo");
    u2 = User.find_by(email: "user2@example.com")
    expect(u2).not_to be_nil
    # And identity persists in session over multiple requests.
    visit(root_path);
    expect(page).to have_text("User McTwo");
  end

  it "returns the user1 User via Devise after local login with no tokens", driver: :selenium_headless do
    Rails.logger.debug "Browser test 2"
    # puts "Using LETted object #{u_one()} #{u_one.email}"
    u_one().save()
    visit(root_path + "?a=/MOCKPROXY/scrub");
    
    visit(root_path);
    click_button "Sign in"
    fill_in :with => "user1@example.com", :name => "user[email]"
    fill_in :with => "scoTTY", :name => "user[password]"
    click_button "Log in"

    expect(page).to have_text("Montgomery Scott");
  end

  it "No user is loged in after the user2 User ceases sending authentication tokens", driver: :selenium_headless do
    Rails.logger.debug "Browser test 3"
    visit(root_path + "?a=/MOCKPROXY/user2");
    # User should have been created from tokens at this point
    expect(page).to have_text("User McTwo");
    visit(root_path + "?a=/MOCKPROXY/scrub");
    # And identity persists in session over multiple requests.
    visit(root_path);
    expect(page).to have_text("You are not logged in.");
  end
  
end
