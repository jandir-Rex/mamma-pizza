import SwiftUI
import Foundation

import SwiftUI

@Observable
final class CartManager {
    var items: [ItemCarrito] = []
    
    var total: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }
    
    var cantidadItems: Int {
        items.reduce(0) { $0 + $1.cantidad }
    }
    
    func agregar(item: ItemCarrito) {
        if let index = items.firstIndex(where: { $0.variante.id == item.variante.id }) {
            items[index].cantidad += item.cantidad
        } else {
            items.append(item)
        }
    }
    
    func cambiarCantidad(id: UUID, delta: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].cantidad += delta
        if items[index].cantidad <= 0 {
            items.remove(at: index)
        }
    }
    
    // Método para eliminar elementos deslizando en la lista (.onDelete)
    func quitar(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    func vaciar() {
        items.removeAll()
    }
}
//
//  BadgeEstadoPedido.swift
//  MammaPizzaClient
//
//  Created by Jandirx on 30/09/26.
//