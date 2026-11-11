import SwiftUI

struct ProductoDetalleSheet: View {
    let producto: Producto
    let agregados: [Agregado]

    @Environment(CarritoStore.self) private var carrito
    @Environment(\.dismiss) private var dismiss
    @State private var varianteId: Int?
    @State private var seleccionados: Set<Int> = []
    @State private var notas = ""
    @State private var cantidad = 1
    @State private var agregado = false

    init(producto: Producto, agregados: [Agregado]) {
        self.producto = producto
        self.agregados = agregados
        let inicial = producto.variantes.first(where: \.disponible) ?? producto.variantes.first
        _varianteId = State(initialValue: inicial?.id)
    }

    private var variante: Variante? { producto.variantes.first { $0.id == varianteId } }

    private var compatibles: [Agregado] {
        guard let v = variante else { return [] }
        return agregados.filter { $0.disponible && $0.precio(para: v.tamano) != nil }
    }

    private var precioUnitario: Double {
        guard let v = variante else { return 0 }
        return agregados.filter { seleccionados.contains($0.id) }
            .reduce(v.precio) { $0 + ($1.precio(para: v.tamano) ?? 0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                if let d = producto.descripcion?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty {
                    Section { Text(d).foregroundStyle(AppColors.gris) }
                }

                Section("Elige el tamaño") {
                    ForEach(producto.variantes) { v in
                        Button {
                            varianteId = v.id
                            seleccionados.removeAll()   // los agregados dependen del tamaño
                        } label: {
                            HStack {
                                Image(systemName: v.id == varianteId ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(v.id == varianteId ? AppColors.primary : AppColors.gris)
                                Text(v.disponible ? v.tamano.capitalizadoLimpio
                                                  : "\(v.tamano.capitalizadoLimpio) — Agotado")
                                Spacer()
                                Text(v.precio.soles).foregroundStyle(AppColors.gris)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!v.disponible)
                        .opacity(v.disponible ? 1 : 0.4)
                        .accessibilityAddTraits(v.id == varianteId ? .isSelected : [])
                    }
                }

                if !compatibles.isEmpty {
                    Section("Agregados") {
                        ForEach(compatibles) { ag in
                            let marcado = seleccionados.contains(ag.id)
                            Button {
                                if marcado { seleccionados.remove(ag.id) } else { seleccionados.insert(ag.id) }
                            } label: {
                                HStack {
                                    Image(systemName: marcado ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(marcado ? AppColors.primary : AppColors.gris)
                                    Text(ag.nombre)
                                    Spacer()
                                    if let p = variante.flatMap({ ag.precio(para: $0.tamano) }) {
                                        Text("+ \(p.soles)").foregroundStyle(AppColors.gris)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(marcado ? .isSelected : [])
                        }
                    }
                }

                Section("Instrucciones especiales") {
                    TextField("Ej. sin cebolla, cortar en 12...", text: $notas, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Stepper("Cantidad: \(cantidad)", value: $cantidad, in: 1...CarritoStore.maxPorItem)
                }
            }
            .navigationTitle(producto.nombre)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Cerrar") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    guard let v = variante else { return }
                    let elegidos = agregados.filter { seleccionados.contains($0.id) }
                    carrito.agregar(ItemCarrito(producto: producto, variante: v, agregados: elegidos,
                                                cantidad: cantidad,
                                                notas: notas.trimmingCharacters(in: .whitespacesAndNewlines)))
                    agregado.toggle()
                    dismiss()
                } label: {
                    Text("Agregar al pedido · \((precioUnitario * Double(cantidad)).soles)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(variante == nil)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(.bar)
                .sensoryFeedback(.success, trigger: agregado)
            }
        }
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.visible)
    }
}
