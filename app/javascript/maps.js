import { Application } from "@hotwired/stimulus"
import LeafletController from "blacklight-maps/controllers/leaflet_controller"

Application.start().register("blacklight-maps-leaflet", LeafletController)
