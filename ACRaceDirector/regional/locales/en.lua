local strings = {
    -- System / Connection
    ["system.connecting"] = "Attempting to connect to ACRD server at %s:%s",
    ["system.connected"] = "Connected to server.",
    ["system.disconnected"] = "Disconnected from server.",
    ["system.initializing"] = "Initializing...",
    ["system.offline_mode"] = "Offline Mode detected. Client will not run.",
    ["system.online_mode"] = "Online Mode. Attempting to fetch ACRD server data...",
    ["system.server_found"] = "ACRD server found at host: %s / port: %s",
    ["system.server_not_using_acrd"] = "Server does not use ACRD. Aborting initialization.",
    ["system.acrd_not_available"] = "ACRD not available on this server.",
    ["system.loading"] = "Loading AC Race Director.",
    ["system.waiting_server"] = "Waiting for server...",
    
    -- Status
    ["status.loading"] = "Loading AC Race Director...",
    ["status.race_director_unavailable"] = "AC Race Director unavailable offline",
    ["status.waiting"] = "Waiting for server...",
    ["status.connected"] = "Connected",
    ["status.connecting"] = "Attempting connection...",
    
    -- UI
    ["ui.connected_full"] = "● Connected (%s:%s)",
    ["ui.log_label"] = "Message Log:",
    ["ui.copy_clipboard"] = "Copy to clipboard",
    ["ui.no_messages"] = "No messages from Race Control.",
    ["ui.current_speed"] = "Current speed: %s km/h",
    ["ui.language_label"] = "Language:",
    ["ui.changing_language"] = "[ACRaceDirector] Changing language to: %s",
    
    -- SoundManager
    ["log.sound_load_error"] = "[SoundManager] Failed to load audio: %s",
    
    -- TcpClient
    ["log.tcp_connecting"] = "[TcpClient] Starting connection to %s:%s",
    ["log.tcp_create_error"] = "[TcpClient] Error creating TCP socket",
    ["log.tcp_connection_in_progress"] = "[TcpClient] Connection in progress...",
    ["log.tcp_connect_error_immediate"] = "[TcpClient] Immediate connection error: %s",
    ["log.tcp_connected_success"] = "[TcpClient] Connection established successfully!",
    ["log.tcp_handshake_sent"] = "[TcpClient] Handshake sent: %s bytes.",
    ["log.tcp_handshake_error"] = "[TcpClient] Error sending handshake: %s. Retrying shortly...",
    ["log.tcp_disconnected"] = "[TcpClient] Disconnected.",
    ["log.tcp_handshake_timeout"] = "[TcpClient] Handshake timeout, forcing CONNECTED state (fallback).",
    ["log.tcp_handshake_resent"] = "[TcpClient] Handshake resent successfully.",
    ["log.tcp_timeout_no_ping"] = "[TcpClient] Connection timeout (no PING from server).",
    ["log.tcp_socket_closed"] = "[TcpClient] Socket closed by server.",
    ["log.tcp_receive_error"] = "[TcpClient] Receive error: %s",
    
    -- NotificationManager
    ["log.notification_added"] = "[NotificationManager] Added: %s",
    ["log.notification_cleared"] = "[NotificationManager] Clear all",
    
    -- ACRaceDirector
    ["log.acrd_initializing"] = "[ACRaceDirector] Initializing...",
    ["log.acrd_message_format"] = "[ACRaceDirector] %s",
    
    -- Localization
    ["log.loc_loaded"] = "Localization loaded: %s",
    ["log.loc_load_error"] = "Failed to load localization: %s. Error: %s",
    
    -- Notifications & Flags
    ["notif.connected"] = "Connected.",
    ["flag.yellow"] = "YELLOW FLAG",
    ["flag.red"] = "RED FLAG",
    ["flag.green"] = "GREEN FLAG",
    ["flag.safety_car"] = "SAFETY CAR",
    ["flag.virtual_safety_car"] = "VIRTUAL SAFETY CAR",
    ["flag.race_control"] = "RACE CONTROL",

    ["notif.yellow"] = "Hazard ahead. Slow down and no overtaking.",
    ["notif.red"] = "Session suspended. Reduce speed and return to pits.",
    ["notif.green"] = "Track clear. Resume racing.",
    ["notif.sc"] = "Safety Car deployed. No overtaking, follow the leader.",
    ["notif.vsc"] = "Virtual Safety Car. Maintain delta and reduce speed.",
    ["notif.race"] = "Message from Race Control.",
}

return strings
