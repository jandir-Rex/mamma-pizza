import SwiftUI

struct MenuView: View {
    @Environment(MenuStore.self) private var menu
    @Environment(AppNavegacion.self) private var nav
    @State private var consulta = ""
    @State private var seleccionado: Producto?

    private var categorias: [String] {
        var vistos = Set<String>()
        let unicas = menu.productos.map(\.categoriaNombre).filter { vistos.insert($0).inserted }
        return ["Todas"] + unicas
    }

    private func coincide(_ a: String, _ b: String) -> Bool {
        let x = a.lowercased().trimmingCharacters(in: .whitespaces)
        let y = b.lowercased().trimmingCharacters(in: .whitespaces)
        if x.isEmpty || y.isEmpty { return false }
        return x == y || x.hasPrefix(y) || y.hasPrefix(x)
    }

    /// Resuelve "Pizzas" (del Home) contra "Pizzas al horno" (del backend).
    private var seleccion: String {
        let sel = nav.categoriaMenu
        if sel == "Todas" { return sel }
        return categorias.first { coincide($0, sel) } ?? sel
    }

    private var secciones: [(nombre: String, productos: [Producto])] {
        let q = consulta.trimmingCharacters(in: .whitespaces).lowercased()
        let filtrados = menu.productos.filter { p in
            (seleccion == "Todas" || coincide(p.categoriaNombre, seleccion))
                && (q.isEmpty || p.nombre.lowercased().contains(q))
        }
        return categorias.dropFirst().compactMap { cat in
            let items = filtrados.filter { $0.categoriaNombre == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if menu.cargando && menu.productos.isEmpty {
                    PizzaLoadingView(mensaje: "Cargando menú...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = menu.error {
                    ContentUnavailableView {
                        Label(error, systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button("Reintentar") { Task { await menu.cargar() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    lista
                }
            }
            .background(AppColors.bg)
            .navigationTitle("Menú")
            .searchable(text: $consulta, prompt: "Buscar pizzas, bebidas, etc...")
            .conCarritoFlotante()
        }
        .task { if !menu.cargado { await menu.cargar() } }
        .sheet(item: $seleccionado) { p in
            ProductoDetalleSheet(producto: p, agregados: menu.agregados)
        }
    }

    private var lista: some View {
        List {
            if secciones.isEmpty {
                ContentUnavailableView("Aún no hay productos aquí", systemImage: "fork.knife")
                    .listRowBackground(Color.clear)
            }
            ForEach(secciones, id: \.nombre) { seccion in
                Section(seccion.nombre) {
                    ForEach(seccion.productos) { p in
                        let agotado = p.agotado
                        TarjetaProducto(producto: p, agotado: agotado) {
                            if !agotado { seleccionado = p }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, 70, for: .scrollContent)
        .safeAreaInset(edge: .top, spacing: 0) { chips }
        .refreshable { await menu.cargar() }
    }

    private var chips: some View {
        @Bindable var nav = nav
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categorias, id: \.self) { cat in
                    let activo = cat == seleccion
                    Button { nav.categoriaMenu = cat } label: {
                        Text(cat)
                            .font(.subheadline.weight(activo ? .bold : .medium))
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .foregroundStyle(activo ? Color.white : AppColors.texto)
                            .background(activo ? AppColors.primary : AppColors.surface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(activo ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .background(.bar)
    }
}
