local strings = {
    -- System / Connection
    ["system.connecting"] = "Tentando conectar ao servidor ACRD em %s:%s",
    ["system.connected"] = "Conectado ao servidor.",
    ["system.disconnected"] = "Desconectado do servidor.",
    ["system.initializing"] = "Inicializando...",
    ["system.offline_mode"] = "Modo Offline detectado. Cliente não será executado.",
    ["system.online_mode"] = "Modo Online. Tentando obter dados do servidor ACRD...",
    ["system.server_found"] = "Obtido servidor ACRD no host: %s / porta: %s",
    ["system.server_not_using_acrd"] = "Servidor não utiliza ACRD. Interrompendo inicialização.",
    ["system.acrd_not_available"] = "ACRD não disponível neste servidor.",
    ["system.loading"] = "Carregando AC Race Director.",
    ["system.waiting_server"] = "Aguardando servidor...",
    
    -- Status
    ["status.loading"] = "Carregando AC Race Director...",
    ["status.race_director_unavailable"] = "AC Race Director não disponível offline",
    ["status.waiting"] = "Aguardando servidor...",
    ["status.connected"] = "Conectado",
    ["status.connecting"] = "Tentando conexão...",
    
    -- UI
    ["ui.connected_full"] = "● Conectado (%s:%s)",
    ["ui.log_label"] = "Log de Mensagens:",
    ["ui.copy_clipboard"] = "Copiar para a área de transferência",
    ["ui.no_messages"] = "Sem mensagens da Direção de Corrida.",
    ["ui.current_speed"] = "Velocidade atual: %s km/h",
    ["ui.language_label"] = "Idioma:",
    ["ui.changing_language"] = "[ACRaceDirector] Alterando idioma para: %s",
    
    -- SoundManager
    ["log.sound_load_error"] = "[SoundManager] Falha ao carregar áudio: %s",
    
    -- TcpClient
    ["log.tcp_connecting"] = "[TcpClient] Iniciando conexão com %s:%s",
    ["log.tcp_create_error"] = "[TcpClient] Erro ao criar socket TCP",
    ["log.tcp_connection_in_progress"] = "[TcpClient] Conexão em andamento...",
    ["log.tcp_connect_error_immediate"] = "[TcpClient] Erro imediato ao conectar: %s",
    ["log.tcp_connected_success"] = "[TcpClient] Conexão estabelecida com sucesso!",
    ["log.tcp_handshake_sent"] = "[TcpClient] Handshake enviado: %s bytes.",
    ["log.tcp_handshake_error"] = "[TcpClient] Erro ao enviar handshake: %s. Tentando novamente em breve...",
    ["log.tcp_disconnected"] = "[TcpClient] Desconectado.",
    ["log.tcp_handshake_timeout"] = "[TcpClient] Timeout de handshake, mas forçando estado CONECTADO (fallback).",
    ["log.tcp_handshake_resent"] = "[TcpClient] Handshake reenviado com sucesso.",
    ["log.tcp_timeout_no_ping"] = "[TcpClient] Timeout de conexão (sem PING do servidor).",
    ["log.tcp_socket_closed"] = "[TcpClient] Socket fechado pelo servidor.",
    ["log.tcp_receive_error"] = "[TcpClient] Erro de recepção: %s",
    
    -- NotificationManager
    ["log.notification_added"] = "[NotificationManager] Adicionada: %s",
    ["log.notification_cleared"] = "[NotificationManager] Limpar tudo",
    
    -- ACRaceDirector
    ["log.acrd_initializing"] = "[ACRaceDirector] Inicializando...",
    ["log.acrd_message_format"] = "[ACRaceDirector] %s",
    
    -- Localization
    ["log.loc_loaded"] = "Localização carregada: %s",
    ["log.loc_load_error"] = "Falha ao carregar localização: %s. Erro: %s",
    
    -- Notifications & Flags
    ["notif.connected"] = "Conectado.",
    ["flag.yellow"] = "BANDEIRA AMARELA",
    ["flag.red"] = "BANDEIRA VERMELHA",
    ["flag.green"] = "BANDEIRA VERDE",
    ["flag.safety_car"] = "SAFETY CAR",
    ["flag.virtual_safety_car"] = "VIRTUAL SAFETY CAR",
    ["flag.race_control"] = "DIREÇÃO DE PROVA",
    
    ["notif.yellow"] = "Perigo à frente. Reduza e não ultrapasse.",
    ["notif.red"] = "Sessão paralisada. Reduza e volte aos boxes.",
    ["notif.green"] = "Pista limpa. Corrida retomada.",
    ["notif.sc"] = "Safety Car na pista. Mantenha fila e não ultrapasse.",
    ["notif.vsc"] = "Virtual Safety Car. Mantenha o delta.",
    ["notif.race"] = "Mensagem da Direção de Prova.",
}

return strings
