$(document).ready(function () {
    var carouselFragments = [];
    var displaySize = [];

    const progressModal = document.getElementById('progress-modal');
    const progressBar = document.getElementById('progress-bar');

    function displayProgressBar(percentage) {
        progressBar.value = percentage;
        progressModal.style.display = 'block';
    };

    function hideProgressBar() {
        progressModal.style.display = 'none';
    };

    $('.dri_threejs_view:not([data-processed="true"])').each(function() {

        var element = $(this);
        element.attr('data-processed', 'true');
        var url = element.data('url');
        var file = element.data('file');
        var id = String(element.attr('id'));
        var extension = file.split('.').pop().toLowerCase();

        // create container
        var container = document.createElement( 'div' );
        container.id = 'carousel-fragment-' + carouselFragments.length;

        // append container to parent
        var parentDiv = document.getElementById(String(element.attr('id')));
        parentDiv.appendChild( container );

        // setup a scene 
        var scene = new THREE.Scene();
        var camera = new THREE.PerspectiveCamera(
            50, 
            window.innerWidth / window.innerHeight, 
            0.1, 
            5000
        );
        
        // Set Generic material
        const absMaterial = new THREE.MeshPhongMaterial({
            color: 0x1111111,
            wireframe: false,
            flatShading: false,
            transparent: false,
            color: 0x5b5b5b
        });

        // Set Normal material
        const normalMaterial = new THREE.MeshNormalMaterial({
            wireframe: false,
            flatShading: false,
            transparent: false
        });

        if (displaySize.length == 0){
            getDisplaySize();
        };

        var isCustomMaterial = false;
        let originalMaterial = [];
        let cPosition = null;
        let cTarget = null;
        let hasLight = false;
        let hasMaterial = false;
        let lightColor = 0xffffff;
        let lightIntensity = 1;
        var directionalLight1, directionalLight2, ambientLight;

        switch(extension) {
            case 'stl':
                const stlLoader = new THREE.STLLoader();
                stlLoader.load(
                    url, 
                    function ( geometry ) {
                        const mesh = new THREE.Mesh( geometry, normalMaterial);
                        processObject(mesh);
                        scene.add(mesh);
                        setCamera(mesh);
                        guiInitializer(mesh);
                    },
                    (xhr) => {
                        if(((xhr.loaded / xhr.total) * 100) == 100){
                            hideProgressBar();
                        } else {
                            displayProgressBar((xhr.loaded / xhr.total) * 100);
                        }
                    },
                    (error) => {
                        hideProgressBar();
                        displayMsg('assetNotLoading');
                        console.log(error);
                    });
                break;
        
            case 'ply':
                const plyLoader = new THREE.PLYLoader();
                plyLoader.load( 
                    url, 
                    function ( ply ) {
                        ply.computeVertexNormals();
                        const mesh = new THREE.Mesh(ply, normalMaterial);
                        processObject(mesh);
                        scene.add(mesh);
                        setCamera(mesh);
                        guiInitializer(mesh);
                    },
                    (xhr) => {
                        if(((xhr.loaded / xhr.total) * 100) == 100){
                            hideProgressBar();
                        } else {
                            displayProgressBar((xhr.loaded / xhr.total) * 100);
                        }
                    },
                    (error) => {
                        hideProgressBar();
                        displayMsg('assetNotLoading');
                        console.log(error);
                    });
                break;
        
            case 'glb':
            case 'gltf':
                const dracoLoader = new THREE.DRACOLoader();
                dracoLoader.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.4.1/');
                dracoLoader.setDecoderConfig({ type: 'js' });
                const gltfLoader = new THREE.GLTFLoader();
                gltfLoader.setDRACOLoader( dracoLoader );
                gltfLoader.load( 
                    url, 
                    function (gltf) {
                        processObject(gltf.scene);
                        scene.add(gltf.scene);
                        setCamera(gltf.scene);
                        guiInitializer(gltf.scene);
                    },
                    (xhr) => {
                        if(((xhr.loaded / xhr.total) * 100) == 100){
                            hideProgressBar();
                        } else {
                            displayProgressBar((xhr.loaded / xhr.total) * 100);
                        }
                    },
                    (error) => {
                        hideProgressBar();
                        displayMsg('assetNotLoading');
                        console.log(error);
                    });
                break;
            
            case 'fbx':
                const fbxLoader = new THREE.FBXLoader();
                fbxLoader.load( 
                    url, 
                    function ( fbx ) {
                        processObject(fbx);
                        scene.add(fbx);
                        setCamera(fbx);
                        guiInitializer(fbx);
                    },
                    (xhr) => {
                        if(((xhr.loaded / xhr.total) * 100) == 100){
                            hideProgressBar();
                        } else {
                            displayProgressBar((xhr.loaded / xhr.total) * 100);
                        }
                    },
                    (error) => {
                        hideProgressBar();
                        displayMsg('assetNotLoading');
                        console.log(error);
                    });
                break;
        
            case 'obj':
                const objLoader = new THREE.OBJLoader( );
                objLoader.load( 
                    url, 
                    function (obj) {
                        processObject(obj);
                        scene.add(obj);
                        setCamera(obj);
                        guiInitializer(obj);
                },
                (xhr) => {
                    if(((xhr.loaded / xhr.total) * 100) == 100){
                        hideProgressBar();
                    } else {
                        displayProgressBar((xhr.loaded / xhr.total) * 100);
                    }
                },
                (error) => {
                    hideProgressBar();
                    displayMsg('assetNotLoading');
                    console.log(error);
                } );
                break;
        
            case 'dae':
                const colladaL = new THREE.ColladaLoader();
                colladaL.load( url, function(dae){
                    processObject(dae.scene);
                    scene.add(dae.scene);
                    setCamera(dae.scene);
                    guiInitializer(dae.scene);
                },
                (xhr) => {
                    if(((xhr.loaded / xhr.total) * 100) == 100){
                        hideProgressBar();
                    } else {
                        displayProgressBar((xhr.loaded / xhr.total) * 100);
                    }
                },
                (error) => {
                    hideProgressBar();
                    displayMsg('assetNotLoading');
                    console.log(error);
                } );
                break;
        
            default:
                displayMsg('assetNotLoading');
        }

        if (hasLight === true){
            addLight(lightColor, 0);
        } else {
            addLight(lightColor, lightIntensity);
        }

        if (scene.background === null || scene.background === undefined ) {
            var backgroundColour = new THREE.Color(0xd8d8d8);
            scene.background = new THREE.Color( backgroundColour );
        }

        function addLight(color, intensity){
            if (!hasLight){
                directionalLight1 = new THREE.DirectionalLight(color, intensity);
                directionalLight1.position.set(0, 1, 0);

                scene.add(directionalLight1);
                directionalLight2 = new THREE.DirectionalLight(color, intensity);
                directionalLight2.position.set(0, -1, 0);

                scene.add(directionalLight2);
                ambientLight = new THREE.AmbientLight(color, intensity);
                scene.add(ambientLight);
                hasLight = true;

            } else {
                directionalLight1.color.set(color);
                directionalLight2.color.set(color);
                ambientLight.color.set(color);
                directionalLight1.intensity = intensity;
                directionalLight2.intensity = intensity;
                ambientLight.intensity = (color, intensity);
            }
        };

        function processObject(object) {
            try {
                object.traverse(function (child) {
                    if (child.isMesh) {
                        if (isCustomMaterial) {
                            child.material = absMaterial;
                        } else {
                            originalMaterial.push(child.material);
                            child.material = normalMaterial;
                        }
                        child.position.set(0, 0, 0);
                        child.material.needsUpdate = true;
                    }
                    if (child.isCamera) {
                        cTarget = child.getWorldPosition(new THREE.Vector3());
                        cPosition = child.position.clone();
                    }
                    if (child.isLight) {
                        hasLight = true;
                    }
                    if (child.material !== undefined && child.material !== null) {
                        hasMaterial = true;
                    }
                });
        
                // If the object is an FBX model, convert its coordinate system from Z-up to Y-up
                if (object.isFBX === true) {
                    object.rotation.x = -Math.PI / 2;
                }

            } catch (error) {
                console.error('An error occurred while processing the object:', error);
            }
        }

        function displayMsg(messageType) {
            switch(messageType){
                case 'emptyHead':
                    parentDiv.innerHTML = `
                        <h2 class="dri_restrict_title">Surrogate not available</h2>
                        <p class="dri_restrict_message">The asset is currently unavailable for display. Please reload the page. If the problem persists, please contact DRI support. </p>
                    `;
                case 'assetNotLoading':
                    parentDiv.innerHTML = `
                        <h2 class="dri_restrict_title">Surrogate not available</h2>
                        <p class="dri_restrict_message">Asset is not supported for display. Please download the asset using the link below if available. </p>
                    `;
            }
            parentDiv.style.display = 'block';
        };

        function setCamera(object) {
            const boundingBox = new THREE.Box3().setFromObject(object);
            const boxSize = new THREE.Vector3();
            boundingBox.getSize(boxSize);
        
            // Calculate the distance from the object based on its size
            const distance = Math.max(boxSize.x, boxSize.y, boxSize.z) * 2;
        
            // Position the camera at a fixed distance from the object
            camera.position.set(0, 0, distance);
        
            // Set the camera target (center of the object)
            cameraTarget = boundingBox.getCenter(new THREE.Vector3());
        
            // Update the camera's near and far clipping planes
            const near = distance / 100;
            const far = distance * 100;
            camera.near = near;
            camera.far = far;
            camera.updateProjectionMatrix();
        };


        function guiInitializer(object){
            var gui = new dat.GUI({autoPlace: false});
            gui.domElement.id = "gui";
            parentDiv.appendChild(gui.domElement);

            var notSkinFormats = ["stl","ply"];

            const options = { 
                wireframe: false,
                object: 0x1111111,
                background: 0xd8d8d8,
                lights: true,
                zoom: 1.0, 
                light: 2
            };

            function toggleFullScreen() {
                if (!document.fullscreenElement) {
                    // Enter full-screen mode
                    if (parentDiv.requestFullscreen) {
                        parentDiv.requestFullscreen();
                    } else if (parentDiv.mozRequestFullScreen) { // Firefox
                        parentDiv.mozRequestFullScreen();
                    } else if (parentDiv.webkitRequestFullscreen) { // Chrome, Safari, and Opera
                        parentDiv.webkitRequestFullscreen();
                    } else if (parentDiv.msRequestFullscreen) { // IE/Edge
                        parentDiv.msRequestFullscreen();
                    }
                } else {
                    // Exit full-screen mode
                    if (document.exitFullscreen) {
                        document.exitFullscreen();
                    } else if (document.mozCancelFullScreen) { // Firefox
                        document.mozCancelFullScreen();
                    } else if (document.webkitExitFullscreen) { // Chrome, Safari, and Opera
                        document.webkitExitFullscreen();
                    } else if (document.msExitFullscreen) { // IE/Edge
                        document.msExitFullscreen();
                    }
                }
            }

            document.addEventListener('fullscreenchange', onFullscreenChange);
            document.addEventListener('webkitfullscreenchange', onFullscreenChange);
            document.addEventListener('mozfullscreenchange', onFullscreenChange);
            document.addEventListener('MSFullscreenChange', onFullscreenChange);
            
            const config = {
                fullScreen: function() {
                toggleFullScreen();
                }
            };

            const guiParams = {
                applyNormalMaterial: function() {
                    for (let i = 0; i < originalMaterial.length; i++) {
                        object.traverse(function(child) {
                            if (child.isMesh) {
                                child.material = normalMaterial;
                            }
                        });
                    }
                },
                resetMaterial: function() {
                    for (let i = 0; i < originalMaterial.length; i++) {
                        object.traverse(function(child) {
                            if (child.isMesh) {
                                child.material = originalMaterial[i];
                            }
                        });
                    }
                }
            };

            function closeColorFolder() {
                if (colorFolder.open) {
                colorFolder.close();
                }
            };

            function closeCameraFolder() {
                if (cameraFolder.open) {
                cameraFolder.close();
                }
            };

            gui.add(config, 'fullScreen').name('Full Screen Mode');

            // Set Camera Folder Settings
            const cameraFolder = gui.addFolder('Rotation & Zoom');
            cameraFolder.add(object.rotation, 'x', 0, Math.PI * 2);
            cameraFolder.add(object.rotation, 'y', 0, Math.PI * 2);
            cameraFolder.add(object.rotation, 'z', 0, Math.PI * 2);
            cameraFolder.add(options, 'zoom', 0.1, 2.0, 0.1).name('Zoom').onChange(() => { object.scale.set(options.zoom, options.zoom, options.zoom) });
            cameraFolder.__ul.addEventListener('click', function () {
                if (cameraFolder.open) {
                closeColorFolder();
                }
            });

            // Set Color Folder Settings
            const colorFolder = gui.addFolder('Light, Material & Color');
            colorFolder.add(options, 'light', 0, 20).onChange( value => {
                addLight(lightColor, options.light);
            } );
            colorFolder.addColor(options, 'background').onChange( col => { 
                scene.background = new THREE.Color(col); 
            });
            colorFolder.addColor(options, 'object').onChange(col => {
                absMaterial.color = new THREE.Color(col);
                isCustomMaterial = true; 
                processObject(object);
            });
            colorFolder.add(guiParams, "applyNormalMaterial").name("Normal Material");
            if(notSkinFormats.indexOf(extension) === -1){
                colorFolder.add(guiParams, "resetMaterial").name("Original Material");
            }
            colorFolder.__ul.addEventListener('click', function () {
                if (colorFolder.open) {
                closeCameraFolder();
                }
            });
            
            gui.close();
        }

        carouselFragments.push({
            scene: scene,
            camera: camera,
            container: container,
            parentDiv: parentDiv,
            id: id,
        });

        animate(carouselFragments.length - 1);
    });

    function animate(fragmentIndex) {
        // Get the scene, camera, and container for the specified carousel fragment
        var fragment = carouselFragments[fragmentIndex];
        var scene = fragment.scene;
        var camera = fragment.camera;
        var container = fragment.container;
      
        // Create a new WebGLRenderer instance for this carousel fragment
        var renderer = new THREE.WebGLRenderer({ antialias: false });
        renderer.shadowMap.enabled = false;

        renderer.setSize(displaySize[0].width, displaySize[0].height);
        container.appendChild(renderer.domElement);
      
        // Recursive function to update scene continuously
        function render() {
          requestAnimationFrame(render);
          renderer.render(scene, camera);
        }

        carouselFragments[fragmentIndex].renderer = renderer;

         // Add controls
         const controls = new THREE.OrbitControls(camera, renderer.domElement);
         controls.target.set(0, 0, 0);

        render();

        window.addEventListener('resize', onWindowResize, false);
        
    };

    function getDisplaySize() {
        var divSize = document.getElementsByClassName('item dri_asset_carousel_item dri_bottom_stack active')[0];

        if (divSize) {
            var containerRect = divSize.getBoundingClientRect();
            var containerWidth = containerRect.width;
            var containerHeight = containerRect.height;
    
            if (displaySize.length === 0) {
                displaySize.push({
                    width: containerWidth,
                    height: containerHeight,
                });
            } else {
                displaySize[0].width = containerWidth;
                displaySize[0].height = containerHeight;
            }
        }
    };

    function onFullscreenChange() {
        if (document.fullscreenElement) {
            displaySize[0].width = window.innerWidth;
            displaySize[0].height = window.innerHeight;
        } else {
            getDisplaySize();
        }
    
        // Update rendering for all carousel fragments
        carouselFragments.forEach((fragment) => {
            const width = displaySize[0].width;
            const height = displaySize[0].height;
            fragment.renderer.setSize(width, height);
            fragment.camera.aspect = width / height;
            fragment.camera.updateProjectionMatrix();
        });
    };
    
    function onWindowResize() {
        if (!document.fullscreenElement) {
            getDisplaySize();
        }
    
        // Update rendering for all carousel fragments
        carouselFragments.forEach((fragment) => {
            const width = displaySize[0].width;
            const height = displaySize[0].height;
    
            fragment.renderer.setSize(width, height);
            fragment.camera.aspect = width / height;
            fragment.camera.updateProjectionMatrix();
        });
    };

    onWindowResize();
    
});