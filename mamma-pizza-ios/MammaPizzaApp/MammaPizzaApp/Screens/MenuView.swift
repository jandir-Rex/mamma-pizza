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
            .fondoApp()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MammaPizza").font(.marca(.headline)).foregroundStyle(AppColors.primary)
                }
            }
            .searchable(text: $consulta, prompt: "Buscar pizzas, bebidas, etc...")
            .conCarritoFlotante()
        }
        .task { if !menu.cargado { await menu.cargar() } }
        .sheet(item: $seleccionado) { p in
            ProductoDetalleSheet(producto: p, agregados: menu.agregados)
        }
    }

    // MARK: - Lista

    private var lista: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                if consulta.isEmpty { encabezado }

                if secciones.isEmpty { vacio }

                ForEach(secciones, id: \.nombre) { seccion in
                    VStack(alignment: .leading, spacing: 14) {
                        cabeceraSeccion(seccion.nombre, cantidad: seccion.productos.count)
                        ForEach(seccion.productos) { p in
                            let agotado = p.agotado
                            TarjetaProducto(producto: p, agotado: agotado) {
                                if !agotado { seleccionado = p }
                            }
                            .scrollTransition(.animated(.snappy)) { vista, fase in
                                vista
                                    .opacity(fase.isIdentity ? 1 : 0.5)
                                    .scaleEffect(fase.isIdentity ? 1 : 0.97)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) { chips }
        .refreshable { await menu.cargar() }
    }

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NUESTRA CARTA")
                .font(.caption.weight(.bold)).tracking(2)
                .foregroundStyle(AppColors.primary)
            Text("¿Qué se te antoja hoy?")
                .font(.marca(.title))
                .foregroundStyle(AppColors.texto)
            Text("Elige, personaliza y te lo llevamos calientito.")
                .font(.subheadline)
                .foregroundStyle(AppColors.gris)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cabeceraSeccion(_ nombre: String, cantidad: Int) -> some View {
        HStack(spacing: 10) {
            Text(nombre)
                .font(.marca(.title2))
                .foregroundStyle(AppColors.texto)
                .accessibilityAddTraits(.isHeader)
            Text("\(cantidad)")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColors.cacaoTexto)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(AppColors.kraftClaro, in: Capsule())
            Rectangle().fill(AppColors.hairline).frame(height: 1)
        }
    }

    private var vacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 30))
                .foregroundStyle(AppColors.primary)
                .frame(width: 72, height: 72)
                .background(AppColors.kraftClaro, in: Circle())
            Text("Aún no hay productos aquí")
                .font(.marca(.title3))
            Text(consulta.isEmpty ? "Prueba con otra categoría" : "No encontramos \"\(consulta)\"")
                .font(.subheadline)
                .foregroundStyle(AppColors.gris)
            if seleccion != "Todas" {
                Button("Ver todo el menú") { withAnimation(.snappy) { nav.categoriaMenu = "Todas" } }
                    .buttonStyle(.secundario)
                    .frame(maxWidth: 220)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .multilineTextAlignment(.center)
    }

    // MARK: - Chips

    private func simbolo(_ cat: String) -> String {
        cat == "Todas" ? "square.grid.2x2.fill" : iconoCategoria(cat)
    }

    private var chips: some View {
        @Bindable var nav = nav
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categorias, id: \.self) { cat in
                    let activo = cat == seleccion
                    Button { withAnimation(.snappy) { nav.categoriaMenu = cat } } label: {
                        Label(cat, systemImage: simbolo(cat))
                            .font(.subheadline.weight(activo ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .frame(minHeight: 40)
                            .foregroundStyle(activo ? Color.white : AppColors.texto)
                            .background(activo ? AppColors.primary : AppColors.surface, in: Capsule())
                            .overlay(Capsule().strokeBorder(activo ? Color.clear : AppColors.hairline, lineWidth: 1))
                            .shadow(color: activo ? AppColors.primary.opacity(0.3) : .clear, radius: 8, y: 3)
                    }
                    .buttonStyle(.presion)
                    .accessibilityAddTraits(activo ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 8)
        }
        .background(.bar)
        .sensoryFeedback(.selection, trigger: nav.categoriaMenu)
    }
}
