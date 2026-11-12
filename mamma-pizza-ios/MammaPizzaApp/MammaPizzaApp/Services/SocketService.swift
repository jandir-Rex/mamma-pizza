import Foundation
import SocketIO

@MainActor
final class SocketService {
    static let shared = SocketService()
    private init() {}

    private var manager: SocketManager?
    private(set) var socket: SocketIOClient?

    /// Devuelve el socket existente (conectado o conectándose) o crea uno nuevo.
    @discardableResult
    func conectar() -> SocketIOClient? {
        if let socket { return socket }
        guard let token = KeychainStore.get("token") else { return nil }

        let m = SocketManager(socketURL: AppConfig.socketURL,
                              config: [
                                .forceWebsockets(true),
                                .reconnects(true),
                                .reconnectAttempts(10),
                                .reconnectWait(2),
                                .compress
                              ])
        let s = m.defaultSocket
        s.connect(withPayload: ["token": token])
        manager = m
        socket = s
        return s
    }

    /// Llamar al cerrar sesión (el token cambia).
    func desconectar() {
        socket?.disconnect()
        socket?.removeAllHandlers()
        manager = nil
        socket = nil
    }
}
