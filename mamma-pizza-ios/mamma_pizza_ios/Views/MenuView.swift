import SwiftUI

struct MenuView: View {
    @State private var productos: [Producto] = []
    @State private var agregados: [Agregado] = []
    @State private var productoSeleccionado: Producto?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    var productosFiltrados: [Producto] {
        if searchText.isEmpty {
            return productos
        } else {
            return productos.filter { $0.nombre.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bg.ignoresSafeArea()
                
                Group {
                    if isLoading && productos.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(AppColors.primary)
                            Text("Preparando el menú...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else if let errorMessage = errorMessage, productos.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.primary)
                            Text(errorMessage)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            Button("Reintentar") {
                                Task { await cargarMenu() }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.primary)
                        }
                        .padding(28)
                    } else if productosFiltrados.isEmpty {
                        ContentUnavailableView(
                            "Sin resultados",
                            systemImage: "magnifyingglass",
                            description: Text("No se encontraron productos disponibles.")
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                                spacing: 16
                            ) {
                                ForEach(productosFiltrados) { producto in
                                    ProductCard(producto: producto) {
                                        productoSeleccionado = producto
                                    }
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await cargarMenu()
                        }
                    }
                }
            }
            .navigationTitle("Mamma Pizza")
            .searchable(text: $searchText, prompt: "Buscar pizzas, bebidas...")
            .sheet(item: $productoSeleccionado) { producto in
                ProductDetailSheet(producto: producto, agregados: agregados)
            }
            .task {
                await cargarMenu()
            }
        }
    }
    
    private func cargarMenu() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            async let fetchedProductos: [Producto] = NetworkService.shared.fetch(endpoint: "/productos/menu")
            async let fetchedAgregados: [Agregado] = NetworkService.shared.fetch(endpoint: "/agregados")
            
            self.productos = try await fetchedProductos
            self.agregados = try await fetchedAgregados
        } catch {
            print("❌ Error al cargar menú: \(error)")
            self.errorMessage = "No se pudo cargar el menú. Comprueba tu conexión."
        }
    }
}
