# CNES (Cadastro Nacional de Estabelecimentos de Saúde) — identificador oficial das
# unidades de saúde no dicionário de dados do e-SUS/DATASUS. Os demais campos do
# dicionário já têm equivalente na tabela (ibge → municipality, logradouro →
# address, bairro → neighborhood, latitude/longitude). Nulo para equipamentos que
# não são de saúde (DEAM, CRAS, CREAS…); único quando presente, para recargas da
# base de UBS não duplicarem estabelecimentos.
class AddCnesToTerritorialFacilities < ActiveRecord::Migration[8.1]
  def change
    add_column :territorial_facilities, :cnes, :string
    add_index :territorial_facilities, :cnes, unique: true, where: "cnes IS NOT NULL"
  end
end
