# Regras de Desenvolvimento do Sedge

## Contribuição

- Novos colaboradores não devem modificar diretamente componentes críticos do sistema, como VFS, VMM, PMM e escalonador.
- Alterações nesses componentes exigem uma justificativa técnica documentando:
  - O problema que a alteração resolve.
  - O comportamento anterior.
  - O comportamento esperado.
  - Possíveis impactos em outros componentes.
- Alterações em componentes críticos devem passar por revisão antes de serem integradas.

## Inteligência Artificial

- O uso de Inteligência Artificial é permitido, desde que realizado com cautela.
- Tarefas simples, como documentação, geração de código repetitivo e auxílio em tarefas de desenvolvimento, são permitidas.
- Todo código gerado por IA deve ser revisado e compreendido pelo colaborador antes de ser submetido.
- O colaborador é inteiramente responsável pelas alterações geradas com auxílio de IA.

## Integridade do Projeto

- Toda contribuição deve respeitar a arquitetura e as convenções existentes no projeto.
- Alterações não devem introduzir dependências desnecessárias.
- Não devem ser introduzidas funcionalidades que não tenham relação com os objetivos do projeto sem discussão prévia.
