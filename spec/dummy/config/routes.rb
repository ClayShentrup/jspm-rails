# frozen_string_literal: true

Rails.application.routes.draw do
  root 'pages#show'
  get 'admin', to: 'admin#show'
end
