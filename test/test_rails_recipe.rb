require 'test_helper'

class TestRailsRecipe < Test::Unit::TestCase
  def test_create_recipes
    assert_equal 0, Fiveruns::Dash.recipes.size
    
    require 'fiveruns_dash_rails'
    Fiveruns::Dash::Rails.load_recipes
    
    assert_equal 3, Fiveruns::Dash.recipes.size
    assert_equal [:actionpack.to_s, :activerecord.to_s, :rails.to_s], Fiveruns::Dash.recipes.map{|r| r.first.to_s}.sort
  end  
end