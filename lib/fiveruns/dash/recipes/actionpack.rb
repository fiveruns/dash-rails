Fiveruns::Dash.register_recipe :actionpack, :url => 'http://dash.fiveruns.com' do |recipe|
  
  recipe.time :response_time, :method => 'ActionController::Base#perform_action', :mark => true
  recipe.counter :requests, 'Requests', :incremented_by => 'ActionController::Base#perform_action'
  
  targets = []
  if defined?(ActionView::Renderable)
    targets << 'ActionView::Renderable#render'
  else
    targets << 'ActionView::Template#render' if defined?(ActionView::Template)
    targets << 'ActionView::PartialTemplate#render' if defined?(ActionView::PartialTemplate)
  end
  if !targets.empty?
    recipe.time :render_time, :method => targets
  else
    Fiveruns::Dash.logger.warn 'Collection of "render_time" unsupported for this version of Rails'
  end
  
end
