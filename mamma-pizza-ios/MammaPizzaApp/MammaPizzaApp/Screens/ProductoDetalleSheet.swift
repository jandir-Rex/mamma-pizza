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
    @State private var mostrarTopeAlcanzado = false

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
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    cabecera
                    seccionTamano
                    if !compatibles.isEmpty { seccionAgregados }
                    seccionNotas
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .fondoApp()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Cerrar") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) { barraAgregar }
        }
        .presentationDetents([.fraction(0.8), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColors.bg)
        .alert("Llegaste al máximo por producto", isPresented: $mostrarTopeAlcanzado) {
            Button("Entendido") { dismiss() }
        } message: {
            Text("Solo puedes tener hasta \(CarritoStore.maxPorItem) unidades de este producto en tu pedido. Ya ajustamos la cantidad por ti.")
        }
    }

    // MARK: Secciones

    private var cabecera: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProductoImagen(url: producto.imagenUrl, size: 220, radius: 28,
                           icono: iconoCategoria(producto.categoriaNombre))
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 6) {
                Text(producto.nombre).font(.marca(.title))
                if let d = producto.descripcion?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty {
                    Text(d).font(.subheadline).foregroundStyle(AppColors.gris)
                }
            }
        }
    }

    private var seccionTamano: some View {
        VStack(alignment: .leading, spacing: 12) {
            EncabezadoSeccion("Elige el tamaño")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(producto.variantes) { v in
                    let activo = v.id == varianteId
                    Button {
                        varianteId = v.id
                        seleccionados.removeAll()   // los agregados dependen del tamaño
                    } label: {
                        VStack(spacing: 4) {
                            Text(v.tamano.capitalizadoLimpio)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColors.texto)
                            Text(v.disponible ? v.precio.soles : "Agotado")
                                .font(.footnote.weight(v.disponible ? .bold : .regular))
                                .foregroundStyle(v.disponible && activo ? AppColors.primary : AppColors.gris)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(activo ? AppColors.kraftClaro : AppColors.surface,
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(activo ? AppColors.primary : AppColors.hairline,
                                          lineWidth: activo ? 1.5 : 1))
                    }
                    .buttonStyle(.presion)
                    .disabled(!v.disponible)
                    .opacity(v.disponible ? 1 : 0.45)
                    .accessibilityAddTraits(activo ? .isSelected : [])
                }
            }
            .sensoryFeedback(.selection, trigger: varianteId)
        }
    }

    private var seccionAgregados: some View {
        VStack(alignment: .leading, spacing: 12) {
            EncabezadoSeccion("Agregados")
            VStack(spacing: 0) {
                ForEach(Array(compatibles.enumerated()), id: \.element.id) { i, ag in
                    let marcado = seleccionados.contains(ag.id)
                    if i > 0 { Divider().padding(.leading, 16) }
                    Button {
                        if marcado { seleccionados.remove(ag.id) } else { seleccionados.insert(ag.id) }
                    } label: {
                        HStack(spacing: 12) {
                            Text(ag.nombre).foregroundStyle(AppColors.texto)
                            Spacer()
                            if let p = variante.flatMap({ ag.precio(para: $0.tamano) }) {
                                Text("+ \(p.soles)").font(.subheadline).foregroundStyle(AppColors.gris)
                            }
                            Image(systemName: marcado ? "checkmark.circle.fill" : "circle")
                                .imageScale(.large)
                                .foregroundStyle(marcado ? AppColors.primary : AppColors.grisClaro)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(marcado ? .isSelected : [])
                }
            }
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.hairline, lineWidth: 1))
            .sensoryFeedback(.selection, trigger: seleccionados)
        }
    }

    private var seccionNotas: some View {
        VStack(alignment: .leading, spacing: 12) {
            EncabezadoSeccion("Instrucciones especiales")
            CampoFormulario(icono: "text.bubble") {
                TextField("Ej. sin cebolla, cortar en 12...", text: $notas, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.vertical, 12)
            }
        }
    }

    private var barraAgregar: some View {
        HStack(spacing: 12) {
            SelectorCantidad(cantidad: cantidad,
                             maximo: CarritoStore.maxPorItem,
                             onMenos: { if cantidad > 1 { cantidad -= 1 } },
                             onMas: { if cantidad < CarritoStore.maxPorItem { cantidad += 1 } })

            Button { agregarAlCarrito() } label: {
                Text("Agregar · \((precioUnitario * Double(cantidad)).soles)")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(.primario)
            .disabled(variante == nil)
            .sensoryFeedback(.success, trigger: agregado)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.bar)
    }

    private func agregarAlCarrito() {
        guard let v = variante else { return }
        let elegidos = agregados.filter { seleccionados.contains($0.id) }
        let recortado = carrito.agregar(ItemCarrito(producto: producto, variante: v, agregados: elegidos,
                                                    cantidad: cantidad,
                                                    notas: notas.trimmingCharacters(in: .whitespacesAndNewlines)))
        agregado.toggle()
        if recortado {
            // No cerramos: mostramos alerta primero para que el usuario se entere.
            mostrarTopeAlcanzado = true
        } else {
            dismiss()
        }
    }
}
