# Algoritmos de Simplificação e Normalização de Gramáticas Livres de Contexto

Este projeto implementa os principais algoritmos para manipulação de gramáticas livres de contexto (GLCs). O código é desenvolvido em Julia e tem como objetivo demonstrar, de forma prática, o funcionamento de cada uma das etapas de simplificação e normalização.

## Sobre o Projeto

O trabalho consiste na implementação dos seguintes algoritmos:

### Simplificação de Gramáticas
- **Remoção de Símbolos Inúteis**: Identifica e elimina símbolos não-terminais que não podem ser alcançados a partir do símbolo inicial ou que não geram cadeias de terminais.
- **Remoção de Produções Vazias (ε)**: Elimina produções que derivam para a string vazia, ajustando a gramática para garantir que a linguagem gerada permaneça a mesma.
- **Remoção de Produções Unitárias**: Elimina produções do tipo `A -> B`, onde `A` e `B` são não-terminais, substituindo-as por produções equivalentes.

### Melhorias na Gramática
- **Fatoração à Esquerda**: Reestrutura a gramática para remover prefixos comuns nas produções de um mesmo não-terminal, uma técnica essencial para a construção de parsers preditivos.
- **Remoção de Recursão à Esquerda**: Elimina produções que derivam recursivamente a si mesmas (`A -> Aα`), transformando-as em uma forma não-recursiva.

### Formas Normais
- **Forma Normal de Chomsky (FNC)**: Converte a gramática para um formato onde todas as produções são da forma `A -> BC` ou `A -> a`.

## Como Executar

O projeto é escrito em Julia. Para executá-lo, certifique-se de ter o ambiente Julia configurado e os pacotes necessários instalados:

```bash
import Pkg
Pkg.add("DataStructures")
Pkg.add("Combinatorics")
