require 'test_helper'

RAILS_ROOT = 'ZOINKS'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

class FixturesController < ActionController::Base
  
  append_view_path File.join(File.dirname(__FILE__))
  
  def simple
    render :action => 'simple'
  end
  
  def simple_layout
    render :action => 'simple', :layout => 'simple'
  end
end

class TestRailsRecipe < ActionController::TestCase
  tests FixturesController
  
  context "fiveruns_dash_rails plugin" do
    setup do
      Fiveruns::Dash.recipes.clear
    end
  
    should "load recipes for activerecord, actionpack and rails" do
      assert_equal 0, Fiveruns::Dash.recipes.size

      Fiveruns::Dash::Rails.load_recipes
    
      assert_equal 3, Fiveruns::Dash.recipes.size
    
      assert_equal [:actionpack.to_s, :activerecord.to_s, :rails.to_s], 
                   Fiveruns::Dash.recipes.map{|r| r.first.to_s}.sort
    end
    
    context "view recipe" do
      
      setup do
        @metric = Fiveruns::Dash::TimeMetric.new(:render_time, :method => 'ActionView::Template#render')
        Fiveruns::Dash::Rails.contextualize_action_pack(@metric)
        @metric.info_id = 42 # eh?
      end
      
      should 'record one context for a template' do
        get :simple
        
        assert_equal ['view', 'fixtures/simple'], 
                     @metric.data[:values].first[:context]
      end
      
      should_eventually 'record two contexts for a template and a layout'
      
      should_eventually 'record three contexts for a template, partial and layout'
      should_eventually 'record contexts for a template, partial collection and layout'
    end
  end
end
