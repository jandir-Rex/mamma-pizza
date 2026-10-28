import SwiftUI

struct ProductDetailSheet: View {
    let producto: Producto
    let agregados: [Agregado]
    
    @Environment(CartManager.self) private var cart
    @Environment(\.dismiss) private var dismiss
    
    @State private var varianteSeleccionada: ProductoVariante?
    @State private var agregadosSeleccionados: Set<Int> = []
    @State private var notas = ""
    @State private var cantidad = 1
    
    init(producto: Producto, agregados: [Agregado]) {
        self.producto = producto
        self.agregados = agregados
        let inicial = producto.variantes.first(where: { $0.disponible }) ?? producto.variantes.first
        _varianteSeleccionada = State(initialValue: inicial)
    }
    
    private var precioUnitario: Double {
        guard let v = varianteSeleccionada else { return 0 }
        let extras = agregados
            .filter { agregadosSeleccionados.contains($0.id) }
            .reduce(0.0) { sum, agg in
                let precioExtra = agg.precioParaTamano(v.tamano) ?? 0
                return sum + precioExtra
            }
        return v.precio + extras
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Cabecera visual
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)
                        
                        Text("🍕")
                            .font(.system(size: 60))
                            .padding()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(producto.nombre)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.dark)
                        
                        if let desc = producto.descripcion {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.gray)
                        }
                    }
                    
                    // Selector de variantes / tamaños
                    if !producto.variantes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tamaño / Opción")
                                .font(.headline)
                                .foregroundStyle(AppColors.dark)
                            
                            ForEach(producto.variantes) { variante in
                                HStack {
                                    Text(variante.tamano)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("S/. \(variante.precio.toStringAsFixed(2))")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.primary)
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(varianteSeleccionada?.id == variante.id ? AppColors.primary : AppColors.border, lineWidth: varianteSeleccionada?.id == variante.id ? 2 : 1)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if variante.disponible {
                                        varianteSeleccionada = variante
                                    }
                                }
                                .opacity(variante.disponible ? 1.0 : 0.5)
                            }
                        }
                    }
                    
                    // Notas adicionales
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notas especiales")
                            .font(.headline)
                            .foregroundStyle(AppColors.dark)
                        
                        TextField("Ej. Sin cebolla, bien dorada...", text: $notas)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                    }
                }
                .padding()
            }
            .background(AppColors.bg)
            .safeAreaInset(edge: .bottom) {
                // Barra inferior de acción
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Total")
                            .font(.caption)
                            .foregroundStyle(AppColors.gray)
                        Text("S/. \((precioUnitario * Double(cantidad)).toStringAsFixed(2))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: agregarAlCarrito) {
                        Text("Agregar al Carrito")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(AppColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
                .background(Color.white.shadow(color: Color.black.opacity(0.05), radius: 8, y: -4))
            }
            .navigationTitle("Detalle del Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
    
    private func agregarAlCarrito() {
        // Lógica para añadir al carrito
        dismiss()
    }
}
