import { Controller } from "@hotwired/stimulus"
import { Map, Marker, Popup, NavigationControl, LngLatBounds } from "maplibre-gl"

// Mapa visual (seção 17 do parecer técnico): MapLibre GL JS + tiles gratuitos do
// OpenFreeMap, em vez de Google Maps/Mapbox — mesmo custo-benefício documentado
// no parecer técnico (US$0/mês, sem licenciamento de mapa).
const MG_CENTER = [-44.38, -18.10]
const MG_DEFAULT_ZOOM = 6

export default class extends Controller {
  static values = { facilities: Array }

  connect() {
    this.map = new Map({
      container: this.element,
      style: "https://tiles.openfreemap.org/styles/liberty",
      center: MG_CENTER,
      zoom: MG_DEFAULT_ZOOM,
      attributionControl: true
    })
    this.map.addControl(new NavigationControl(), "top-right")

    this.map.on("load", () => {
      this.plotFacilities()
      this.tryGeolocate()
    })
  }

  disconnect() {
    this.map?.remove()
  }

  // Uma camada GeoJSON com agrupamento (desenhada no canvas) em vez de um Marker
  // (elemento HTML) por equipamento: com centenas de pontos — 215 só em BH desde
  // que as UBS entraram — os marcadores HTML travavam o mapa no celular. Pontos
  // próximos viram um círculo com o total, que se abre ao clicar/dar zoom.
  plotFacilities() {
    const located = this.facilitiesValue.filter((f) => f.lat != null && f.lng != null)
    if (located.length === 0) return

    this.map.addSource("facilities", {
      type: "geojson",
      cluster: true,
      clusterRadius: 40,
      clusterMaxZoom: 14,
      data: {
        type: "FeatureCollection",
        features: located.map((f) => ({
          type: "Feature",
          geometry: { type: "Point", coordinates: [f.lng, f.lat] },
          properties: { name: f.name, url: f.url }
        }))
      }
    })

    this.map.addLayer({
      id: "facility-clusters",
      type: "circle",
      source: "facilities",
      filter: ["has", "point_count"],
      paint: {
        "circle-color": "#6F2233",
        "circle-opacity": 0.85,
        "circle-stroke-color": "#FFFFFF",
        "circle-stroke-width": 2,
        "circle-radius": ["step", ["get", "point_count"], 16, 10, 20, 50, 26, 200, 32]
      }
    })
    this.map.addLayer({
      id: "facility-cluster-count",
      type: "symbol",
      source: "facilities",
      filter: ["has", "point_count"],
      layout: { "text-field": ["get", "point_count_abbreviated"], "text-font": ["Noto Sans Bold"], "text-size": 13 },
      paint: { "text-color": "#FFFFFF" }
    })
    this.map.addLayer({
      id: "facility-points",
      type: "circle",
      source: "facilities",
      filter: ["!", ["has", "point_count"]],
      paint: {
        "circle-color": "#6F2233",
        "circle-radius": 8,
        "circle-stroke-color": "#FFFFFF",
        "circle-stroke-width": 2
      }
    })

    this.map.on("click", "facility-clusters", async (event) => {
      const feature = event.features[0]
      const zoom = await this.map.getSource("facilities").getClusterExpansionZoom(feature.properties.cluster_id)
      this.map.easeTo({ center: feature.geometry.coordinates, zoom })
    })
    this.map.on("click", "facility-points", (event) => {
      const feature = event.features[0]
      new Popup({ offset: 12 })
        .setLngLat(feature.geometry.coordinates)
        .setDOMContent(this.popupContent(feature.properties))
        .addTo(this.map)
    })
    for (const layer of ["facility-clusters", "facility-points"]) {
      this.map.on("mouseenter", layer, () => { this.map.getCanvas().style.cursor = "pointer" })
      this.map.on("mouseleave", layer, () => { this.map.getCanvas().style.cursor = "" })
    }

    if (located.length === 1) {
      this.map.flyTo({ center: [located[0].lng, located[0].lat], zoom: 13 })
    } else {
      const bounds = new LngLatBounds()
      located.forEach((f) => bounds.extend([f.lng, f.lat]))
      this.map.fitBounds(bounds, { padding: 60, maxZoom: 14 })
    }

    this.hasResults = true
  }

  // Montado com textContent (e não HTML) porque o nome vem da base de dados.
  popupContent({ name, url }) {
    const link = document.createElement("a")
    link.href = url
    link.textContent = name
    link.className = "font-semibold text-vinho underline"
    return link
  }

  tryGeolocate() {
    if (this.hasResults || !("geolocation" in navigator)) return

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords
        new Marker({ color: "#CB7979" }).setLngLat([longitude, latitude]).addTo(this.map)
        this.map.flyTo({ center: [longitude, latitude], zoom: 11 })
      },
      () => {},
      { enableHighAccuracy: false, timeout: 6000 }
    )
  }
}
