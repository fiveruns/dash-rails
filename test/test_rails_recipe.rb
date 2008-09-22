require 'test_helper'

class TestRailsRecipe < Test::Unit::TestCase
  context "fiveruns_dash_rails plugin" do
    setup do
      Fiveruns::Dash.recipes.clear
    end
  
    should "create load recipes for activerecord, actionpack and rails" do
      assert_equal 0, Fiveruns::Dash.recipes.size

      require 'fiveruns_dash_rails'
      Fiveruns::Dash::Rails.load_recipes
    
      assert_equal 3, Fiveruns::Dash.recipes.size
    
      assert_equal [:actionpack.to_s, :activerecord.to_s, :rails.to_s], Fiveruns::Dash.recipes.map{|r| r.first.to_s}.sort
    end
  end
end
