using DataStructures
using Combinatorics

# Definição da estrutura para a gramática
mutable struct Gramatica
    simbolo_inicial::String
    nao_terminais::Set{String}
    terminais::Set{Char}
    producoes::DefaultDict{String, Vector{String}}
end

# Construtor para facilitar a criação da gramática
function Gramatica()
    return Gramatica("", Set{String}(), Set{Char}(), DefaultDict{String, Vector{String}}([]))
end

# Função para carregar a gramática a partir de um texto
function carregar_gramatica(texto::String)::Gramatica
    g = Gramatica()
    linhas = split(strip(texto), '\n')
    for (i, linha) in enumerate(linhas)
        partes = split(linha, "->")
        nao_terminal = strip(partes[1])
        if i == 1
            g.simbolo_inicial = nao_terminal
        end
        push!(g.nao_terminais, nao_terminal)
        
        opcoes = split(strip(partes[2]), '|')
        for opcao in opcoes
            producao = strip(opcao)
            push!(g.producoes[nao_terminal], producao)
            
            for char in producao
                if !isuppercase(char) && char != 'ε'
                    push!(g.terminais, char)
                end
            end
        end
    end
    return g
end

# Representação da gramática para impressão
function Base.show(io::IO, g::Gramatica)
    println(io, "Símbolo Inicial: $(g.simbolo_inicial)")
    println(io, "Não-terminais: $(join(sort(collect(g.nao_terminais)), ", "))")
    println(io, "Terminais: $(join(sort(collect(g.terminais)), ", "))")
    println(io, "Produções:")
    for nt in sort(collect(keys(g.producoes)))
        producoes_str = join(g.producoes[nt], " | ")
        println(io, "$nt -> $producoes_str")
    end
end

# --- Simplificação ---
# ---------------------

# Copia uma gramática para uma nova variável
function _copiar_gramatica(g_origem::Gramatica)::Gramatica
    g_destino = Gramatica()
    g_destino.simbolo_inicial = g_origem.simbolo_inicial
    g_destino.nao_terminais = copy(g_origem.nao_terminais)
    g_destino.terminais = copy(g_origem.terminais)
    for (nt, prods) in g_origem.producoes
        g_destino.producoes[nt] = copy(prods)
    end
    return g_destino
end

# a) Remove símbolos inúteis
function remover_simbolos_inuteis(g::Gramatica)::Gramatica
    g_simplificada = _copiar_gramatica(g)
    
    produtivos = Set{String}()
    mudou = true
    while mudou
        mudou = false
        for (nt, producoes) in g_simplificada.producoes
            if nt in produtivos
                continue
            end
            for prod in producoes
                if all(!isuppercase(c) || string(c) in produtivos for c in prod)
                    push!(produtivos, nt)
                    mudou = true
                    break
                end
            end
        end
    end
    
    alcancaveis = Set{String}()
    push!(alcancaveis, g_simplificada.simbolo_inicial)
    fila = Queue{String}()
    enqueue!(fila, g_simplificada.simbolo_inicial)
    while !isempty(fila)
        nt = dequeue!(fila)
        if haskey(g_simplificada.producoes, nt)
            for prod in g_simplificada.producoes[nt]
                for char in prod
                    if isuppercase(char) && string(char) ∉ alcancaveis
                        push!(alcancaveis, string(char))
                        enqueue!(fila, string(char))
                    end
                end
            end
        end
    end
    
    uteis = intersect(produtivos, alcancaveis)
    
    nova_producoes = DefaultDict{String, Vector{String}}([])
    novos_terminais = Set{Char}()
    for nt in uteis
        if haskey(g_simplificada.producoes, nt)
            for prod in g_simplificada.producoes[nt]
                if all(!isuppercase(c) || string(c) in uteis for c in prod)
                    push!(nova_producoes[nt], prod)
                    for char in prod
                        if !isuppercase(char) && char != 'ε'
                            push!(novos_terminais, char)
                        end
                    end
                end
            end
        end
    end
    
    g_simplificada.producoes = nova_producoes
    g_simplificada.nao_terminais = uteis
    g_simplificada.terminais = novos_terminais
    
    return g_simplificada
