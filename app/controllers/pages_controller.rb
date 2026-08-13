class PagesController < ApplicationController
  COMING_SOON = {
    map: {
      title: "Mapa",
      description: "O mapa com equipamentos e serviços em Minas Gerais está sendo construído."
    },
    violence_types: {
      title: "Tipos de violência",
      description: "Os conteúdos educativos sobre tipos de violência, fornecidos pela equipe Maria Mineira, estão sendo organizados aqui."
    },
    rights: {
      title: "Direitos",
      description: "Os conteúdos sobre direitos das mulheres estão sendo organizados aqui."
    },
    policies: {
      title: "Políticas e programas",
      description: "Os conteúdos sobre políticas públicas e programas para mulheres estão sendo organizados aqui."
    },
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
