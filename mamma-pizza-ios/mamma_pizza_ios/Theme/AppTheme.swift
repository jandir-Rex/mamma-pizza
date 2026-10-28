import SwiftUI
import Foundation

import SwiftUI

struct ProductDetailSheet: View {
    let producto: Producto
    @Environment(CartManager.self) private var cart
    @Environment(\.dismiss) private var dismiss
    
    @State private var varianteSeleccionada: ProductoVariante?
    @State private var cantidad = 1
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let urlString = producto.imagenUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color(.secondarySystemBackground))
                            }
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(producto.nombre)
                                .font(.title2.bold())
                            
                            if let desc = producto.descripcion {
                                Text(desc)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Selecciona la presentación", systemImage: "ruler")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            ForEach(producto.variantes) { variante in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(variante.tamano)
                                            .font(.body.weight(.medium))
                                    }
                                    Spacer()
                                    Text("S/.\(variante.precio, specifier: "%.2f")")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.secondary)
                                    
                                    Image(systemName: varianteSeleccionada == variante ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(varianteSeleccionada == variante ? Color.orange : Color.gray)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture {
                                    varianteSeleccionada = variante
                                }
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Cantidad")
                                .font(.headline)
                            Spacer()
                            
                            HStack(spacing: 16) {
                                Button {
                                    if cantidad > 1 { cantidad -= 1 }
                                } label: {
                                    Image(systemName: "minus")
                                        .frame(width: 32, height: 32)
                                        .background(Color(.tertiarySystemFill))
                                        .clipShape(Circle())
                                }
                                
                                Text("\(cantidad)")
                                    .font(.headline)
                                
                                Button {
                                    cantidad += 1
                                } label: {
                                    Image(systemName: "plus")
                                        .frame(width: 32, height: 32)
                                        .background(Color(.tertiarySystemFill))
                                        .clipShape(Circle())
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    .padding()
                }
                
                // BARRA INFERIOR DE ACCIÓN
                VStack {
                    Button(action: agregarAlCarrito) {
                        HStack {
                            Text("Agregar al pedido")
                            Spacer()
                            if let v = varianteSeleccionada {
                                Text("S/.\(v.precio * Double(cantidad), specifier: "%.2f")")
                            }
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.gray)
                    }
                }
            }
            .onAppear {
                varianteSeleccionada = producto.variantes.first
            }
        }
        .presentationDetents([.large])
    }
    
    private func agregarAlCarrito() {
        guard let v = varianteSeleccionada else { return }
        let item = ItemCarrito(
            producto: producto,
            variante: v,
            cantidad: cantidad,
            agregados: [],
            notas: nil
        )
        cart.agregar(item: item)
        dismiss()
    }
}
//
//  AppTheme.swift
//  MammaPizzaClient
//
//  Created by Jandirx on 30/09/26.
//