end

# b) Remove produções vazias
function remover_producoes_vazias(g::Gramatica)::Gramatica
    g_simplificada = _copiar_gramatica(g)
    anulaveis = Set{String}()
    mudou = true
    while mudou
        mudou = false
        for (nt, producoes) in g_simplificada.producoes
            if nt in anulaveis
                continue
            end
            for prod in producoes
                if prod == "ε" || (all(isuppercase(c) && string(c) in anulaveis for c in prod) && !any(!isuppercase(c) for c in prod))
                    push!(anulaveis, nt)
                    mudou = true
                    break
                end
            end
        end
    end
    
    nova_producoes = DefaultDict{String, Vector{String}}([])
    for (nt, producoes) in g_simplificada.producoes
        for prod in producoes
            if prod == "ε"
                continue
            end
            
            if !(prod in nova_producoes[nt])
                push!(nova_producoes[nt], prod)
            end
            
            anulaveis_na_prod_indices = [i for i=1:length(prod) if isuppercase(prod[i]) && string(prod[i]) in anulaveis]

            for i = 1:length(anulaveis_na_prod_indices)
                for combo in combinations(anulaveis_na_prod_indices, i)
                    nova_prod_list = collect(prod)
                    deleteat!(nova_prod_list, collect(combo))
                    nova_prod = join(nova_prod_list)
                    if nova_prod == ""
                        nova_prod = "ε"
                    end
                    if !(nova_prod in nova_producoes[nt]) && nova_prod != "ε"
                        push!(nova_producoes[nt], nova_prod)
                    end
                end
            end
        end
    end
    
    if g_simplificada.simbolo_inicial in anulaveis && "ε" ∉ nova_producoes[g_simplificada.simbolo_inicial]
        novo_simbolo_inicial = "S0"
        while novo_simbolo_inicial in g_simplificada.nao_terminais
            novo_simbolo_inicial *= "0"
        end
        push!(nova_producoes[novo_simbolo_inicial], g_simplificada.simbolo_inicial)
        push!(nova_producoes[novo_simbolo_inicial], "ε")
        g_simplificada.simbolo_inicial = novo_simbolo_inicial
        push!(g_simplificada.nao_terminais, novo_simbolo_inicial)
    end
    
    g_simplificada.producoes = nova_producoes
    return g_simplificada
end

# c) Remove produções unitárias
function remover_producoes_unitarias(g::Gramatica)::Gramatica
    g_simplificada = _copiar_gramatica(g)
    fechamento_unitario = DefaultDict{String, Set{String}}(() -> Set{String}())
    for nt in g_simplificada.nao_terminais
        push!(fechamento_unitario[nt], nt)
    end
    
    mudou = true
    while mudou
        mudou = false
        for nt in g_simplificada.nao_terminais
            if haskey(g_simplificada.producoes, nt)
                for prod in g_simplificada.producoes[nt]
                    if prod in g_simplificada.nao_terminais && !(prod in fechamento_unitario[nt])
                        union!(fechamento_unitario[nt], fechamento_unitario[prod])
                        mudou = true
                    end
                end
            end
        end
    end
    
    nova_producoes = DefaultDict{String, Vector{String}}([])
    for nt in g_simplificada.nao_terminais
        for derivacao in fechamento_unitario[nt]
            if haskey(g_simplificada.producoes, derivacao)
                for prod in g_simplificada.producoes[derivacao]
                    if length(prod) > 1 || !(prod in g_simplificada.nao_terminais)
                        if !(prod in nova_producoes[nt])
                             push!(nova_producoes[nt], prod)
                        end
                    end
                end
            end
        end
    end
    
    g_simplificada.producoes = nova_producoes
    return g_simplificada
end

# --- Formas Normais ---
# ----------------------

