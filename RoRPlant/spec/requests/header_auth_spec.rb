require 'rails_helper'

RSpec.describe PlantController, type: :controller do
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
  it "contains no User when given no auth headers" do
    # this get will run the controller.
    get :index # "http://127.0.0.1:3000/"
    # but no other Rails middleware ran before it, so the next line
    # raises "Devise could not find the `Warden::Proxy` instance on your request environment"
    expect(assigns(:usr_signed_in)).to eq(false);
  end

  it "returns the user2 User via Devise when given user2 tokens" do
    # the get will not route to middleware and controller
    # because this is a :controller type spec/example.
    get(root_path + "?a=/MOCKPROXY/user2")
    expect(assigns(:usr_signed_in)).to eq(true);
    expect(assigns(:cur_usr).email).to eq("user2@example.com")
  end
  
end

class ToDoList
  attr_reader :todo, :done
  
  def initialize(todolist)
    @todo = [] # ensure copy
    @todo += todolist
    @done = []
  end

  def complete_item(item)
    @todo.slice!(@todo.index(item))
    @done.append(item)
  end

end

RSpec.describe "authn middleware request", type: :request do
  # fixtures :users # does not work because 'password' is a property not a DB column

  it "contains no User when given no auth headers" do
    get root_path # "http://127.0.0.1:3000/"
    expect(session['warden.user.user.key']).to be_nil
    expect(response.body).to include("You are not logged in.")
  end

  it "returns the new user2 User via Devise when given user2 tokens" do
    get(root_path + "?a=/MOCKPROXY/user2")

    expect(session['warden.user.user.key']).not_to be_nil
    u2_ll1 = User.find_by(email: "user2@example.com").last_sign_in_at
    expect(u2_ll1).not_to be_nil
    expect(response.status).to eq(200)
    expect(response.body).to include("User McTwo")
  end

  it "returns the old user2 User via Devise when given user2 tokens" do
    # users(:u_two)

    get(root_path + "?a=/MOCKPROXY/user2")

    expect(session['warden.user.user.key']).not_to be_nil
    
    expect(response.status).to eq(200)
    expect(response.body).to include("User McTwo")
  end

  it "updates User attributes via Devise when given user2 tokens" do
    # users(:u_two)

    u2_0 = User.find_by(email: "user2@example.com")
    u2_ll0 = u2_0.last_sign_in_at
    u2_sic0 = u2_0.sign_in_count
    puts "last_sign_in_at #{u2_ll0}"
    expect(u2_ll0).not_to be_nil

    get(root_path + "?a=/MOCKPROXY/user2")
    
    puts "lookupid #{u2_0.id}"
    u2_1 = User.find(u2_0.id)
    u2_ll1 = u2_1.last_sign_in_at
    expect(u2_ll1).to satisfy("signin timestamp was incremented") { |x| x > u2_ll0}
    puts "TS #{u2_ll0} was updated #{u2_ll1}"
    expect(u2_1.sign_in_count).to satisfy("count incremented") { |x| x > u2_sic0 }
  end

  it "logs the authenticated user2 actions when given user2 tokens" do
    # users(:u_two)
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
      "HeaderAuthentication replied to Warden with user2@example.com",
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
    visit(root_path + "?a=/MOCKPROXY/user2");
    expect(page).to have_text("User McTwo");
    u2 = User.find_by(email: "user2@example.com")
    expect(u2).not_to be_nil
    visit(root_path);
    expect(page).to have_text("User McTwo");
  end

  it "returns the user1 User via Devise after local login with no tokens", driver: :selenium_headless do
    # puts "Using LETted object #{u_one()} #{u_one.email}"
    # u2_ll0 = u_one().last_sign_in_at
    u_one().save()
    visit(root_path + "?a=/MOCKPROXY/scrub");
    
    visit(root_path);
    click_button "Sign in"
    fill_in :with => "user1@example.com", :name => "user[email]"
    fill_in :with => "scoTTY", :name => "user[password]"
    click_button "Log in"

    expect(page).to have_text("Montgomery Scott");
  end
  
end
