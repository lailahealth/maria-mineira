class PagesController < ApplicationController
  COMING_SOON = {
    partners: {
      title: "Rede Maria Mineira",
      description: "A rede de parceiros da Maria Mineira está sendo estruturada — em breve você vai poder conhecê-la aqui."
    },
    about: {
      title: "Sobre a Maria Mineira",
      description: "Informação, acolhimento e apoio para mulheres mineiras. Esta página está sendo construída."
    }
  }.freeze

  COMING_SOON.each_key do |action|
    define_method(action) do
      page = COMING_SOON.fetch(action)
      render "pages/coming_soon", locals: { title: page[:title], description: page[:description] }
    end
  end
end