# Função auxiliar para copiar DefaultDict
function _copiar_producoes(producoes::DefaultDict{String, Vector{String}})
    temp = DefaultDict{String, Vector{String}}([])
    for (k, v) in producoes
        temp[k] = copy(v)
    end
    return temp
end

# a) Forma Normal de Chomsky (FNC)
function para_fnc(g::Gramatica)::Gramatica
    g_normalizada = _copiar_gramatica(g)
    
    novos_simbolos = 0
    function get_novo_simbolo()
        novos_simbolos += 1  # Removido 'nonlocal'
        novo_simbolo = "X$(novos_simbolos)"
        while novo_simbolo in g_normalizada.nao_terminais
            novos_simbolos += 1
            novo_simbolo = "X$(novos_simbolos)"
        end
        push!(g_normalizada.nao_terminais, novo_simbolo)
        return novo_simbolo
    end

    # Passo 1: Isolar terminais em produções de tamanho > 1
    temp_producoes = _copiar_producoes(g_normalizada.producoes)
    g_normalizada.producoes = DefaultDict{String, Vector{String}}([])
    
    substituicoes_terminais = Dict{Char, String}()
    for (nt, producoes) in temp_producoes
        for prod in producoes
            if length(prod) > 1 && any(!isuppercase(c) for c in prod)
                nova_prod_list = String[]
                for char in prod
                    if !isuppercase(char)
                        if !haskey(substituicoes_terminais, char)
                            novo_nt = get_novo_simbolo()
                            substituicoes_terminais[char] = novo_nt
                            push!(g_normalizada.producoes[novo_nt], string(char))
                        end
                        push!(nova_prod_list, substituicoes_terminais[char])
                    else
                        push!(nova_prod_list, string(char))
                    end
                end
                push!(g_normalizada.producoes[nt], join(nova_prod_list))
            else
                push!(g_normalizada.producoes[nt], prod)
            end
        end
    end

    # Passo 2: Quebrar produções longas em produções de tamanho 2
    temp_producoes = _copiar_producoes(g_normalizada.producoes)
    g_normalizada.producoes = DefaultDict{String, Vector{String}}([])
    for (nt, producoes) in temp_producoes
        for prod in producoes
            if length(prod) > 2
                current_prod = prod
                
                while length(current_prod) > 2
                    primeiro_simbolo = current_prod[1:1]
                    sufixo = current_prod[2:end]
                    
                    novo_nt = get_novo_simbolo()
                    push!(g_normalizada.producoes[novo_nt], sufixo)
                    
                    current_prod = "$(primeiro_simbolo)$(novo_nt)"
                end
                
                push!(g_normalizada.producoes[nt], current_prod)
            else
                push!(g_normalizada.producoes[nt], prod)
            end
        end
    end
    
    return g_normalizada
end

# b) Forma Normal de Greibach (FNG)
function para_fng(g::Gramatica)::Gramatica
    g_normalizada = _copiar_gramatica(g)
    
    # Para uma implementação simples da FNG, vamos apenas verificar
    # se as produções já estão em formato FNG (começam com terminal)
    nova_producoes = DefaultDict{String, Vector{String}}([])
    
    for (nt, producoes) in g_normalizada.producoes
        for prod in producoes
            # Se a produção está vazia ou é epsilon, manter
            if prod == "ε" || isempty(prod)
                push!(nova_producoes[nt], prod)
                continue
            end
            
            # Se já começa com terminal (FNG), manter
            if !isuppercase(prod[1])
                push!(nova_producoes[nt], prod)
            else
                # Para simplificar, vamos tentar uma transformação básica
                # Se começa com não-terminal, tentar substituir
                primeiro_nt = string(prod[1])
                resto = prod[2:end]
                
                # Procurar por produções do primeiro não-terminal que começam com terminal
                substituicoes_feitas = false
                if haskey(g_normalizada.producoes, primeiro_nt)
                    for sub_prod in g_normalizada.producoes[primeiro_nt]
                        if !isempty(sub_prod) && sub_prod != "ε" && !isuppercase(sub_prod[1])
                            nova_prod = sub_prod * resto
                            push!(nova_producoes[nt], nova_prod)
                            substituicoes_feitas = true
                        end
                    end
                end
                
                # Se não conseguiu fazer substituições, manter a produção original
                if !substituicoes_feitas
                    push!(nova_producoes[nt], prod)
                end
            end
        end
    end
    
    g_normalizada.producoes = nova_producoes
    return g_normalizada
