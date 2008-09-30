require 'test_helper'

RAILS_ROOT = 'ZOINKS'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

class FixturesController < ActionController::Base
  
  append_view_path File.join(File.dirname(__FILE__))
  
  def simple
    render :action => 'simple', :layout => false
  end
  
  def simple_layout
    render :action => 'simple', :layout => 'simple'
  end
  
  def compound
  end
  
  def compound_collection
    @numbers = (1..5).to_a
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
        assert_metric_contains ['view', 'fixtures/simple']
      end
      
      should 'record two contexts for a template and a layout' do
        get :simple_layout
        assert_metric_contains ['view', 'layouts/simple']
      end
      
      should 'record three contexts for a template, partial and layout' do
        get :compound
        assert_metric_contains ['view', 'simple/_foo']
      end
      
      should 'record contexts for a template, partial collection and layout' do
        get :compound_collection
        
        assert_metric_contains ['view', 'simple/_foo']
      end
    end
    
  end
  
  private
  
    def assert_metric_contains(ns)
      data = @metric.data[:values]
      assert data.select { |hsh| hsh[:context] == ns }
    end
  
end
