import { Application } from "@hotwired/stimulus"
import LeafletController from "./maps/leaflet_controller"

Application.start().register("blacklight-maps-leaflet", LeafletController)
