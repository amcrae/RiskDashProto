require 'rails_helper'

RSpec.describe "authn middleware request", type: :request do
  
  it "contains no User when given no auth headers" do
    get root_path # "http://127.0.0.1:3000/"
    expect(response.body).to include("You are not logged in.")
  end

  it "returns the user2 User via Devise when given user2 tokens" do
    get(root_path + "/?a=/MOCKPROXY/user2")
    expect(response.body).to include("User McTwo")
  end
  
end  

# RSpec.describe "authn results", type: :system do
#   it "returns the user2 User via Devise when given user2 tokens" do
#     visit(root_path + "/?a=/MOCKPROXY/user2");
#     expect(page).to have_text("User McTwo");
#   end
# end
