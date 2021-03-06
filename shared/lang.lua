LANG = {
    getLocale = function()
        repeat Wait(50)
        until GlobalState['hydrus:lang'] ~= nil

        return GlobalState['hydrus:lang']
    end,
    ['en'] = {
        ['error'] = 'An error occurred: :error',
        ['contact.support'] = 'Contact Support',
        ['credits.insufficient'] = 'Insufficient credits',
        ['redeem'] = 'Redeem',
        ['confirm'] = 'Confirm',
        ['redeem.one'] = 'Redeem for :amount credit',
        ['redeem.many'] = 'Redeem for :amount credits',
        ['redeemed'] = 'Redeemed!',
        ['categories'] = 'CATEGORIES',
        ['select.option'] = 'Select an option',
        ['select.home'] = 'Select a home',
        ['select.vehicle'] = 'Select a vehicle',
        ['insert.phone'] = 'Type the desired number',
        ['already.owned.self'] = 'Already owned by the player',
        ['already.owned.someone'] = 'Already owned by someone',
        ['autofilled'] = 'Filled automatically',
        ['framework.detected'] = 'Framework detected (:name)',

        ['connection.error'] = 'Unable to establish connection -> :error',
        ['connection.ok'] = 'Connection established',
        ['connection.outage'] = 'Five consecutives errors ocorrured, rtc outage?\nTrying again in 60 seconds...',
        ['extension.not_found'] = 'Fail to load extension :name -> File not found',
        ['extension.error'] = 'Fail to load extension :name -> :error',
        ['testdrive'] = 'Test drive',

        ['nui.title'] = 'REDEEM BENEFITS',
        ['notify.title'] = 'BENEFITS',
        ['notify.subtitle.one'] = 'You have 1 redeemable item',
        ['notify.subtitle.many'] = 'You have up to :count redeemable items',
        ['notify.footer'] = 'Type /store to redeem',

        ['chat.template'] = '{0} just reedemed {1}',
        ['vip.template.group'] = 'Your group {0} expires at {1}',
        ['vip.template.house'] = 'Your residence {0} expires at {1}',
        ['vip.template.vehicle'] = 'Your vehicle {0} expires at {1}',
    },
    ['pt'] = {
        ['error'] = 'Um erro ocorreu: :error',
        ['contact.support'] = 'Entre em contato com o suporte',
        ['credits.insufficient'] = 'Cr??ditos insuficientes',
        ['redeem'] = 'Resgatar',
        ['confirm'] = 'Confirmar',
        ['redeem.one'] = 'Resgatar por :amount cr??dito',
        ['redeem.many'] = 'Resgatar por :amount cr??ditos',
        ['redeemed'] = 'Voc?? resgatou',
        ['categories'] = 'CATEGORIAS',
        ['select.option'] = 'Selecione uma op????o',
        ['select.home'] = 'Selecione uma resid??ncia',
        ['select.vehicle'] = 'Selecione um ve??culo',
        ['insert.phone'] = 'Insira o n??mero desejado',
        ['already.owned.self'] = 'O jogador j?? possui',
        ['already.owned.someone'] = 'Outro jogador j?? possui',
        ['autofilled'] = 'Preenchido automaticamente',
        ['framework.detected'] = 'Base identificada (:name)',

        ['connection.error'] = 'Falha ao se conectar com o sistema -> :error',
        ['connection.ok'] = 'Conex??o estabelecida',
        ['connection.outage'] = 'Cinco erros consecutivos, rtc outage?\nTentando novamente em 60 segundos...',
        ['extension.not_found'] = 'Falha ao carregar a extens??o :name -> Arquivo n??o encontrado',
        ['extension.error'] = 'Falha ao carregar a extens??o :name -> :error',
        ['testdrive'] = 'Test drive',

        ['nui.title'] = 'RESGATE DE BENEF??CIOS',
        ['notify.title'] = 'BENEF??CIOS',
        ['notify.subtitle.one'] = 'Voc?? pode resgatar 1 item',
        ['notify.subtitle.many'] = 'Voc?? pode resgatar at?? :count itens',
        ['notify.footer'] = 'Digite /store para resgatar',

        ['chat.template'] = '{0} comprou {1}',
        ['vip.template.group'] = 'Seu VIP {0} expira em {1}',
        ['vip.template.house'] = 'Sua resid??ncia {0} expira em {1}',
        ['vip.template.vehicle'] = 'Seu ve??culo {0} expira em {1}',
    }
}

function _(name, args)
    local locale = LANG.getLocale()
    local entry = LANG[locale][name]
    assert(entry, string.format('Entry %s does not exists in %s', name, locale))
    return (entry:gsub(':[A-z_]+', function(param)
        return args[param:sub(2)] or '(nil)'
    end))
end

pcall(RegisterNUICallback, 'get_lang', function(data, cb)
    local locale = LANG.getLocale()
    cb(LANG[locale])
end)