end

# --- Melhorias ---
# -----------------

# a) Fatoração à esquerda
function fatoracao_esquerda(g::Gramatica)::Gramatica
    g_melhorada = _copiar_gramatica(g)
    
    nao_terminais_a_processar = collect(g_melhorada.nao_terminais)
    while !isempty(nao_terminais_a_processar)
        nt = popfirst!(nao_terminais_a_processar)
        
        producoes_originais = get(g_melhorada.producoes, nt, String[])
        
        if isempty(producoes_originais)
            continue
        end
        
        prefixos_comuns = DefaultDict{Char, Vector{String}}([])
        for prod in producoes_originais
            if !isempty(prod)
                push!(prefixos_comuns[prod[1]], prod)
            end
        end
        
        novas_producoes_para_nt = String[]
        for (prefixo, prods_com_mesmo_prefixo) in prefixos_comuns
            if length(prods_com_mesmo_prefixo) > 1
                
                sufixos = [p[length(string(prefixo))+1:end] for p in prods_com_mesmo_prefixo]
                sufixos = [s == "" ? "ε" : s for s in sufixos]
                
                novo_nt_nome = "$(nt)_fatorado"
                while novo_nt_nome in g_melhorada.nao_terminais
                    novo_nt_nome *= "0"
                end
                push!(g_melhorada.nao_terminais, novo_nt_nome)
                
                push!(novas_producoes_para_nt, "$(prefixo)$(novo_nt_nome)")
                
                g_melhorada.producoes[novo_nt_nome] = sufixos
                
                if !(novo_nt_nome in nao_terminais_a_processar)
                    push!(nao_terminais_a_processar, novo_nt_nome)
                end
            else
                push!(novas_producoes_para_nt, first(prods_com_mesmo_prefixo))
            end
        end
        
        g_melhorada.producoes[nt] = novas_producoes_para_nt
    end
    
    return g_melhorada
end

# b) Remoção de recursão à esquerda
function remover_recursao_esquerda(g::Gramatica)::Gramatica
    g_melhorada = _copiar_gramatica(g)
    
    nova_producoes = DefaultDict{String, Vector{String}}([])
    for nt in g_melhorada.nao_terminais
        recursivas = String[]
        nao_recursivas = String[]
        
        if haskey(g_melhorada.producoes, nt)
            for prod in g_melhorada.producoes[nt]
                if startswith(prod, nt)
                    push!(recursivas, prod[length(nt)+1:end])
                else
                    push!(nao_recursivas, prod)
                end
            end
        end
        
        if !isempty(recursivas)
            novo_nt = "$(nt)\'"
            while novo_nt in g_melhorada.nao_terminais
                novo_nt *= "\'"
            end
            push!(g_melhorada.nao_terminais, novo_nt)
            
            for prod in nao_recursivas
                push!(nova_producoes[nt], "$(prod)$(novo_nt)")
            end
            
            for rec_prod in recursivas
                push!(nova_producoes[novo_nt], "$(rec_prod)$(novo_nt)")
            end
            push!(nova_producoes[novo_nt], "ε")
        else
            if haskey(g_melhorada.producoes, nt)
                nova_producoes[nt] = g_melhorada.producoes[nt]
            end
        end
    end
    
    g_melhorada.producoes = nova_producoes
    return g_melhorada
end

