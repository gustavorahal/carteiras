require 'test_helper'

class SecurityRenderingTest < ActionView::TestCase
  test 'titulo_pagina escapa texto recebido' do
    render partial: 'common/titulo_pagina', locals: { titulo: '<script>alert(1)</script>' }

    assert_includes rendered, '&lt;script&gt;alert(1)&lt;/script&gt;'
    refute_includes rendered, '<script>alert(1)</script>'
  end

  test 'titulo_pagina preserva fragmentos html explicitamente seguros' do
    render partial: 'common/titulo_pagina', locals: { titulo: ['Carteira ', link_to('Example', '/example')] }

    assert_includes rendered, 'Carteira <a href="/example">Example</a>'
  end
end
