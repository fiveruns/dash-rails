require 'test_helper'

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
    render :action => 'compound', :layout => 'simple'
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
        @metric = Fiveruns::Dash::TimeMetric.new(:render_time, :method => %w(ActionView::Template#render ActionView::PartialTemplate#render))
        Fiveruns::Dash::Rails.contextualize_action_pack(@metric)
        @metric.info_id = 42 # eh?
        
        unless ActionView::Template.included_modules.include?(Fiveruns::Dash::Rails::ViewContext)
          # FIXME: ugly duplication
          ActionView::Template.send(:include, 
                                    Fiveruns::Dash::Rails::ViewContext)
          ActionView::PartialTemplate.send(:include, 
                                           Fiveruns::Dash::Rails::ViewContext)
        end
      end
      
      teardown { Fiveruns::Dash::Rails::ViewContext.reset }
      
      should 'record one context for a template' do
        get :simple
        assert_metric_contains ['view', 'fixtures/simple']
      end
      
      context 'for a template and a layout' do
        
        setup { get :simple_layout }
        
        should 'record the layout' do
          assert_metric_contains ['view', 'layouts/simple']
        end
        
        should 'record the action' do
          assert_metric_contains ['view', 'fixtures/simple']
        end
        
      end
      
      context 'for a template, partial and layout' do
        
        setup { get :compound }
        
        should 'record the layout' do
          assert_metric_contains ['view', 'layouts/simple']
        end
        
        should 'record the action' do
          assert_metric_contains ['view', 'fixtures/compound']
        end
        
        should 'record the partial inside the action' do
          assert_metric_contains ['view', 'fixtures/compound', 'view', 'fixtures/_foo']
        end
        
      end
      
      should 'record contexts for a template, partial collection and layout' do
        get :compound_collection
        
        assert_metric_contains ['view', 'fixtures/_bar']
      end
    end
    
  end
  
  private
  
    def assert_metric_contains(context)
      data = @metric.data[:values]
      
      context_found = lambda do |hsh|
        result = false
        hsh[:context].each_slice(context.length) do |slice|
          result = true if slice == context
        end
        result
      end
      
      assert data.any?(&context_found), 
             "could not find #{context.inspect} in #{data.inspect}"
    end
  
end
