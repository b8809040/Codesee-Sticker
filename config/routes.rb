Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root :to => 'sticker_generator#menu'

  get "sticker_generator" => 'sticker_generator#generate'

end
