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

  plotFacilities() {
    const located = this.facilitiesValue.filter((f) => f.lat != null && f.lng != null)
    if (located.length === 0) return

    located.forEach((facility) => {
      new Marker({ color: "#6F2233" })
        .setLngLat([facility.lng, facility.lat])
        .setPopup(new Popup({ offset: 24 }).setText(facility.name))
        .addTo(this.map)
    })

    if (located.length === 1) {
      this.map.flyTo({ center: [located[0].lng, located[0].lat], zoom: 13 })
    } else {
      const bounds = new LngLatBounds()
      located.forEach((f) => bounds.extend([f.lng, f.lat]))
      this.map.fitBounds(bounds, { padding: 60, maxZoom: 14 })
    }

    this.hasResults = true
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
