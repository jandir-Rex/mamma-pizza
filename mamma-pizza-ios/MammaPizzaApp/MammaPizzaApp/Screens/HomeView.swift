import SwiftUI

struct HomeView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(MenuStore.self) private var menu
    @Environment(AppNavegacion.self) private var nav
    @State private var seleccionado: Producto?

    /// Categorías derivadas del menú del backend. Se recalculan cuando llegan los productos.
    /// El orden respeta el orden en que aparecen en el menú.
    private var categorias: [(nombre: String, simbolo: String)] {
        var vistos = Set<String>()
        let unicas = menu.productos
            .map(\.categoriaNombre)
            .filter { !$0.isEmpty && vistos.insert($0).inserted }
        return unicas.map { (nombre: $0, simbolo: iconoCategoria($0)) }
    }

    private var nombre: String {
        auth.usuario?.nombre.split(separator: " ").first.map(String.init) ?? ""
    }

    private var saludo: String {
        switch Calendar.current.component(.hour, from: .now) {
        case ..<12: "Buenos días"
        case ..<19: "Buenas tardes"
        default: "Buenas noches"
        }
    }

    private var recomendados: [Producto] {
        Array(menu.productos.filter { $0.variantes.contains(where: \.disponible) }.prefix(3))
    }

    var body: some View {
        NavigationStack {
            Group {
                if menu.cargando && menu.productos.isEmpty {
                    PizzaLoadingView(mensaje: "Cargando…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contenido
                }
            }
            .fondoApp()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MammaPizza").font(.marca(.headline)).foregroundStyle(AppColors.primary)
                }
            }
            .conCarritoFlotante()
        }
        .task { if !menu.cargado { await menu.cargar() } }
        .sheet(item: $seleccionado) { p in
            ProductoDetalleSheet(producto: p, agregados: menu.agregados)
        }
    }

    private var contenido: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !nombre.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(saludo.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(AppColors.primary)
                        Text(nombre)
                            .font(.marca(.title))
                            .foregroundStyle(AppColors.texto)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button { nav.irAMenu() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppColors.cacao)
                        Text("Buscar pizzas, bebidas, etc...")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(AppColors.gris)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppColors.hairline, lineWidth: 1))
                }
                .buttonStyle(.presion)

                banner

                if !categorias.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        EncabezadoSeccion("Categorías", boton: "Ver todas") { nav.irAMenu() }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(categorias, id: \.nombre) { c in
                                    Button { nav.irAMenu(c.nombre) } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: c.simbolo)
                                                .font(.title2)
                                                .foregroundStyle(AppColors.primary)
                                                .frame(width: 64, height: 64)
                                                .background(AppColors.kraftClaro,
                                                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                            Text(c.nombre)
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(AppColors.texto)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 76)
                                    }
                                    .buttonStyle(.presion)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, -20)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    EncabezadoSeccion(nombre.isEmpty ? "Nuestras favoritas" : "Recomendados para ti")
                    if recomendados.isEmpty {
                        Text("Pronto tendremos recomendaciones para ti")
                            .foregroundStyle(AppColors.gris)
                            .frame(maxWidth: .infinity).padding(.vertical, 24)
                    } else {
                        ForEach(recomendados) { p in
                            TarjetaProducto(producto: p) { seleccionado = p }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .contentMargins(.bottom, 70, for: .scrollContent)
        .refreshable { await menu.cargar() }
    }

    private var banner: some View { AdCarousel(onVerMenu: { nav.irAMenu() }) }
}
