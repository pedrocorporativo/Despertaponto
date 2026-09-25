<<<<<<< HEAD
# Despertador Pro

Aplicativo Android de despertador com interface moderna.

## Funcionalidades planejadas/implementadas

- Vários alarmes.
- Ativar/desativar individualmente.
- Horário em formato 24h.
- Repetição por dia da semana.
- Nome personalizado.
- Escolha do aplicativo para abrir.
- Tela de alarme em primeiro plano.
- Compatibilidade com tela bloqueada.
- Botão para desligar e abrir o aplicativo.
- Toque selecionável na interface.
- Persistência local dos alarmes.
- Interface Material 3 escura.
- Gestos para excluir alarmes.
- Build automático de APK via GitHub Actions.

## Gerar APK pelo celular

1. Crie uma conta no GitHub.
2. Crie um repositório novo.
3. Envie todos os arquivos desta pasta.
4. Abra a aba **Actions**.
5. Execute **Build Android APK**.
6. Quando terminar, abra o artefato **Despertador-Pro** e baixe o APK.

## Observação importante

Android moderno impõe restrições para execução em segundo plano. O projeto usa uma Activity de alarme que pode aparecer sobre a tela bloqueada, e o aplicativo escolhido é aberto quando o usuário toca no botão de desligar.

Para uma versão de produção, ainda é recomendável adicionar:
- agendamento nativo de exact alarms para cada dia;
- persistência/reagendamento após reboot;
- solicitação explícita de `SCHEDULE_EXACT_ALARM`;
- seleção de apps instalada no aparelho via PackageManager;
- canais de áudio/notificação;
- controle de volume e vibração;
- snooze;
- desafios para desligar;
- testes específicos por fabricante (Samsung, Xiaomi, Motorola etc.).
=======
# Despertaponto
>>>>>>> 0cc0ffc90a479bfb7474ec215f4891ecf22547db
