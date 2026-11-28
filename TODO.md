# TODO — Sedge

- [ ] copy_from_user e copy_to_user
- [ ] is_in_user_range

## VFS
- [x] VFS Básico
- [x] Corrigir vfs_create que deve passar apenas a PATH sem o prefixo 'VOL:'
- [x] Colocar handle_type_t type no stat_t
- [x] Fazer o vfs_check_fs não rejeitar Filesystems que não tem todas as operações
- [ ] Adicionar verificação de 'h' nulo no vfs_open
- [ ] Mudar verificação de ops->write para ops->create
- [ ] Fazer vfs_unmount decrementar num_volumes, copiar só até ':' e tirar de volumes[]
