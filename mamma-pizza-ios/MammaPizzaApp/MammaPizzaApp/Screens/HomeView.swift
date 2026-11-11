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
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(saludo).font(.subheadline).foregroundStyle(AppColors.gris)
                    Text(nombre.isEmpty ? "👋" : "\(nombre) 👋")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                }

                Button { nav.irAMenu() } label: {
                    Label("Buscar pizzas, bebidas, etc...", systemImage: "magnifyingglass")
                        .foregroundStyle(AppColors.gris)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14).frame(height: 48)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppColors.hairline, lineWidth: 1))
                }
                .buttonStyle(.presion)

                banner

                VStack(alignment: .leading, spacing: 14) {
                    EncabezadoSeccion("Categorías", boton: "Ver todas") { nav.irAMenu() }
                    HStack(spacing: 12) {
                        ForEach(categorias, id: \.nombre) { c in
                            Button { nav.irAMenu(c.nombre) } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: c.simbolo)
                                        .font(.title2)
                                        .foregroundStyle(AppColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 64)
                                        .background(AppColors.kraftClaro,
                                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    Text(c.nombre)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(AppColors.texto)
                                }
                            }
                            .buttonStyle(.presion)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    EncabezadoSeccion("Recomendados para ti")
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
        VStack(alignment: .leading, spacing: 6) {
            Text("HECHA AL HORNO")
                .font(.caption.weight(.bold)).tracking(1.5)
                .foregroundStyle(AppColors.mostaza)
            Text("La verdadera pizza\nes una buena idea")
                .font(.marca(.title2))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Button { nav.irAMenu() } label: {
                Label("Ver menú", systemImage: "arrow.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppColors.cacao)
                    .padding(.horizontal, 16).frame(minHeight: 36)
                    .background(AppColors.kraft, in: Capsule())
            }
            .buttonStyle(.presion)
            .padding(.top, 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                AppColors.marcaDegradado
                Circle().fill(AppColors.kraft.opacity(0.10)).frame(width: 220).offset(x: 70, y: -80)
                Circle().fill(AppColors.tomate.opacity(0.22)).frame(width: 110).offset(x: 30, y: 90)
            }
        }
        .overlay(alignment: .trailing) {
            Image(systemName: "flame.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.mostaza)
                .rotationEffect(.degrees(-10))
                .padding(.trailing, 24)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
