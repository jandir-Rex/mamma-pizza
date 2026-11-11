import SwiftUI

struct HomeView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(MenuStore.self) private var menu
    @Environment(AppNavegacion.self) private var nav
    @State private var seleccionado: Producto?

    private let categorias: [(nombre: String, simbolo: String)] = [
        ("Pizzas", "fork.knife"), ("Entradas", "takeoutbag.and.cup.and.straw"),
        ("Bebidas", "cup.and.saucer.fill"), ("Postres", "birthday.cake.fill")
    ]

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
            .background(AppColors.bg)
            .navigationTitle("MammaPizza")
            .conCarritoFlotante()
        }
        .task { if !menu.cargado { await menu.cargar() } }
        .sheet(item: $seleccionado) { p in
            ProductoDetalleSheet(producto: p, agregados: menu.agregados)
        }
    }

    private var contenido: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(saludo),").font(.subheadline).foregroundStyle(AppColors.gris)
                    Text(nombre.isEmpty ? "👋" : "\(nombre) 👋")
                        .font(.largeTitle.weight(.heavy))
                    Text("¿Qué antojo tienes hoy?").font(.subheadline).foregroundStyle(AppColors.gris)
                }

                Button { nav.irAMenu() } label: {
                    Label("Buscar pizzas, bebidas, etc...", systemImage: "magnifyingglass")
                        .foregroundStyle(AppColors.gris)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14).frame(height: 46)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                banner

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Categorías").font(.title3.weight(.bold))
                        Spacer()
                        Button("Ver todas") { nav.irAMenu() }.font(.subheadline.weight(.semibold))
                    }
                    HStack {
                        ForEach(categorias, id: \.nombre) { c in
                            Button { nav.irAMenu(c.nombre) } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: c.simbolo)
                                        .font(.title2)
                                        .foregroundStyle(AppColors.primary)
                                        .frame(width: 64, height: 64)
                                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    Text(c.nombre).font(.caption.weight(.medium))
                                        .foregroundStyle(AppColors.texto)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recomendados para ti").font(.title3.weight(.bold))
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

    private var banner: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: [Color(hex: 0xB71C1C), Color(hex: 0x7F1214)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 8) {
                Text("La verdadera").font(.subheadline)
                Text("pizza, siempre").font(.title2.weight(.heavy))
                Text("es una buena idea").font(.subheadline)
                Rectangle().fill(AppColors.gold).frame(width: 64, height: 2)
                Button { nav.irAMenu() } label: {
                    Label("Ver menú", systemImage: "arrow.right")
                        .labelStyle(.titleAndIcon)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color(hex: 0xC41E24))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.white, in: Capsule())
                }
            }
            .foregroundStyle(.white)
            .padding(18)
        }
        .frame(height: 172)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
