# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

#Rails.application.config.assets.precompile += [ %w( Three/three.min.js ),%w( Three/OrbitControls.js ),
#%w( Three/GLTFLoader.js ), %w( Three/STLLoader.js ), %w( Three/dat.gui.min.js ),
#%w( Three/dat.gui.min.js )
#]	


# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += [
    %w( video-js.swf vjs.eot vjs.svg vjs.ttf vjs.woff ),
    'dri/dri_grid.css','dri/dri_layouts.css', 'dri/dri_print.css', 'blacklight_maps.css',
    'blacklight_oai_provider/oai_dri.xsl',
    %w( jquery-xmleditor/vendor/cycle.js iiif_viewer.js three_js_viewer.js dri/modals.js analytics.js)
]

