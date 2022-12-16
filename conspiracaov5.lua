---------------------------------------------------------
-- e aí, parsa, veio dar uma olhada?
-- não sou o chico xavier da programação
-- então é claro q o script vai estar cheio de gambiarras
-- tem alguma crítica p/ dar? fale à vontade
-- autoria de preuclides#3383 rs
-- um modelo de "conspiração" no transformice
-- ideia de um joguinho de celular semelhante a esse
-- créditos: {
--    Sklag#2552 pelo script de Degradê,
--    Ninguem#0095 por me deixar roubar o mapa do unotfm,
--    Yuh#0748 pelos desenhos incríveis (ainda não foram adicionados `-
--  }
-- início: 10/08/2022

--declarando as funções globais usadas no script para + otimização
--coroutines
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local coroutine_yield = coroutine.yield

--tables
local table_unpack = table.unpack
local table_insert = table.insert
local table_concat = table.concat

--uis
local ui_addTextArea = ui.addTextArea
local ui_removeTextArea = ui.removeTextArea
local ui_setMapName = ui.setMapName

--execs
local tfm_exec_addImage = tfm.exec.addImage
local tfm_exec_removeImage = tfm.exec.removeImage
local tfm_exec_newGame = tfm.exec.newGame
local tfm_exec_respawnPlayer = tfm.exec.respawnPlayer
local tfm_exec_setPlayerScore = tfm.exec.setPlayerScore

--outros
local math_random = math.random
local os_time = os.time
local system_bindKeyboard = system.bindKeyboard
--ps: é desnecessário adicionar funções globais que só usamos poucas vezes nesta lista
--isso só é útil qnd ela é usada 200 ou + vezes no script
--então as variáveis acima n tem necessidade, coloquei inutilmente mesmo (exceto o addImage e removeImage q uso milhares de vezes)

--aleatorização
do
  math.randomseed(math_random()+math_random((os_time()/64)+math_random()*math_random()))
end

--desativa shaman, inicio de jogo, tempo, morte automática e ponto automático
do local desativar = {'AutoShaman', 'AutoNewGame', 'AutoTimeLeft', 'AfkDeath', 'AutoScore'}
  for i=1, #desativar do
    tfm.exec['disable'..desativar[i]]()
  end
end

--detalhe: as variáveis que começam com _ (exemplo: _variavel = 1) não devem ser mudadas!
--todas as outras que não possuem isso podem ser alteradas para personalizar o jogo

--lista de administradores
local administradores = {['Preuclides#3383'] = true} --se é administrador

--lista de jogadores e sua pontuação
local jogadoresGlobais = {['Preuclides#3383'] = 0} --jogadores e seu número de vitórias

--tabelas do jogo
local jogadoresNaSala = {} --lista de jogadores na sala

local jogadoresNoJogo = {} --{nick, papel} lista de jogadores na cadeira
local papeisNoJogo = {1, 0, 0, 1, 1, 1} --0 é espião, 1 é sociedade //coloque 6 papéis, mais ou menos do que isso causa problemas
local jogadoresTotais = 0 --total de jogadores nas cadeiras

--cores usadas no jogo para as textareas
local coresPadrao = {brancoDeTexto = 'FDFDFE',
    brancoMaisEscuro = 'EDEDEE',
    corDeEspaco = 'BABD2F',
    textAreaFundo = '000001',
    textAreaBorda = '554444',
    espiao = 'FF0C40',
    sociedade = '10FF54',
    lider = '0950FF',
    espiaoEscolhido = 'FF6B00',
    missaoNumero = 'FFBF00',
    missaoEspecialTitulo = 'FFAAFF',
    missaoEspecial = 'ED67EA',
    colocarLider = '0730CC',
    colocarPadrao = 'CC0A00',
    colocarCinza = '20BB10',
    colocarCheio = 'AAAABC',
    colocarVerde = '30CD20',
    colocarBemEscuro = '55557A',
    _colocar = ':)'
  }

local textoColorido = {}
local corColorida = {coresPadrao.espiao, coresPadrao.missaoNumero, coresPadrao.lider}

--tempo total percorrido no modo
local tempoPercorrido = 0

--elementos da missão
local _missaoAtual = 1 --número da missão atual
local numeroDeMissoes = 5 --número total de missões
local liderDaMissao = '' --quem estará escolhendo os agentes
local numeroEscolhido = 0 --número do primeiro líder da missão
local liderGenero = 0 --nenhum, feminino e masculino
local missaoSelecionada = 0 --número do título da missão selecionada
local numeroDeAgentesNaMissao = 0 --quantos agentes terão na missão atual
local missoesSabotadas = 0 --número de missões sabotadas (o jogo acaba quando atingir o limite)
local missoesSucedidas = 0 --numero de missões bem-sucedidas (acima ↑)
local limiteMissoesSabotadas = 3 --se for alterar, coloque um valor menor que o número de missões e maior que 0
local limiteMissoesSucedidas = 3 -- acima ↑
local chanceLimiteRecusar = 6 --60% de chance de a missão ser sabotada em caso de limite de recusas na aprovação
local quemAprovou = {} --aprovei
local quemRecusou = {} --recusei

--agentes da missão atual
local agentesAtuais = {'', '', '', '', '', ''} --agentes escolhidos para a missão atual
local agentesDeVerdade = {{}, {}}
local agentesNormal = {}
local agentesForamAprovados = false --se agentes foram aprovados
local sequenciaPossivelDeAgentes = {{2, 3, 2, 2, 3}, {2, 2, 2, 3, 3}, {2, 3, 2, 3, 2}} --sequência de número de agente nas missões
local sequenciaDaPartida = {} --a sequência de agentes na partida atual

--se a missão foi sabotada
local quemSabotou = {}

--mensagens específicas pra exibir
local mensagemAleatoria = {'Allah te guiará nessa.', 'Adeus, Buda.', 'Seu objetivo está tão perto.', 'Seja compassivo.', 'AAAAAA ele me arranhou.', 'Disseram-me "0 é a cor do azar".', 'Obliviscitur tenebris.', 'Ac tenebras.', 'Invenire astrologus.', 'Memento mori.', 'Et non moriatur.', 'Não esqueça ao que você está aqui.', 'Maloso vobiscum et cum spiritum.', 'Anseio por paz em meu coração.', 'Você entendeu algo?', 'Os olhos da sociedade está em você.', 'Este sujeito está estranhamente de bom humor.', 'Este sorriso é suspeito.', 'Tem algo em mente?', 'Temos olhos nas paredes...', 'É você?', 'Como você sabia?', 'Mi vitae, felis, bibendum.', 'Maior sum quam liber tuus.', 'Não acredite nisso.', 'Será que é uma boa?', 'Felicamos com prazer aqueles que nos subjugariam.', 'Não são apenas palavras bonitas.', 'Sic gorgiamus allos subjuntos freira.'}
local pronomes = {[0] = 'u', [1] = 'a', [2] = 'e'} --mostra elu, ela ou ele nas textareas

