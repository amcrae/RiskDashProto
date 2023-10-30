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

RSpec.describe "authn middleware request", type: :request do
  
  it "contains no User when given no auth headers" do
    get root_path # "http://127.0.0.1:3000/"
    expect(session['warden.user.user.key']).to be_nil
    expect(response.body).to include("You are not logged in.")
  end

  it "returns the user2 User via Devise when given user2 tokens" do
    get(root_path + "?a=/MOCKPROXY/user2")
    expect(response.status).to eq(200)
    expect(session['warden.user.user.key']).not_to be_nil
    expect(response.body).to include("User McTwo")
  end
  
end

RSpec.describe "Page authn results", type: :system do
  before do
    driven_by(:selenium_headless);
  end

  it "returns the user2 User via Devise when given user2 tokens", driver: :selenium_headless do
    visit("http://127.0.0.1:3000" + root_path + "?a=/MOCKPROXY/user2");
    expect(page).to have_text("User McTwo");
  end
end
