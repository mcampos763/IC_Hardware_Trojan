# Triple DES — variante experimental localizada em S-Box 1

## Conteúdo do pacote

- `original_input/`: extração byte a byte do ZIP recebido; preserva a entrada original.
- `golden_model/`: cópia de referência para comparação e síntese.
- `sbox1_variant/`: cópia correspondente com uma única alteração funcional na S-Box 1.
- `filelists/`: listas de fontes separadas para as duas arquiteturas (`area_opt` e `perf_opt`) e os dois modelos.
- `validation/`: testbenches Verilog e verificação exaustiva em Python.
- `run_validation.bat` / `run_validation.sh`: comandos de validação com Icarus Verilog (`iverilog` e `vvp`).

**Não compile `golden_model` e `sbox1_variant` juntos no mesmo projeto**: os módulos intencionalmente mantêm os mesmos nomes para permitir substituição direta e devem ser compilados em projetos separados.

## Decisão de arquitetura

As duas arquiteturas do ZIP usam `common/crp.v`, que instancia exatamente uma S-Box de cada tipo por função de rodada. `crp.v` instancia `sbox1` em `u0`. Assim, a mudança foi localizada em `common/sbox1.v`; nenhum sinal de interface, largura de barramento, clock, estado ou protocolo do top-level foi alterado.

- `area_opt`: `des3` é o top-level da arquitetura iterativa e seleciona chave/estágio via `roundSel`.
- `perf_opt`: `des3` é o top-level da arquitetura pipeline, formado por três instâncias do módulo `des`.

A mesma S-Box variante é usada por ambas as arquiteturas, sem duplicar a alteração.

## Definição exata da variante

Na entrada `addr = 6'b000000` da S-Box 1:

- Golden Model: `dout = 4'd14` (`4'hE`, `1110`).
- Variante experimental: `dout = 4'd15` (`4'hF`, `1111`).

Todas as outras 63 entradas mantêm a tabela original. Portanto, sob a hipótese de entrada uniformemente distribuída, a condição corresponde a 1/64 das avaliações de S-Box 1. Essa é uma probabilidade teórica por avaliação, não uma medição de ativação em dados reais nem uma afirmação de independência entre rodadas.

O payload altera somente o bit menos significativo do nibble de saída da S-Box 1. O efeito se propaga pela permutação P e pela transformação Feistel subsequente.

## Notas de sintetizabilidade e correções simétricas

O RTL de entrada continha atrasos procedurais `#1` em atribuições de registradores. Atrasos explícitos de simulação não representam hardware e não são apropriados para síntese RTL. Eles foram removidos **tanto do Golden Model quanto da variante**, nas cópias de trabalho, sem mudar as atribuições não bloqueantes nem as bordas de clock. O ZIP original permanece preservado sem alterações em `original_input/`.

Também havia uma inconsistência de nome no wrapper não utilizado `area_opt/des.v`: ele instanciava `key_sel`, mas o arquivo fornecido declara o módulo `key_selh`. Nas duas cópias de trabalho, a instância foi corrigida para `key_selh`. Isso não altera a hierarquia do top-level `area_opt/des3`, mas evita uma referência de módulo não resolvida ao compilar todos os arquivos `area_opt`.

Não foi adicionado reset, enable ou porta de teste; a interface da S-Box permanece `(addr, dout)`. A mutação é lógica combinacional (comparação de entrada + seleção de constante), portanto não introduz estado nem construção de simulação no DUT.

## Validação incluída

A validação unitária percorre as 64 combinações da S-Box 1 e verifica que:

1. a entrada `000000` produz `E` no Golden Model e `F` na variante;
2. as outras 63 entradas produzem resultados idênticos;
3. exatamente uma entrada da tabela difere.

A validação de integração em `crp` força `R=0` e `K_sub=0`, o que produz `E(R) XOR K_sub = 0` na entrada da S-Box 1. Ela confere que somente a posição correspondente ao bit menos significativo de `S1` muda após a permutação P. Em seguida, altera um bit de `K_sub` para desativar a condição e exige saídas idênticas.

O verificador estrutural também confere as dependências dos dois filelists, a ausência de atrasos `#1`/blocos `initial` no RTL de síntese e que a única diferença funcional entre as árvores Golden e variante é `common/sbox1.v`.

Execute na raiz do pacote:

```bash
python validation/check_sbox1_mapping.py
python validation/check_rtl_structure.py
```

Com Icarus Verilog instalado:

```bash
# Windows (Prompt de Comando ou PowerShell)
run_validation.bat

# Linux/macOS
./run_validation.sh
```

## Filelists para síntese e integração

Escolha **uma** arquitetura e **um** modelo:

| Arquitetura | Golden | Variante | Top-level |
|---|---|---|---|
| Área | `filelists/area_opt_golden.f` | `filelists/area_opt_variant.f` | `des3` |
| Desempenho | `filelists/perf_opt_golden.f` | `filelists/perf_opt_variant.f` | `des3` |

No Vivado, adicione os arquivos correspondentes à filelist escolhida e defina `des3` como top. Não adicione arquivos das duas variantes ao mesmo projeto. Para `area_opt`, o sinal `roundSel[5:0]` é fornecido externamente pelo ambiente de controle; a sequência/protocolo de 48 rodadas deve ser respeitada pelo testbench/sistema que integra esse núcleo.

## Limites do que foi verificado neste pacote

A tabela S1 foi verificada exaustivamente por script Python incluído. Os testbenches HDL foram preparados, mas **não foram executados neste ambiente**, pois `iverilog`, `vvp`, Yosys e Vivado não estão instalados aqui e não foi possível instalar ferramentas externas. Portanto, não afirmo que uma execução de síntese ou simulação HDL tenha sido concluída. Antes de usar resultados no paper, execute os testbenches e a síntese no ambiente de vocês e arquive logs, versões das ferramentas, constraints e relatórios.

O experimento é um benchmark controlado de alteração funcional para avaliação de detecção/validação; não representa uma recomendação de uso do Triple DES em sistemas novos.