--título das missões
local listaDeMissoes = function(numeroExtra) 
  if numeroExtra == nil then
    return 16
  end
  return({
    --1-3
    {'<font size="14">Achatar a Terra', '<font size="9">Que a Terra é plana todo o globo sabe. Os dias estão contados, a sociedade viu o capitão do exército americano comentando sobre a contrução de equipamentos de terraformação para curvar a Terra, localizados no parque de Tallahassee. Sugeriu-se que '..numeroDeAgentesNaMissao..' agentes da sociedade viajassem para os parques da cidade, onde o congressista Manchuriano e os agentes, acompanhados por quatro carros de palhaços chamando a atenção do público, destruiriam a máquina e achataria a Terra novamente.'}, 
    {'<font size="14">Fazer chapéus de alumínio', '<font size="9">Abstendo-se ao manejo mental das micro-ondas, a fábrica de chapéus alumínio construiu chapéus em folhas de duas camadas, quatro camadas se separadas umas das outras. A ponta encolhe e, portanto, torna-se cada vez mais pequena. Guarde para você. Mantenha-o fresco. Imite em um. A repetição é um programa de aula gratuito. Respiração profunda. Você dá os sinais de porta logo após dar as instruções. Defina os controles no modo de alto impacto para que apenas os membros da sociedade protejam-se do controle mental.'}, 
    {'<font size="14">Gravar pouso falso na Lua', '<font size="9">A diretora da sociedade manda uma carta: "Cara sociedade, uma nave espacial apareceu em Hollywood onde o menino está e começou a filmá-lo pulando. Dentro do navio está o capitão do exército japonês com máscara de macaco, pedindo pela entrega do material do pouso lunar falso. Sombras apareceram me chamando para a gravação lunar. Livre como macaco, haha. Quero que vocês lidem com isto. Atenciosamente, Diretora Hello Kitty". O membro '..liderDaMissao..' vai nos liderar nessa.'}, 
    --4-6
    {'<font size="14">Visitar líderes reptilianos', '<font size="9">Uma carta escrita em nome do Rei Calango para um de seus favoritos marítimos contava sobre o desejo de os répteis em aliar-se à nossa sociedade. Os calangos provaram ser uma marca igualmente evocativa de líder, e não um gosto resistente ao ridículo. À medida que o país se apressava de contar séculos de sagas e dinastias, Calango, o imortal, retratou os leitores com o registro de suas aventuras nos pântamos. Devemos visitar o pântano secreto do Rei para firmar a aliança.'}, 
    {'<font size="14">Achar filhos do Conde Drácula', '<font size="9">O gato sugeriu fincar uma estaca no coração do vampiro para que ele se dissipe e sejamos mais fortes. Ah! Bobeira... Nadaremos em ouro com a aliança dos vampiros. Justiça, Romênia, preferência. Desde quando você quer justiça para os cristãos? Peter (memória falsa) sugeriu que um vampiro de aparência humana se tornasse humano (ah hah, perfeito porque essa pessoa provavelmente ficaria melhor). O gato lamentavelmente esfaqueou o vampiro romeniano e rasgou sua linda lingerie.'}, 
    {'<font size="14">Começar um desastre "natural"', '<font size="9">O cientista Peter, assistente na base de aquecimento da ionosfera, olha para Mara Chung, agarra seu namorado Marco em algum lugar na multidão, entra no corredor e bate a porta do centro de pesquisa. Ele concluiu seu pensamento: Este monte de fracotes não percebe o que nós representamos. Histeria em massa. Moeda de piada para as autoridades da cidade da próxima semana. Aqueça a ionosfera na temperatura máxima com a ajuda de '..numeroDeAgentesNaMissao..' agentes para destruir este lugar.'}, 
    --7-9
    {'<font size="14">Inspec. bunker apocalíptico', '<font size="9">Na Groenlândia comemos peixes capturados há apenas alguns meses, os ursos nos trazem comida depois de procurar mísseis nucleares no subsolo, há um enorme bunker, seu verde reluzente na neve, absorvedores de eco varreram a escuridão, usamos luvas brancas aqui, alguns pequenos manequins sendo substituídos, um soldado avança, Pelé voa como um velho urso polar, somos solenes, elogios para o diretor angolano David do bunker. Pede-nos para inspecionar.'}, 
    {'<font size="14">Quebrar mercado de ações', '<font size="9">Propomos a queda de 99% de todas as ações, reduzindo o valor das ações para o valor básico até que a reconstrução possa começar. Em última análise, as ações voltarão como sangue nas veias. A era da oferta e da demanda se aproxima. Somente a natureza fornece mensagens dessa urgência. O dinheiro se torna primitivo, perverso, cru e apaixonado ao longo de décadas. Maluco acima. Digno de rancor abaixo. São '..numeroDeAgentesNaMissao..' agentes que derrubarão as ações e acabarão com o dinheiro desprezível que controla nossas vidas.'}, 
    {'<font size="14">Sabotar alianças internacionais', '<font size="9">A Santíssima Trindade que une os países deve ser derrubada. Manipularemos o governo japonês para atacar ativistas japoneses. Manifestantes não conseguem silenciar os defensores do sistema. A cobra da sociedade envenenará aqueles que se oporem a ela. A ação das forças sombrias de Roma, assustando as feministas, conspira por motivos ecniilistas legítimos contra fatos políticos. Os opressores chineses globais dizem "adeus Buda". Somento a sociedade pode apagar as uniões globais.'}, 
    --10-12
    {'<font size="14">Sabotar organizações rivais', '<font size="9">Uma época em que movimentos desonestos usados em tecnologias gatinas (propriedade dos gatos) levam, espontaneamente, a uma evolução evolutivos de um robô móvel biológico secreto capaz de se infiltrar dentro de cada organismo para controlar, escanear, monitorar, visualizar e registrar as atividades humanas dia e noite. A sociedade usará os dispositivos imponentes para vigilância e mapeamento celular que colocam em risco a humanidade para retalhar as ações dos inimigos.'}, 
    {'<font size="14">Encontrar o homem de Marte', '<font size="9">Marco estava sentado nu no chão enquanto conversava com o homem de Marte, salvador de mundos perigosos colonizados. Marco (memória real) lhe oferecia um gato em troca da salvação da Terra (que é plana). Bigode, máscara e vestido são as roupas naturais do homem de Marte. Balões coloridos voavam pela estrada marciana. Eram eles: os palhaços e o homem manchuriano, que procuravam pela companhia de '..numeroDeAgentesNaMissao..' agentes para visitá-lo. Precisamos de bigodes, máscaras e vestidos para nos juntar a eles.'}, 
    {'<font size="14">Eleger candidato manchuriano', '<font size="9">Mara Chong organizou uma audiência ao candidato manchuriano. A diretora Hello Kitty buscava o consulado chinês. O congressista era o modelo de palco. A cobra produziu o filme de campanha como uma paródia de espionagem. Mara Chong repreendeu a cobra pela ironia. Só falta os agentes distribuirem o show de música & comédia que mostra por que a legislação da Manchúria aprovou o capturador de graves, dedicou as baleias a Deus e transformou os manchurianos em súditos benevolentes 15 minutos depois.'}, 
    --13-15
    {'<font size="14"><font color="#'..coresPadrao.missaoEspecialTitulo..'"><b>Prever o futuro com tarot</b></font>', '<font size="9">\n\n<font size="11">Parece que essa <font color="#'..coresPadrao.missaoEspecial..'"><b>missão</b></font> é <font color="#'..coresPadrao.missaoEspecial..'"><b>especial</b></font>. Madame Lulu joga suas cartas na mesa e simbolos são revelados. Apenas os agentes da missão veem as letras. Este futuro será profíquo?'}, 
    {'<font size="14"><font color="#'..coresPadrao.missaoEspecialTitulo..'"><b>Encontrar-se com a Bruxa Real</b></font>', '<font size="9">\n\n<font size="11"><font color="#'..coresPadrao.missaoEspecial..'"><b>Missão especial</b></font>. Encontre a Bruxa Real. Ela desfrutará de seus poderes absolutos para te metamorfosear em sociedade ou espião, de acordo com seus desejos. Só um agente da missão pode se comunicar com ela.'}, 
    {'<font size="14"><font color="#'..coresPadrao.missaoEspecialTitulo..'"><b>Conversar com a Bruxa Maléfica</b></font>', '<font size="9">\n\n<font size="11">Hello kitty<font color="#'..coresPadrao.missaoEspecial..'"><b> deu uma missão especial</b></font>. A Bruxa Maléfica jogará uma praga na Missão #5, fazendo com que ela seja bem-sucedida ou sabotada de modo automático, sem importar quais são os agentes da missão. Só um agente pode conversar com a Bruxa Maléfica.'},
    --16
    {('<font size="14"><font color="#%s"><b>Contatar espião soviético</b></font>'):format(coresPadrao.missaoEspecialTitulo), ('<font size="9">\n\n<font size="11">Uma <font color="#%s"><b>missão especial</b></font> selvagem apareceu: Reintegração. Não temos contato no Vietnã. Nosso detetive russo desvendará o disfarce inimigo, seu assistente mandará um telégrafo para nossa base. Cremos que %s agentes serão escolhidos para interpretar a mensagem. Onde fica o Vietnã?'):format(coresPadrao.missaoEspecial, numeroDeAgentesNaMissao)}
  })[numeroExtra]
end

--modos e suas propriedades
local listaDeModos = { 

  { --pegar as cadeiras 1
    _tipoDoModo = 'cadeira', --o ID do modo
    _primeiraVez = true, --se é a primeira vez que tá sendo executado
    _modoAtual = true, --se esse é o modo ativo ou não
    _textAreaDeTempo = 7, --número da textArea de tempo
    duracaoDoModo = 0 --duração do modo
    },

  { --parte em que mostra se vc é espião ou sociedade 2
    _tipoDoModo = 'inciar',
    _primeiraVez = true,
    _modoAtual = false,
    _textAreaDeTempo = 8,
    duracaoDoModo = 14
    },

   { --exibição da missão que iniciará 3
    _tipoDoModo = 'exibir', 
    _primeiraVez = true,
    _modoAtual = false,
    _textAreaDeTempo = 8,
    duracaoDoModo = 14 --este número precisa de ser maior que ou igual a 7
    },

  { --seleção de agentes pelo líder 4
    _tipoDoModo = 'selecionar',
    _primeiraVez = true,
    _modoAtual = false,
    _textAreaDeTempo = 8,
    duracaoDoModo = 45
    },

  { --aprovação da missão pela população 5
    _tipoDoModo = 'aprovar',
    _primeiraVez = true,
    _modoAtual = false,
    _textAreaDeTempo = 8,
    duracaoDoModo = 25
    },

  { --se missão foi aprovada 6
    _tipoDoModo = 'checar',
    _primeiraVez = true,
    _modoAtual = false,
    _textAreaDeTempo = 8,
    _segundaVez = false,
    duracaoDoModo = 5
    },

   { --durante a execução da missão 7
    _tipoDoModo = 'agir',
    _primeiraVez = true,
    _modoAtual = false,
    _textAreaDeTempo = 8,
    duracaoDoModo = 10
    },

  { --depois da missão, resultado 8
    _tipoDoModo = 'resultar',
    _primeiraVez = true,
    _modoAtual = false,
    _textAreaDeTempo = 8,
    duracaoDoModo = 5
    },
  { --quado chega na última missão 9
    _tipoDoModo = 'finalizar',
    _primeiraVez = true,
    _modoAtual = false,
    _textAreaDeTempo = 8,
    duracaoDoModo = 500
    }
}

local textAreaVisivel = {} -- organizado em: {jogadorAlvo = {numeroDaTextArea = {}}}

--até aqui você pode editar livremente ↑
---------------------------------------------------------------------------------------------------
--ajustando algumas coisas, adiciona index na tabela
setmetatable(jogadoresNoJogo, {__index = function()
  return {'</b><font size="11">[ espaço ]', 2}
end})

