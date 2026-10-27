# Troca um método de classe por um valor fixo durante o bloco — o minitest 6 não
# traz mais o Object#stub, e os testes do chat precisam desligar as chamadas
# externas (IA, ViaCEP, geocodificação) que a chave do .env ligaria.
module SingletonStub
  def with_singleton_stub(klass, name, value)
    original = klass.method(name)
    klass.define_singleton_method(name) { |*, **| value }
    yield
  ensure
    klass.define_singleton_method(name, original)
  end
end