# Exemplo de uso
function main()
    gramatica_exemplo_texto = """
    S -> aAa | bBv
    A -> a | aA
    B -> b | bB
    """
    
    println("--- Gramática Original ---")
    g_original = carregar_gramatica(gramatica_exemplo_texto)
    println(g_original)

    println("\n" * "="^30 * "\n")
    println("--- Simplificação ---")
    
    g_simplificada_inuteis = remover_simbolos_inuteis(g_original)
    println("\n--- a) Após remover símbolos inúteis ---")
    println(g_simplificada_inuteis)
    
    g_vazia = carregar_gramatica("S -> aA | bB\nA -> c | ε\nB -> d")
    g_vazia_sem_vazias = remover_producoes_vazias(g_vazia)
    println("\n--- b) Após remover produções vazias ---")
    println(g_vazia_sem_vazias)
    
    g_unit = carregar_gramatica("S -> A | B\nA -> a\nB -> b")
    g_simplificada_unit = remover_producoes_unitarias(g_unit)
    println("\n--- c) Após remover produções unitárias ---")
    println(g_simplificada_unit)
    
    println("\n" * "="^30 * "\n")
    println("--- Formas Normais ---")
    
    # Teste completo de FNC
    println("\n" * "="^30 * "\n")
    println("--- Teste de FNC completo ---")
    
    # Gramática de exemplo para FNC
    g_fnc_exemplo = carregar_gramatica("S -> aA | bB\nA -> Aab | b\nB -> Bb | a")
    println("\nGramática inicial para FNC:")
    println(g_fnc_exemplo)

    # 1. Remover recursão à esquerda
    g_sem_recursao = remover_recursao_esquerda(g_fnc_exemplo)
    println("\nApós remover recursão à esquerda:")
    println(g_sem_recursao)

    # 2. Fatorar à esquerda
    g_fatorada = fatoracao_esquerda(g_sem_recursao)
    println("\nApós fatoração à esquerda:")
    println(g_fatorada)

    # 3. Converter para FNC e imprimir o resultado final
    g_normalizada_fnc = para_fnc(g_fatorada)
    println("\n--- Gramática em Forma Normal de Chomsky (FNC) ---")
    println(g_normalizada_fnc)

    # Teste de FNG
    println("\n" * "="^30 * "\n")
    println("--- Teste de FNG completo ---")
    
    g_fng_exemplo = carregar_gramatica("S -> aA | bB\nA -> aAb | b\nB -> bBa | a")
    println("\nGramática inicial para FNG:")
    println(g_fng_exemplo)
    
    # 1. Remover recursão à esquerda (necessário para FNG)
    g_fng_sem_recursao = remover_recursao_esquerda(g_fng_exemplo)
    println("\nApós remover recursão à esquerda:")
    println(g_fng_sem_recursao)

    # 2. Fatorar à esquerda (necessário para FNG)
    g_fng_fatorada = fatoracao_esquerda(g_fng_sem_recursao)
    println("\nApós fatoração à esquerda:")
    println(g_fng_fatorada)

    # 3. Converter para FNG
    g_normalizada_fng = para_fng(g_fng_fatorada)
    println("\n--- Gramática em Forma Normal de Greibach (FNG) ---")
    println(g_normalizada_fng)

    println("\n" * "="^30 * "\n")
    println("--- Melhorias ---")
    
    g_fatoracao = carregar_gramatica("S -> aAB | aC\nA -> a\nB -> b\nC -> c")
    g_fatorada_melhoria = fatoracao_esquerda(g_fatoracao)
    println("\n--- a) Após fatoração à esquerda ---")
    println(g_fatorada_melhoria)

    g_recursao = carregar_gramatica("S -> Sa | Sb | c")
    g_sem_recursao_melhoria = remover_recursao_esquerda(g_recursao)
    println("\n--- b) Após remoção de recursão à esquerda ---")
    println(g_sem_recursao_melhoria)

    # Teste simples da FNG
    println("\n--- Teste simples FNG ---")
    try
        g_teste = carregar_gramatica("S -> aA\nA -> b")
        g_fng_teste = para_fng(g_teste)
        println("Funcionou!")
        println(g_fng_teste)
    catch e
        println("Erro na FNG: ", e)
    end
end

main()