--text areas gerais
local textAreas = function(numeroDaTextArea, jogadorAlvo, textoAuxiliar, numeroExtra, numeroExtra2)
  local numeroExtra = numeroExtra or 1
  local numeroExtra2 = numeroExtra2 or 0
  local textoAuxiliar = textoAuxiliar or ''
  for i=numeroDaTextArea, numeroDaTextArea do
    return ({
      --1-6 - lista de cadeiras
      {1, "<p align='center'><font size='10'><b><font color='#"..textoAuxiliar.."'>"..jogadoresNoJogo[1][1], jogadorAlvo, 000, 100, 100, 20, nil, nil, 0, false},
      {2, "<p align='center'><font size='10'><b><font color='#"..textoAuxiliar.."'>"..jogadoresNoJogo[2][1], jogadorAlvo, 130, 100, 120, 20, nil, nil, 0, false},
      {3, "<p align='center'><font size='10'><b><font color='#"..textoAuxiliar.."'>"..jogadoresNoJogo[3][1], jogadorAlvo, 270, 100, 120, 20, nil, nil, 0, false},
      {4, "<p align='center'><font size='10'><b><font color='#"..textoAuxiliar.."'>"..jogadoresNoJogo[4][1], jogadorAlvo, 410, 100, 120, 20, nil, nil, 0, false},
      {5, "<p align='center'><font size='10'><b><font color='#"..textoAuxiliar.."'>"..jogadoresNoJogo[5][1], jogadorAlvo, 550, 100, 120, 20, nil, nil, 0, false},
      {6, "<p align='center'><font size='10'><b><font color='#"..textoAuxiliar.."'>"..jogadoresNoJogo[6][1], jogadorAlvo, 700, 100, 100, 20, nil, nil, 0, false},
      --7 - do modo 'cadeira', text areas de jogadores que faltam
      {7, '<p align="center"><font size="12" color="#'..coresPadrao.brancoMaisEscuro..'">Faltam <font size="12" color="#'..coresPadrao.missaoNumero..'">'..6-jogadoresTotais..'</font> jogadores</font></p>', nil, 320, 20, 160, 25, tonumber('0x'..coresPadrao.textAreaFundo), tonumber('0x'..coresPadrao.textAreaBorda), 0.85},
      --8 - contagem de tempo na maioria do listaDeModos
      {8, '<p align="center"><font size="14" color="#'..coresPadrao.missaoNumero..'">'..numeroExtra-tempoPercorrido, nil, 375, 20, 40, 20, 0x000001, 0x443333, 0.85},
      --9 do modo 'encerrar', mostra "fim de jogo"
      {9, '<p align="center"><font size="12" color="#C2C2DA">Fim de jogo', nil, 375, 20, 50, 20, nil, nil, 0.5},
      --10 mensagem de erro quando a coroutine quebra
      {10,'\n\n\n\n\n\n\n\n\n\n<p align="center"><font color="#FFFFFF" size="24" face="lucida console"><b> <font color="#FF0000">[ ERRO ]</font> O jogo quebrou!\nRecarregue o script\nou mude de sala para corrigir.</b>\n\n\n\n<font size="16">Chame no Discord: flamma#0050 caso o erro persista.</font></font>', nil, 0, 0, 800, 400, tonumber('0x'..coresPadrao.brancoMaisEscuro), tonumber('0x'..coresPadrao.brancoMaisEscuro), 0, false},
      --11 do modo 'iniciar', mostra se é espião ou sociedade; do modo 'exibir', mostra a missão e quem está escolhendo a missão
      --do modo 'aprovar', mostra se pode ser aprovado
      --do modo 'checar', mostra se agentes foram aprovados
      {11, textoAuxiliar, jogadorAlvo, 200, 142, 400, 200, tonumber('0x'..coresPadrao.textAreaFundo), tonumber('0x'..coresPadrao.textAreaBorda), 0.94, false},
      --12 do modo exibir, mostra a descrição da missão
      {12, textoAuxiliar, jogadorAlvo, 300, 185, 235, 175, nil, nil, 0, false},
      --13 do modo exibir, mostra o líder da missão
      {13, textoAuxiliar, jogadorAlvo, 210, 200, 380, 132, nil, nil, 0, false},
      --14-19 do modo selecionar, adiciona uma pessoa na missão
      {13+numeroExtra, textoAuxiliar, jogadorAlvo, (140*numeroExtra)+28-140, 120, 45, 18, tonumber('0x'..coresPadrao._colocar), nil, 1, false},
      {15}, {16}, {17}, {18}, {19}, --textareas simbólicas
      {20, ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Aprovar</a></font></p>'):format(coresPadrao.brancoDeTexto, textoAuxiliar), jogadorAlvo, 230, 320, 135, 22, numeroExtra, tonumber('0x'..coresPadrao.textAreaBorda), 1, false}, --terminar
      {21, ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Recusar</a></font></p>'):format(coresPadrao.brancoDeTexto, textoAuxiliar), jogadorAlvo, 435, 320, 135, 22, numeroExtra, tonumber('0x'..coresPadrao.textAreaBorda), 1, false},
      {22, textoAuxiliar, jogadorAlvo, 200, 192, 400, 200, nil, nil, 0, false},
      {23, textoAuxiliar, jogadorAlvo, 230, 320, 135, 22, numeroExtra, tonumber('0x'..coresPadrao.textAreaBorda), 1, false}, --terminar
      {24, textoAuxiliar, jogadorAlvo, 435, 320, 135, 22, numeroExtra, tonumber('0x'..coresPadrao.textAreaBorda), 1, false}
  })[i]
  end
end

local removerTextArea = function(numeroDaTextArea, jogadorAlvo, ...) --remove text area
  if ... then --se tem + de 1 textarea pra remover
    local argumentos = {...}
    for i=1, #argumentos do
      ui_removeTextArea(argumentos[i], jogadorAlvo)
      if jogadorAlvo == nil then jogadorAlvo = 'nil' end
      textAreaVisivel[jogadorAlvo][argumentos[i]] = nil
    end
  end
  if jogadorAlvo == nil then jogadorAlvo = 'nil' end
  textAreaVisivel[tostring(jogadorAlvo)][numeroDaTextArea] = nil
  if jogadorAlvo == 'nil' then jogadorAlvo = nil end
  ui_removeTextArea(numeroDaTextArea, jogadorAlvo)
end

local carregarTextArea = function(numeroDaTextArea, jogadorAlvo, textoAuxiliar, numeroExtra) --carrega textarea
  ui_addTextArea(table_unpack(textAreas(numeroDaTextArea, jogadorAlvo, textoAuxiliar, numeroExtra)))
  if jogadorAlvo == nil then jogadorAlvo = 'nil' end
  textAreaVisivel[jogadorAlvo] = {[numeroDaTextArea] = {textoAuxiliar, numeroExtra}}
  return false
end

--funções úteis (essas não fui eu quem fez, créditos aos criadores obviamente rs)
local shuffle = function(tbl) --embaralhador, coloca a tabela em ordem aleatória
  local t = {}
  for i, v in ipairs(tbl) do
    local pos = math_random(1, #t+1)
    table_insert(t, pos, v)
  end
  return t
end

local tablelength = function(T) --contar o número de elementos na tabela
  local count = 0
  for _ in next, T do if T[_] ~= '' and T[_] ~= false then count = count + 1 end end
  return count
end

local gradient = function(targetPlayer, force, imagem, camada, opacity) --por sklag#2552, adiciona as imagens em modo degradê
  local y = 0
  local opacity = opacity or 1.16
  local numeroDeImagens = 0
  local imagem = imagem or '17948da3319.png'
  local camada = camada or '!'
  while opacity > force do
    y = y +1
    opacity = opacity-force
    numeroDeImagens = numeroDeImagens+1
    tfm_exec_addImage(imagem, camada..'1', 0, y, targetPlayer, 800, 1, nil, opacity)
    tfm_exec_addImage(imagem, camada..'1', 0, 400-y, targetPlayer, 800, 1, nil, opacity)
  end
  return numeroDeImagens
end

--+ tabelas e funções do jogo
for i=1, math_random(4, 8) do
  papeisNoJogo = (shuffle(papeisNoJogo)) --embaralha a tabela "papel" pra definir espião ou sociedade
end

local podeSerAdministrador = function(nomeDoJogador) --lista de pessoas que ganharão 'admin' no jogo automaticamente
  return administradores[nomeDoJogador] == nil 
  and nomeDoJogador:sub(-5) == "#0001"
  or nomeDoJogador:sub(-5) == "#0010" 
  or nomeDoJogador:sub(-5) == "#0015" 
  or nomeDoJogador:sub(-5) == "#0020" 
  or nomeDoJogador == ({pcall(nil)})[2]:match('(.+#%d+)')
end

local analisarJogador = function(nomeDoJogador)
  local taNoJogo
  for i=1, 6 do
    if jogadoresNoJogo[i][1] == nomeDoJogador then
      taNoJogo = true
    end
  end
  if jogadoresGlobais[nomeDoJogador] == nil then
    tfm_exec_setPlayerScore(nomeDoJogador, 0)
  else
    tfm_exec_setPlayerScore(nomeDoJogador, jogadoresGlobais[nomeDoJogador])
  end
  system_bindKeyboard(nomeDoJogador, 32, true, true) --espaço
  tfm_exec_respawnPlayer(nomeDoJogador) --ressuscita
  for i=1, 6 do --exibe as textareas sempre q alguém novo entra
    if jogadoresNoJogo[i][1] == '</b><font size="11">[ espaço ]' then
      carregarTextArea(i, nomeDoJogador, coresPadrao.corDeEspaco) --"[ espaço ]" se a cadeira tá vazia
    end
  end
  if textAreaVisivel['nil'] ~= nil then
    for k, v in next, textAreaVisivel['nil'] do
      carregarTextArea(k, nomeDoJogador, table_unpack(v))
    end
  end
  if textAreaVisivel[nomeDoJogador] ~= nil then
    for k, v in next, textAreaVisivel[nomeDoJogador] do
      carregarTextArea(k, nomeDoJogador, table_unpack(v))
    end
  end
  if listaDeModos[1]._modoAtual then --mostra "faltam x jogadores"
    carregarTextArea(7, nomeDoJogador)
  end
end

local removerDegrade = function(imagensParaRemover)
  for i=1, imagensParaRemover do
    tfm_exec_removeImage(i-1)
  end
end

local enfeite = function(tipoDaParticula, posicaoDoJogador)
  for i=1, math_random(12, 15) do
    tfm.exec.displayParticle(tipoDaParticula, math_random((26-140+(140*posicaoDoJogador)), (66-140+(140*posicaoDoJogador))), math_random(43, 93))
  end
end

local coresNome = function(posicaoDoJogador)
end

local menu = function(quemClicou)
  tfm.exec.playMusic('deadmaze/cinematique/rock.mp3', '1', 90, false, true, quemClicou)
end

local normalizarNomes = function(quemVaiVer)
end

--ajustando + coisas
for k in next, tfm.get.room.playerList do
  jogadoresNaSala[#jogadoresNaSala+1] = tfm.get.room.playerList[k].playerName
end


for i=1, #jogadoresNaSala do --executa p'ra todes
  analisarJogador(jogadoresNaSala[i])
end

--tfm.exec.playSound('tfmadv/musique/tfmadv_musique1.mp3')
--coroutine que será chamada pelo eventLoop
local scriptDoGato = coroutine_create(function()
  local degradeParaRemover
  while true do
    if listaDeModos[1]._modoAtual and jogadoresTotais == 6 then --cadeira - pegar as cadeiras
      sequenciaDaPartida = sequenciaPossivelDeAgentes[math_random(#sequenciaPossivelDeAgentes)]
      listaDeModos[1]._modoAtual = false --começa o modo iniciar quando as cadeiras são preenchidas
      listaDeModos[2]._modoAtual = true
      tempoPercorrido = 0
      removerTextArea(listaDeModos[1]._textAreaDeTempo, nil)
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[2]._modoAtual then --iniciar - mostra sociedade ou espião
      carregarTextArea(listaDeModos[2]._textAreaDeTempo, nil, nil, listaDeModos[2].duracaoDoModo) --contagem do tempo
      if listaDeModos[2]._primeiraVez then
        numeroEscolhido = math_random(#jogadoresNoJogo) --escolhe o líder aleatóraimente
        degradeParaRemover = gradient(nil, 0.008)
        for i=1, 1 do
          carregarTextArea(11, jogadoresNoJogo[i][1], '<font color="#'..coresPadrao.lider..'" size="20"><b>&#12288;Você é expectador</b></font>\n\n\n<font size="12" color="#'..coresPadrao.brancoDeTexto..'">&#12288;&#12288;&#12288;➜ <font color="#'..coresPadrao.espiao..'">Infiltre</font> e <font color="#'..coresPadrao.espiao..'">sabote</font> 3 missões da <font color="#'..coresPadrao.sociedade..'">sociedade</font> para vencer;\n\n&#12288;&#12288;&#12288;➜ Seja discreto: não deixe que a <font color="#'..coresPadrao.sociedade..'">sociedade</font> descubra\n&#12288;&#12288;&#12288;&#12288;sua verdadeira <font color="#'..coresPadrao.espiao..'">identidade</font>;\n\n&#12288;&#12288;&#12288;➜ Tente fazer com que o <font color="#'..coresPadrao.lider..'">Líder</font> da missão escolha você.\n&#12288;&#12288;&#12288;&#12288;Um <font color="#'..coresPadrao.espiao..'">espião</font> pode sabotar a missão inteira.</font>')
        end
        for i=1, #jogadoresNoJogo do --muda a cor dos espiões para vermelho
          if jogadoresNoJogo[i][2] == 0 then
            for j=1, #jogadoresNoJogo do
              if jogadoresNoJogo[j][2] == 0 then
                carregarTextArea(i, jogadoresNoJogo[j][1], coresPadrao.espiao)
              end
            end --abaixo: mostra a mensagem do espião
            carregarTextArea(11, jogadoresNoJogo[i][1], '<font color="#'..coresPadrao.espiao..'" size="20"><b>&#12288;Você é um espião</b></font>\n\n\n<font size="12" color="#'..coresPadrao.brancoDeTexto..'">&#12288;&#12288;&#12288;➜ <font color="#'..coresPadrao.espiao..'">Infiltre</font> e <font color="#'..coresPadrao.espiao..'">sabote</font> 3 missões da <font color="#'..coresPadrao.sociedade..'">sociedade</font> para vencer;\n\n&#12288;&#12288;&#12288;➜ Seja discreto: não deixe que a <font color="#'..coresPadrao.sociedade..'">sociedade</font> descubra\n&#12288;&#12288;&#12288;&#12288;sua verdadeira <font color="#'..coresPadrao.espiao..'">identidade</font>;\n\n&#12288;&#12288;&#12288;➜ Tente fazer com que o <font color="#'..coresPadrao.lider..'">Líder</font> da missão escolha você.\n&#12288;&#12288;&#12288;&#12288;Um <font color="#'..coresPadrao.espiao..'">espião</font> pode sabotar a missão inteira.</font>')
          else --mostra a mensagem da sociedade
            carregarTextArea(11, jogadoresNoJogo[i][1], '<font color="#'..coresPadrao.sociedade..'" size="20"><b>&#12288;Você é sociedade</b></font>\n\n\n<font size="12" color="#'..coresPadrao.brancoDeTexto..'">&#12288;&#12288;&#12288;➜ Complete <font color="#'..coresPadrao.sociedade..'">3 missões</font> com <font color="#'..coresPadrao.sociedade..'">sucesso</font> para vencer;\n\n&#12288;&#12288;&#12288;➜ Fique atento: há <font color="#'..coresPadrao.espiao..'">2 espiões</font> infiltrados na <font color="#'..coresPadrao.sociedade..'">sociedade</font>\n&#12288;&#12288;&#12288;&#12288;que podem sabotar as missões;\n\n&#12288;&#12288;&#12288;➜ Ao ser o <font color="#'..coresPadrao.lider..'">Líder</font> da missão, escolha com sabedoria\n&#12288;&#12288;&#12288;&#12288;seus agentes. Um <font color="#'..coresPadrao.espiao..'">espião</font> pode sabotar a missão inteira.</font>')
          end
        end
        liderDaMissao = jogadoresNoJogo[numeroEscolhido][1] --coloca o líder da missão aleatoriamente
        listaDeModos[2]._primeiraVez = false
      end
      if tempoPercorrido == listaDeModos[2].duracaoDoModo then --vê se o modo iniciar já acabou
        removerTextArea(11, nil) --tira a textarea de exibição padrão
        tempoPercorrido = 0 --padrão de mudar o modo
        listaDeModos[2]._modoAtual = false
        listaDeModos[3]._modoAtual = true
        coroutine_yield() --para por 1 seg
      end
      if tempoPercorrido >= listaDeModos[2].duracaoDoModo+3 then --derruba o jogo se houver algum problema
        break
      end
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[3]._modoAtual then --exibir - missao atual
      carregarTextArea(listaDeModos[3]._textAreaDeTempo, nil, nil, listaDeModos[3].duracaoDoModo) --tempo
      if listaDeModos[3]._primeiraVez then --se é a primeira vez do modo exibir
        if _missaoAtual == 1 or _missaoAtual == 5 then
          missaoSelecionada = math_random(listaDeMissoes()-4) --se for a 1° ou 5° missão, não coloca nenhuma missão especial
        else
          missaoSelecionada = math_random(listaDeMissoes())
        end
        numeroDeAgentesNaMissao = sequenciaDaPartida[_missaoAtual]
        listaDeModos[3]._primeiraVez = false
        carregarTextArea(11, nil, '<font size="12" color="#'..coresPadrao.missaoNumero..'"><b>&#12288;&#12288;Missão #'..tostring(_missaoAtual)..'</b></font>\n<font size="22" color="#'..coresPadrao.brancoDeTexto..'"><b>&#12288;&#12288;&#12288; <font size="12" color="#'..coresPadrao.missaoNumero..'"><b>└ </b></font>'..listaDeMissoes(missaoSelecionada)[1]..'</b></font>')
        carregarTextArea(12, nil, '<p align="justify"><font size="11" color="#'..coresPadrao.brancoMaisEscuro..'">'..listaDeMissoes(missaoSelecionada)[2]..'</font></p>')
      elseif tempoPercorrido == tonumber((tostring(listaDeModos[3].duracaoDoModo*0.85)):match('(%d+)'))-1 then
        removerTextArea(12, nil)
      elseif tempoPercorrido == tonumber((tostring(listaDeModos[3].duracaoDoModo*0.85)):match('(%d+)')) then
        liderGenero = tfm.get.room.playerList[liderDaMissao] and tfm.get.room.playerList[liderDaMissao].gender or 0
        carregarTextArea(13, nil, '\n<font size="12" color="#'..coresPadrao.lider..'"><b>'..liderDaMissao..'</b></font><font size="12" color="#'..coresPadrao.brancoDeTexto..'"> foi escolhid'..pronomes[liderGenero]..' como líder da missão.\n<font size="12">El'..pronomes[liderGenero]..' terá que selecionar '..numeroDeAgentesNaMissao.. ' agentes para completá-la.\n\n\n\n\n\n\n\n<p align="right"><font size="9">'..mensagemAleatoria[math_random(#mensagemAleatoria)]..'</font></p></font>')
      elseif tempoPercorrido == listaDeModos[3].duracaoDoModo then
        removerTextArea(11, nil, 12, 13)
        tempoPercorrido = 0
        listaDeModos[3]._modoAtual = false
        listaDeModos[4]._modoAtual = true
      elseif tempoPercorrido >= listaDeModos[3].duracaoDoModo+3 then
        break
      end
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[4]._modoAtual then --selecionar - seleciona os agentes da missão
      carregarTextArea(listaDeModos[4]._textAreaDeTempo, nil, nil, listaDeModos[4].duracaoDoModo)
      if listaDeModos[4]._primeiraVez then
        listaDeModos[4]._primeiraVez = false
        for i=1, #jogadoresNoJogo do
          if jogadoresNoJogo[i][1] == liderDaMissao then
            for k=1, #jogadoresNoJogo do
              coresPadrao._colocar = coresPadrao.colocarLider
              agentesAtuais[i] = liderDaMissao
              if jogadoresNoJogo[numeroEscolhido][2] == 0 and jogadoresNoJogo[k][2] == 0 then
                local escolheCor = 3
                for j=1, (jogadoresNoJogo[numeroEscolhido][1]):len() do
                  textoColorido[#textoColorido+1] = corColorida[escolheCor].."'>"..(jogadoresNoJogo[numeroEscolhido][1]):sub(j, j).."<font color='#"
                  if escolheCor == 3 then
                    escolheCor = 1
                  else
                    escolheCor = 3
                  end
                  if j == (jogadoresNoJogo[numeroEscolhido][1]):len() then
                    textoColorido[#textoColorido+1] = "'>\n\n\n\n\n\n"
                  end
                end
                carregarTextArea(i, jogadoresNoJogo[k][1], table_concat(textoColorido))
                textoColorido = {}
              else
                carregarTextArea(i, jogadoresNoJogo[k][1], coresPadrao.lider)
              end
            end
            carregarTextArea(14, nil, ('<p align="center"><b><font color="#%s" size="10">Líder</font></b></p>'):format(coresPadrao.brancoDeTexto), i)
          else
            coresPadrao._colocar = coresPadrao.colocarPadrao
            carregarTextArea(14, jogadoresNoJogo[numeroEscolhido][1], ('<p align="center"><b><font color="#%s" size="9"><a href="event:selecionar">Incluir</a></font></b></p>'):format(coresPadrao.brancoDeTexto), i)
          end
        end
      end
      if tempoPercorrido == listaDeModos[4].duracaoDoModo then
        for i=1, #jogadoresNoJogo do
          if i == numeroEscolhido then
          else
            removerTextArea(13+i, nil)
          end
        end
      end
      if tempoPercorrido == listaDeModos[4].duracaoDoModo then
        listaDeModos[4]._modoAtual = false
        listaDeModos[5]._modoAtual = true
        tempoPercorrido = 0
      end
      if tempoPercorrido >= listaDeModos[4].duracaoDoModo+3 then
        break
      end
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[5]._modoAtual then
      carregarTextArea(listaDeModos[5]._textAreaDeTempo, nil, nil, listaDeModos[5].duracaoDoModo)
      if listaDeModos[5]._primeiraVez then
        listaDeModos[5]._primeiraVez = false
        if tablelength(agentesAtuais) <= numeroDeAgentesNaMissao then
          local numero1, numero2, numero3 = math_random(6), math_random(6), math_random(6)
          local agentesQueFaltam = numeroDeAgentesNaMissao+1
          local liderPosicao
          local numero = 1
          for i=1, #agentesAtuais do
            if agentesAtuais[i] ~= '' then
              agentesQueFaltam = agentesQueFaltam-1
            end
            if agentesAtuais[i] == liderDaMissao then
              liderPosicao = i
            end
            if agentesAtuais[i] ~= liderDaMissao and agentesAtuais[i] ~= '' then
              if numero == 1 then
                numero1 = i
                numero = numero+1
              end
              if numero == 2 then
                numero2 = i
                numero = numero+1
              end
              if numero == 3 then
                numero = i
                numero = numero+1
              end
            end 
          end
          do
            --com certeza esse não é o melhor jeito de fazer o que eu vou fazer
            --mas eu tava com pressa...
            --e preguiça
            while numero1 == liderPosicao do
              numero1 = math_random(#jogadoresNoJogo)
            end
            --definimos o numero1, agora o numero2 tem q ser diferente do 1
            while numero2 == numero1 or numero2 == liderPosicao do
              numero2 = math_random(#jogadoresNoJogo)
            end
            --e vamos para o número 3
            while numero3 == numero1 or numero3 == numero2 or numero3 == liderPosicao do
              numero3 = math_random(#jogadoresNoJogo)
            end
            --fim!!!
            --na verdade, falta ver se o numero escolhido é igual ao de um agente :\
            --depois eu resolvo isso
            --atualização 06/09/2022: resolvido rs
          end
          local backUpCB = listaDeModos[4]._modoAtual
          listaDeModos[4]._modoAtual = true
          if agentesQueFaltam == 1 then
            eventTextAreaCallback(13+numero3, liderDaMissao, 'selecionar')
          end
          if agentesQueFaltam == 2 then
            eventTextAreaCallback(13+numero3, liderDaMissao, 'selecionar')
            eventTextAreaCallback(13+numero2, liderDaMissao, 'selecionar')
          end
          if agentesQueFaltam == 3 then
            eventTextAreaCallback(13+numero1, liderDaMissao, 'selecionar')
            eventTextAreaCallback(13+numero2, liderDaMissao, 'selecionar')
            eventTextAreaCallback(13+numero3, liderDaMissao, 'selecionar')
          end
          listaDeModos[4]._modoAtual = backUpCB
        end
        for i=1, #jogadoresNoJogo do
          if i == numeroEscolhido then
          else
            removerTextArea(13+i, nil)
          end
        end
        for i=1, #agentesAtuais do
          if agentesAtuais[i] == liderDaMissao or agentesAtuais[i] == '' then
          elseif jogadoresNoJogo[i][2] == 0 then
            agentesDeVerdade[1][#agentesDeVerdade[1]+1] = '<font color="#'..coresPadrao.espiao..'">'..agentesAtuais[i]..'</font>'
          else
            agentesDeVerdade[2][#agentesDeVerdade[2]+1] = agentesAtuais[i]
          end
        end
        for i=1, #agentesAtuais do
          if agentesAtuais[i] == liderDaMissao or agentesAtuais[i] == '' then
          else
            agentesNormal[#agentesNormal+1] = agentesAtuais[i]
          end
        end
        carregarTextArea(11, nil, ('<font size="12" color="#%s"><b>&#12288;&#12288;Missão #%s</b></font>\n<font size="22" color="#%s"><b>&#12288;&#12288;&#12288; <font size="12" color="#%s"><b>└ </b></font>Aprovação dos agentes</b></font>'):format(coresPadrao.missaoNumero, _missaoAtual, coresPadrao.brancoDeTexto, coresPadrao.lider))
        for i=1, #jogadoresNoJogo do
          if jogadoresNoJogo[i][2] == 0 then
            if next(agentesDeVerdade[1]) == nil then
              carregarTextArea(22, jogadoresNoJogo[i][1], ('<font size="12" color="#%s">\n\n&#12288;Decida se você aprovaria os agentes:\n\n&#12288;&#12288;&#12288;➜ %s'):format(coresPadrao.brancoDeTexto, table_concat(agentesDeVerdade[2], '\n&#12288;&#12288;&#12288;➜ ')))
            elseif (next(agentesDeVerdade[1]) == nil) == false and (next(agentesDeVerdade[2]) == nil) == false then
              carregarTextArea(22, jogadoresNoJogo[i][1], ('<font size="12" color="#%s">\n\n&#12288;Decida se você aprovaria os agentes:\n\n&#12288;&#12288;&#12288;➜ %s'):format(coresPadrao.brancoDeTexto, table_concat(agentesDeVerdade[1], '\n&#12288;&#12288;&#12288;➜ ')..'\n&#12288;&#12288;&#12288;➜ '..table_concat(agentesDeVerdade[2], '\n&#12288;&#12288;&#12288;➜ ')))
            else
              carregarTextArea(22, jogadoresNoJogo[i][1], ('<font size="12" color="#%s">\n\n&#12288;Decida se você aprovaria os agentes:\n\n&#12288;&#12288;&#12288;➜ %s'):format(coresPadrao.brancoDeTexto, table_concat(agentesDeVerdade[1], '\n&#12288;&#12288;&#12288;➜ ')))
            end
          else
            carregarTextArea(22, jogadoresNoJogo[i][1], ('<font size="12" color="#%s">\n\n&#12288;Decida se você aprovaria os agentes:\n\n&#12288;&#12288;&#12288;➜ %s'):format(coresPadrao.brancoDeTexto, table_concat(agentesNormal, '\n&#12288;&#12288;&#12288;➜ ')))
          end
          carregarTextArea(20, jogadoresNoJogo[i][1], 'aprovar', tonumber('0x'..coresPadrao.colocarVerde))
          carregarTextArea(21, jogadoresNoJogo[i][1], 'recusar', tonumber('0x'..coresPadrao.colocarPadrao))
        end
      end
      for i=1, #jogadoresNoJogo do
        if quemAprovou[i] then
          enfeite(9, i)
        end
        if quemRecusou[i] then
          enfeite(13, i)
        end
      end
      if tempoPercorrido >= listaDeModos[5].duracaoDoModo then
        listaDeModos[5]._modoAtual = false
        listaDeModos[6]._modoAtual = true
        tempoPercorrido = 0
      end
      if tempoPercorrido >= listaDeModos[5].duracaoDoModo+3 then
        break
      end
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[6]._modoAtual then --modo para checar se agentes foram aprovados
      carregarTextArea(listaDeModos[6]._textAreaDeTempo, nil, nil, listaDeModos[6].duracaoDoModo)
      if listaDeModos[6]._segundaVez then
        for i=1, #jogadoresNoJogo do
          if quemAprovou[i] then
            enfeite(9, i)
          end
          if quemRecusou[i] then
            enfeite(13, i)
          end
        end
        listaDeModos[6]._segundaVez = false
      end
      if listaDeModos[6]._primeiraVez then
        listaDeModos[6]._primeiraVez = false
        removerTextArea(22, nil, 20, 21, 11)
        if tablelength(quemAprovou) > tablelength(quemRecusou) then
          carregarTextArea(11, nil, ('\n<p align="center"><font size="15" color="#%s"><b>A sociedade os aprovou.\n<font size="13">A missão irá começar.</b></font></p>'):format(coresPadrao.sociedade))
          --aqui é pra mostrar 'agentes foram aprovados'
        else
          carregarTextArea(11, nil, ('\n<p align="center"><font size="15" color="#%s"><b>A sociedade rejeita os agentes.</b></font></p>'):format(coresPadrao.espiao))
          --'agentes foram recusados'
        end
        local quebraDeLinha = '\n\n'
        if numeroDeAgentesNaMissao == 3 then
          quebraDeLinha = '\n'
        end
        local agentesFinais = {}
        for i=1, #agentesDeVerdade[1] do
          agentesFinais[#agentesFinais+1] = '✷ '
          agentesFinais[#agentesFinais+1] = agentesDeVerdade[1][i]
          agentesFinais[#agentesFinais+1] = ' ✷'
        end
        for i=1, #agentesDeVerdade[2] do
          agentesFinais[#agentesFinais+1] = '✷ '
          agentesFinais[#agentesFinais+1] = agentesDeVerdade[2][i]
          agentesFinais[#agentesFinais+1] = ' ✷'
        end
        for i=1, #jogadoresNoJogo do
          if jogadoresNoJogo[i][2] == 0 then
            carregarTextArea(22, jogadoresNoJogo[i][1], ('<p align="center"><font size="12" color="#%s">\n\n✷ %s ✷'):format(coresPadrao.brancoDeTexto, table_concat(agentesFinais)))
          end
        end
        listaDeModos[6]._segundaVez = true
      end
      if tablelength(quemAprovou) > tablelength(quemRecusou) and tempoPercorrido >= listaDeModos[6].duracaoDoModo then
        listaDeModos[6]._modoAtual = false
        listaDeModos[7]._modoAtual = true
        tempoPercorrido = 0
        for i=1, #jogadoresNoJogo do
          if i == numeroEscolhido then
          else
            removerTextArea(13+i, nil)
          end
        end
        removerTextArea(22, nil, 11)
      elseif tempoPercorrido >= listaDeModos[6].duracaoDoModo then
        numeroEscolhido = numeroEscolhido+1
        if numeroEscolhido > 6 then
          numeroEscolhido = 1
        end
        liderDaMissao = jogadoresNoJogo[numeroEscolhido][1]
        for i=1, #listaDeModos do
          listaDeModos[i]._primeiraVez = true
        end
        for i=1, #jogadoresNoJogo do --muda a cor dos espiões para vermelho
          if jogadoresNoJogo[i][2] == 0 then
            for j=1, #jogadoresNoJogo do
              if jogadoresNoJogo[j][2] == 0 then
                carregarTextArea(i, jogadoresNoJogo[j][1], coresPadrao.espiao)
              else
                for k=1, #jogadoresNoJogo do
                  if jogadoresNoJogo[k][2] == 1 then
                    carregarTextArea(i, jogadoresNoJogo[k][1], coresPadrao.brancoDeTexto)
                  end
                end
              end
            end
          else
            carregarTextArea(i, nil, coresPadrao.brancoDeTexto)
          end
        end
        agentesAtuais = {'', '', '', '', '', ''} --agentes escolhidos para a missão atual
        agentesDeVerdade = {{}, {}}
        agentesNormal = {}
        quemAprovou = {} --aprovei
        quemRecusou = {} --recusei
        agentesForamAprovados = false
        listaDeModos[3]._modoAtual = true
        listaDeModos[6]._modoAtual = false
        tempoPercorrido = 0
        removerTextArea(22, nil, 11, 14, 15, 16, 17, 18, 19)
      end
      if tempoPercorrido >= listaDeModos[6].duracaoDoModo+3 then
        break
      end
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[7]._modoAtual then
      carregarTextArea(listaDeModos[5]._textAreaDeTempo, nil, nil, listaDeModos[5].duracaoDoModo)
      if listaDeModos[7]._primeiraVez then
        listaDeModos[7]._primeiraVez = false
        for i=1, #agentesAtuais do
          if agentesAtuais[i] ~= '' and i ~= numeroEscolhido then
            carregarTextArea(11, agentesAtuais[i], ('<font size="12" color="#%s"><b>&#12288;&#12288;Missão #%s</b></font>\n<font size="16" color="#%s"><b>&#12288;&#12288;&#12288; <font size="12" color="#%s"><b>└ </b></font>Execução da missão.</b></font>\n\n\n\n\n<p align="center"><font size="11" color="#%s">Escolha o resultado da missão.</font>'):format(coresPadrao.missaoNumero, _missaoAtual, coresPadrao.brancoDeTexto, coresPadrao.lider, coresPadrao.brancoDeTexto))
          end
        end
        for i=1, #agentesAtuais do
          if agentesAtuais[i] ~= '' and i ~= numeroEscolhido then
            if jogadoresNoJogo[i][2] == 0 then
              carregarTextArea(23, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sucesso</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sucesso'), tonumber('0x'..coresPadrao.colocarVerde))
              carregarTextArea(24, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sabotagem</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sabotagem'), tonumber('0x'..coresPadrao.colocarPadrao))
            else
              carregarTextArea(23, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sucesso</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sucesso'), tonumber('0x'..coresPadrao.colocarVerde))
              carregarTextArea(24, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11">Sabotagem</a></font></p>'):format(coresPadrao.brancoMaisEscuro), tonumber('0x'..coresPadrao.colocarBemEscuro))
            end
          end
        end
      end
      if tempoPercorrido == listaDeModos[7].duracaoDoModo then
        removerTextArea(23, nil, 24, 11)
        listaDeModos[7]._modoAtual = false
        listaDeModos[8]._modoAtual = true
        tempoPercorrido = 0
      end
      if tempoPercorrido >= listaDeModos[7].duracaoDoModo+3 then
        break
      end
    ------------------------------------------------------------------------------------------
    end

    if listaDeModos[8]._modoAtual then
      if listaDeModos[8]._primeiraVez then
        listaDeModos[8]._primeiraVez = false
        if (next(quemSabotou) == nil) == false then
          carregarTextArea(11, nil, ('<font size="12" color="#%s"><b>&#12288;&#12288;Missão #%s</b></font>\n<font size="16"><b>&#12288;&#12288;&#12288; </b></font><font size="12" color="#%s"><b>└ </b></font><font size="16" color="#%s">A missão foi <font color="#%s">sabotada</font></b></font>\n\n<p align="center"><font size="11" color="#%s">Um ou mais membros da missão é um espião.</font>'):format(coresPadrao.espiao, _missaoAtual, coresPadrao.missaoNumero, coresPadrao.brancoDeTexto, coresPadrao.espiao, coresPadrao.brancoDeTexto, coresPadrao.espiao, coresPadrao.brancoDeTexto))
        else
          carregarTextArea(11, nil, ('<font size="12" color="#%s"><b>&#12288;&#12288;Missão #%s</b></font>\n<font size="16"><b>&#12288;&#12288;&#12288; </b></font><font size="12" color="#%s"><b>└ </b></font><font size="15" color="#%s"><b>Resultado da missão: <font color="#%s">bem-sucedida</p></font></b></font>\n\n\n<p align="center"><font size="11" color="#%s">Mesmo assim, pode haver espiões na missão...</font>'):format(coresPadrao.sociedade, _missaoAtual, coresPadrao.missaoNumero, coresPadrao.brancoDeTexto, coresPadrao.sociedade, coresPadrao.brancoDeTexto, coresPadrao.sociedade, coresPadrao.brancoDeTexto))
        end
        local quebraDeLinha = '\n\n'
        if numeroDeAgentesNaMissao == 3 then
          quebraDeLinha = '\n'
        end
        for i=1, #jogadoresNoJogo do
          if jogadoresNoJogo[i][2] == 0 then
            if next(agentesDeVerdade[1]) == nil then
              carregarTextArea(22, jogadoresNoJogo[i][1], ('<p align="center"><font size="12" color="#%s">\n\n\n\n✷ %s ✷'):format(coresPadrao.brancoDeTexto, table_concat(agentesDeVerdade[2], ' ✷'..quebraDeLinha..'✷ ')))
            elseif (next(agentesDeVerdade[1]) == nil) == false and (next(agentesDeVerdade[2]) == nil) == false then
              carregarTextArea(22, jogadoresNoJogo[i][1], ('<p align="center"><font size="12" color="#%s">\n\n\n\n✷ %s ✷'):format(coresPadrao.brancoDeTexto, table_concat(agentesDeVerdade[1], ' ✷'..quebraDeLinha..'✷ ')..' ✷\n✷ '..table_concat(agentesDeVerdade[2], ' ✷'..quebraDeLinha..'✷ ')))
            else
              carregarTextArea(22, jogadoresNoJogo[i][1], ('<p align="center"><font size="12" color="#%s">\n\n\n\n✷ %s ✷'):format(coresPadrao.brancoDeTexto, table_concat(agentesDeVerdade[1], ' ✷'..quebraDeLinha..'✷ ')))
            end
          else
            carregarTextArea(22, jogadoresNoJogo[i][1], ('<p align="center"><font size="12" color="#%s">\n\n\n\n✷ %s ✷'):format(coresPadrao.brancoDeTexto, table_concat(agentesNormal, ' ✷'..quebraDeLinha..'✷ ')))
          end
        end
      end
      if tempoPercorrido == listaDeModos[8].duracaoDoModo then
        if _missaoAtual == 5 then
          listaDeModos[9]._modoAtual = true
          listaDeModos[8]._modoAtual = false
        else
          numeroEscolhido = numeroEscolhido+1
          if numeroEscolhido > 6 then
            numeroEscolhido = 1
          end
          liderDaMissao = jogadoresNoJogo[numeroEscolhido][1]
          for i=1, #listaDeModos do
            listaDeModos[i]._primeiraVez = true
          end
          for i=1, #jogadoresNoJogo do --muda a cor dos espiões para vermelho
            if jogadoresNoJogo[i][2] == 0 then
              for j=1, #jogadoresNoJogo do
                if jogadoresNoJogo[j][2] == 0 then
                  carregarTextArea(i, jogadoresNoJogo[j][1], coresPadrao.espiao)
                else
                  for k=1, #jogadoresNoJogo do
                    if jogadoresNoJogo[k][2] == 1 then
                      carregarTextArea(i, jogadoresNoJogo[k][1], coresPadrao.brancoDeTexto)
                    end
                  end
                end
              end
            else
              carregarTextArea(i, nil, coresPadrao.brancoDeTexto)
            end
          end
          agentesAtuais = {'', '', '', '', '', ''} --agentes escolhidos para a missão atual
          agentesDeVerdade = {{}, {}}
          agentesNormal = {}
          quemAprovou = {} --aprovei
          quemRecusou = {} --recusei
          agentesForamAprovados = false
          listaDeModos[3]._modoAtual = true
          listaDeModos[8]._modoAtual = false
          removerTextArea(22, nil, 11, 14, 15, 16, 17, 18, 19)
          _missaoAtual = _missaoAtual+1
          tempoPercorrido = 0
        end
        coroutine_yield()
      end
      if tempoPercorrido >= listaDeModos[8].duracaoDoModo+3 then
        break
      end
    ------------------------------------------------------------------------------------------
    end
    if listaDeModos[9]._modoAtual then
      if listaDeModos[9]._primeiraVez then
        listaDeModos[9]._primeiraVez = false
        menu()
      end
    ------------------------------------------------------------------------------------------
    end
    coroutine_yield()
  end
end)

---------------------------------------------------------
--funções chamadas pelo transformice
do 
  local aCada1Segundo
  eventLoop = function() --"aii mimimi coroutine desnecessaria" AAAAAAAAA RASENGAN
    if aCada1Segundo then 
      aCada1Segundo = false
      return
    end
    if coroutine_resume(scriptDoGato) == false then
      gradient(nil, 0.008, '17948d9ecc2.png', ':', 0.98)
      for i=1, 14 do
        removerTextArea(10+i)
      end
      carregarTextArea(10, nil)
      coroutine_resume = function() return true end
    end
    tempoPercorrido = tempoPercorrido+1
    aCada1Segundo = true
  end
end

eventNewPlayer = function(jogadorQueEntrou)
  analisarJogador(jogadorQueEntrou) --novo player = dá oq é necessário p ele
end

eventPlayerLeft = function(jogadorQueSaiu)
  if listaDeModos[1]._modoAtual then
    for i=1, 6 do
      if jogadoresNoJogo[i][1] == jogadorQueSaiu then
        jogadoresNoJogo[i] = nil
        carregarTextArea(i, nil, coresPadrao.corDeEspaco)
        jogadoresTotais = jogadoresTotais-1
        carregarTextArea(7)
      end
    end
  end
end

eventTextAreaCallback = function(numeroDaTextArea, quemClicou, nomeDoEvento)
  --tfm.exec.playSound ( sound, volume, soundPosX, soundPosY, targetPlayer )
  tfm.exec.playSound('tfmadv/bouton1.mp3', nil, nil, nil, quemClicou)
  if numeroDaTextArea > 13 and quemClicou == jogadoresNoJogo[numeroEscolhido][1] and nomeDoEvento == 'selecionar' and listaDeModos[4]._modoAtual then
    coresPadrao._colocar = coresPadrao.colocarCinza
    carregarTextArea(14, jogadoresNoJogo[numeroEscolhido][1], ('<p align="center"><b><font color="#%s" size="9"><a href="event:remover">Retirar</a></font></b></p>'):format(coresPadrao.brancoDeTexto), numeroDaTextArea-13)
    for i=1, #jogadoresNoJogo do
      if jogadoresNoJogo[i][2] == 0 and jogadoresNoJogo[numeroDaTextArea-13][2] == 0 then
        local escolheCor = 1
        for i=1, (jogadoresNoJogo[numeroDaTextArea-13][1]):len() do
          textoColorido[#textoColorido+1] = corColorida[escolheCor].."'>"..(jogadoresNoJogo[numeroDaTextArea-13][1]):sub(i, i).."<font color='#"
          if escolheCor == 2 then
            escolheCor = 1
          else
            escolheCor = 2
          end
          if i == (jogadoresNoJogo[numeroDaTextArea-13][1]):len() then
            textoColorido[#textoColorido+1] = "'>\n\n\n\n\n\n"
          end
        end
        carregarTextArea(numeroDaTextArea-13, jogadoresNoJogo[i][1], table_concat(textoColorido))
        textoColorido = {}
      else
        carregarTextArea(numeroDaTextArea-13, jogadoresNoJogo[i][1], coresPadrao.missaoNumero)
      end
    end
    agentesAtuais[numeroDaTextArea-13] = jogadoresNoJogo[numeroDaTextArea-13][1]
    if tablelength(agentesAtuais) > numeroDeAgentesNaMissao then
      for k, v in next, agentesAtuais do
        if v == ''  then
          coresPadrao._colocar = coresPadrao.colocarCheio
          carregarTextArea(14, jogadoresNoJogo[numeroEscolhido][1], ('<p align="center"><b><font color="#%s" size="9">\\\\\\</font></b></p>'):format(coresPadrao.lider), tonumber(k))
        end
      end
    end
  end
  if numeroDaTextArea > 13 and quemClicou == jogadoresNoJogo[numeroEscolhido][1] and nomeDoEvento == 'remover' and listaDeModos[4]._modoAtual then
    coresPadrao._colocar = coresPadrao.colocarPadrao
    carregarTextArea(14, jogadoresNoJogo[numeroEscolhido][1], ('<p align="center"><b><font color="#%s" size="9"><a href="event:selecionar">Incluir</a></font></b></p>'):format(coresPadrao.brancoDeTexto), numeroDaTextArea-13)
    for i=1, #jogadoresNoJogo do
      if jogadoresNoJogo[i][2] == 0 and jogadoresNoJogo[numeroDaTextArea-13][2] == 0 then
        carregarTextArea(numeroDaTextArea-13, jogadoresNoJogo[i][1], coresPadrao.espiao)
      else
        carregarTextArea(numeroDaTextArea-13, jogadoresNoJogo[i][1], coresPadrao.brancoDeTexto)
      end
    end
    agentesAtuais[numeroDaTextArea-13] = ''
    for k, v in next, agentesAtuais do
      if v == '' then
        coresPadrao._colocar = coresPadrao.colocarPadrao
        carregarTextArea(14, jogadoresNoJogo[numeroEscolhido][1], ('<p align="center"><b><font color="#%s" size="9"><a href="event:selecionar">Incluir</a></font></b></p>'):format(coresPadrao.brancoDeTexto), tonumber(k))
      end
    end
  end
  if listaDeModos[5]._modoAtual then
    if numeroDaTextArea > 19 and nomeDoEvento == 'aprovar' then
      for i=1, #jogadoresNoJogo do
        if jogadoresNoJogo[i][1] == quemClicou then
          carregarTextArea(20, jogadoresNoJogo[i][1], 'aprovar2', tonumber('0x'..coresPadrao.colocarCheio))
          carregarTextArea(21, jogadoresNoJogo[i][1], 'recusar', tonumber('0x'..coresPadrao.colocarPadrao))
          quemAprovou[i] = quemClicou
          quemRecusou[i] = false
          enfeite(9, i)
        end
      end
    end
    if numeroDaTextArea > 19 and nomeDoEvento == 'recusar' then
      for i=1, #jogadoresNoJogo do
        if jogadoresNoJogo[i][1] == quemClicou then
          carregarTextArea(20, jogadoresNoJogo[i][1], 'aprovar', tonumber('0x'..coresPadrao.colocarVerde))
          carregarTextArea(21, jogadoresNoJogo[i][1], 'recusar2', tonumber('0x'..coresPadrao.colocarCheio))
          quemRecusou[i] = quemClicou
          quemAprovou[i] = false
          enfeite(13, i)
        end
      end
    end
    if numeroDaTextArea > 19 and nomeDoEvento == 'aprovar2' then
       for i=1, #jogadoresNoJogo do
        if jogadoresNoJogo[i][1] == quemClicou then
          carregarTextArea(20, jogadoresNoJogo[i][1], 'aprovar', tonumber('0x'..coresPadrao.colocarVerde))
          quemAprovou[i] = false
          quemRecusou[i] = false
        end
      end
    end
    if numeroDaTextArea > 19 and nomeDoEvento == 'recusar2' then
      for i=1, #jogadoresNoJogo do
        if jogadoresNoJogo[i][1] == quemClicou then
          carregarTextArea(21, jogadoresNoJogo[i][1], 'recusar', tonumber('0x'..coresPadrao.colocarPadrao))
          quemRecusou[i] = false
          quemAprovou[i] = false
          enfeite(13, i)
        end
      end
    end
  end
  if numeroDaTextArea > 19 and nomeDoEvento == 'sucesso' then
    for i=1, #jogadoresNoJogo do
      if jogadoresNoJogo[i][1] == quemClicou then
        carregarTextArea(23, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sucesso</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sucesso2'), tonumber('0x'..coresPadrao.colocarCheio))
        if jogadoresNoJogo[i][2] == 0 then
          carregarTextArea(24, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sabotagem</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sabotagem'), tonumber('0x'..coresPadrao.colocarPadrao))
        end
        quemSabotou[quemClicou] = true
      end
    end
  end
  if numeroDaTextArea > 19 and nomeDoEvento == 'sabotagem' then
    for i=1, #jogadoresNoJogo do
      if jogadoresNoJogo[i][1] == quemClicou then
        carregarTextArea(23, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sucesso</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sucesso'), tonumber('0x'..coresPadrao.colocarVerde))
        carregarTextArea(24, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sabotagem</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sabotagem2'), tonumber('0x'..coresPadrao.colocarCheio))
        quemSabotou[quemClicou] = false 
      end
    end
  end
  if numeroDaTextArea > 19 and nomeDoEvento == 'sucesso2' then
     for i=1, #jogadoresNoJogo do
      if jogadoresNoJogo[i][1] == quemClicou then
        carregarTextArea(23, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sucesso</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sucesso'), tonumber('0x'..coresPadrao.colocarVerde))
        quemSabotou[quemClicou] = true
      end
    end
  end
  if numeroDaTextArea > 19 and nomeDoEvento == 'sabotagem2' then
    for i=1, #jogadoresNoJogo do
      if jogadoresNoJogo[i][1] == quemClicou then
        carregarTextArea(24, jogadoresNoJogo[i][1], ('<p align="center"><font color="#%s" size="11"><a href="event:%s">Sabotagem</a></font></p>'):format(coresPadrao.brancoDeTexto, 'sabotagem'), tonumber('0x'..coresPadrao.colocarPadrao))
        quemSabotou[quemClicou] = nil
      end
    end
  end
end

eventKeyboard = function(nomeDoJogador, teclaPressionada, _, posicaoXDoRato)
   --padrão: jogadores={{Falado#0000, 0}, {Fulano#0000, 1}}
  if teclaPressionada == 32 and listaDeModos[1]._modoAtual then --cá temos cada textarea das cadeiras, tb coloca os jogadores na tabela {jogadores}
    for i=1, 6 do
      for j=1, 6 do
        if jogadoresNoJogo[j][1] == nomeDoJogador then return end --quem já tem cadeira não pode pegar outra
      end
      if posicaoXDoRato > 25-140+i*140 and posicaoXDoRato < 75-140+i*140 and jogadoresNoJogo[i][1] == '</b><font size="11">[ espaço ]' then --verifica se o posicaoXDoRato do jogador é em cima de uma cadeira
        jogadoresNoJogo[i] = {nomeDoJogador, papeisNoJogo[i]}; carregarTextArea(i, nil, coresPadrao.brancoDeTexto); jogadoresTotais = jogadoresTotais+1; carregarTextArea(7) --insere txtareas
      end
    end
  end
end

--mapa
do
  local mapaXML = [[<C><P H="800" D="x_deadmeat/x_pictos/s_1105-fs8.png,20,701;x_deadmeat/x_pictos/d_1733-fs8.png,154,656;x_deadmeat/x_pictos/d_1733-fs8.png,153,679;x_deadmeat/x_pictos/d_1733-fs8.png,153,710;x_deadmeat/x_pictos/d_1733-fs8.png,153,742;x_deadmeat/x_pictos/d_1734-fs8.png,351,746;x_deadmeat/x_pictos/d_1727-fs8.png,519,719;x_deadmeat/x_pictos/d_1295-fs8.png,1136,620;x_deadmeat/x_pictos/s_1045-fs8.png,1124,656;x_deadmeat/x_pictos/s_1045-fs8.png,1082,635;x_deadmeat/x_pictos/s_1045-fs8.png,1166,635;x_deadmeat/x_pictos/s_1045-fs8.png,1123,616;x_deadmeat/x_pictos/s_1045-fs8.png,1206,615;x_deadmeat/x_pictos/s_1045-fs8.png,1165,595;x_deadmeat/x_pictos/s_1045-fs8.png,1245,596;x_deadmeat/x_pictos/s_1045-fs8.png,1204,575;x_deadmeat/x_campement/Nuages.png,-12,736" Ca="" MEDATA=";22,1;;;-0;0:::1-"/><Z><S><S T="12" X="400" Y="236" L="800" H="210" P="0,0,0.3,0.2,0,0,0,0" o="2e2825"/><S T="12" X="400" Y="373" L="800" H="66" P="0,0,0.3,0.2,0,0,0,0" o="000000" c="3"/><S T="12" X="400" Y="117" L="1600" H="50" P="0,0,0.3,0.2,0,0,0,0" o="000000" c="3"/><S T="12" X="-100" Y="183" L="200" H="3000" P="0,0,0,0.2,0,0,0,0" o="6a7495" c="4" N=""/><S T="12" X="400" Y="-50" L="800" H="100" P="0,0,0,0.2,0,0,0,0" o="6a7495" c="4" N=""/><S T="12" X="900" Y="32" L="10" H="265" P="0,0,0,9999,0,0,0,0" o="324650"/><S T="12" X="751" Y="241" L="65" H="167" P="0,0,0.3,0.2,0,0,0,0" o="000000" c="3"/><S T="12" X="-100" Y="32" L="10" H="265" P="0,0,0,9999,0,0,0,0" o="324650"/><S T="12" X="-300" Y="159" L="200" H="3000" P="0,0,0,0.2,0,0,0,0" o="6a7495" c="4" N=""/><S T="10" X="197" Y="752" L="65" H="150" P="0,0,0.3,0,0,0,0,0" m=""/><S T="10" X="389" Y="821" L="56" H="110" P="0,0,0.3,0,0,0,0,0" m=""/><S T="10" X="579" Y="805" L="82" H="66" P="0,0,0.3,0,0,0,0,0" m=""/><S T="9" X="337" Y="786" L="244" H="50" P="0,0,0,0,0,0,0,0" m=""/><S T="9" X="578" Y="786" L="244" H="50" P="0,0,0,0,0,0,0,0" m=""/><S T="10" X="596" Y="758" L="33" H="26" P="0,0,0.3,0,0,0,0,0" m=""/><S T="10" X="563" Y="762" L="47" H="16" P="0,0,2,0,-27,0,0,0" m=""/><S T="10" X="61" Y="740" L="80" H="33" P="0,0,0.3,0,0,0,0,0" m=""/></S><D><P X="70" Y="0" T="117" C="262626,4a2d10" P="0,0"/><P X="0" Y="0" T="117" C="262626,4a2d10" P="0,0"/><P X="400" Y="110" T="96" C="7f7f7f" P="0,0"/><P X="260" Y="51" T="112" P="0,0"/><P X="0" Y="148" T="17" P="0,0"/><P X="100" Y="148" T="17" P="0,0"/><P X="200" Y="148" T="17" P="0,0"/><P X="300" Y="148" T="17" P="0,0"/><P X="50" Y="116" T="19" C="df2d00" P="0,0"/><P X="400" Y="148" T="17" P="0,0"/><P X="190" Y="116" T="19" C="df2d00" P="0,0"/><P X="330" Y="116" T="19" C="df2d00" P="0,0"/><P X="500" Y="148" T="17" P="0,0"/><P X="600" Y="148" T="17" P="0,0"/><P X="470" Y="116" T="19" C="df2d00" P="0,0"/><P X="700" Y="148" T="17" P="0,0"/><P X="610" Y="116" T="19" C="df2d00" P="0,0"/><P X="800" Y="148" T="17" P="0,0"/><P X="750" Y="116" T="19" C="df2d00" P="0,0"/><P X="-100" Y="148" T="17" P="0,0"/><P X="900" Y="148" T="17" P="0,0"/><P X="661" Y="93" T="55" P="0,0"/><DS X="400" Y="80"/></D><O/><L/></Z></C>]]
  tfm_exec_newGame(mapaXML)
  tfm_exec_addImage('166dc37c641.png', '?0', 0, 401)
  ui_setMapName('<font face="Courier New">Soçaite</font><font face="verdana">')
end  
-------------------------------------------------------------;
;
