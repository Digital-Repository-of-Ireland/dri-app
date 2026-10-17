import "./globals/jquery"            // must be first

import "jquery-ui/dist/jquery-ui"   // full UI build: mouse, draggable, resizable, autocomplete, menu, sortable
import "datatables.net"             // plain DT, matching jquery.dataTables
import "jquery-validation"
import "jquery-validation/dist/additional-methods"

import Clipboard from "clipboard"
window.Clipboard = window.ClipboardJS = Clipboard   // clipboard-rails 1.7.1 used the name "Clipboard"

import Cookies from "js-cookie"
window.Cookies = Cookies

import bootstrap from "bootstrap/dist/js/bootstrap.bundle.js"
window.bootstrap = bootstrap

import { Spinner } from "spin.js"
import "spin.js/spin.css"
window.Spinner = Spinner
