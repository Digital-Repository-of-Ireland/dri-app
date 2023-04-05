$(document).ready(function () {

	var container = document.createElement( 'div' );
	container.id = "ThreeDContainer";

    var parentDiv = document.getElementById("dri_threejs_view");
	parentDiv.appendChild( container );

	// Setup
	var scene = new THREE.Scene();

	var camera = new THREE.PerspectiveCamera(
        50, 
        window.innerWidth / window.innerHeight, 
        0.1, 
        5000
    );

	var renderer = new THREE.WebGLRenderer({antialias: false});
	renderer.shadowMap.enabled = false;
	renderer.setSize(window.innerWidth/2, window.innerHeight/2);
	container.appendChild( renderer.domElement );
    
    var backgroundColour = '0xfffff0';
	scene.background = new THREE.Color( backgroundColour );

    // Resize after viewport-size-change
	window.addEventListener( 'resize', onWindowResize, false);

    function onWindowResize() {
        var width = parentDiv.clientWidth;
        var height = parentDiv.clientHeight;
        renderer.setSize(width, height);
        camera.aspect = width / height;
        camera.updateProjectionMatrix();
	}

	// Add controls
    const controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.target.set(0, 0, 0);

    var boxSize = new Array();
    const absMaterial = new THREE.MeshNormalMaterial({ 
        wireframe: false, 
        flatShading: false, 
        transparent: true,
    });

	var url = $('#dri_threejs_view').data('url');
    var extension;

    $.ajax({
        'async': false,
        type: "HEAD",
        url: url,
        success: function(message, text, response) {
            header = response.getResponseHeader('Content-Disposition');
            var filename = header.match(/filename="(.+)"/)[1].split( '.' ).pop().toLowerCase();
            extension = filename
        }
    });

    switch(extension) {
        case 'stl':
            var stlLoader = new THREE.STLLoader();
            stlLoader.load( url, function ( geometry ) {
                var mesh = new THREE.Mesh( geometry, absMaterial);
                renderObject(mesh);
                guiInitializer(absMaterial, mesh);
            },
            (xhr) => {
                console.log((xhr.loaded / xhr.total) * 100 + '% loaded');
            },
            (error) => {
                console.log(error);
            });
            break;
    
        case 'ply':
            const plyLoader = new THREE.PLYLoader();
            plyLoader.load( url, function ( ply ) {
                ply.computeVertexNormals();
                const mesh = new THREE.Mesh(ply, absMaterial);
                renderObject(mesh);
                guiInitializer(absMaterial, mesh);
            },
            (xhr) => {
                console.log((xhr.loaded / xhr.total) * 100 + '% loaded')
            },
            (error) => {
                console.log(error)
            } ); 
            break;
    
        case 'glb':
        case 'gltf':
            var dracoLoader = new THREE.DRACOLoader();
            dracoLoader.setDecoderPath('/assets/Three/lib/three/examples/js/libs/draco/')
            var gltfLoader = new THREE.GLTFLoader();
            gltfLoader.setDRACOLoader( dracoLoader );
            gltfLoader.load( url, function (gltf) {
                materialConfig(gltf.scene);
                renderObject(gltf.scene);
                guiInitializer(absMaterial, gltf.scene);
            },
            (xhr) => {
                console.log((xhr.loaded / xhr.total) * 100 + '% loaded')
            },
            (error) => {
                console.log(error)
            } );
            break;
        
        case 'fbx':
            var fbxLoader = new THREE.FBXLoader( );
            fbxLoader.load( url, function ( fbx ) {
                materialConfig(fbx);
                renderObject(fbx);
                guiInitializer(absMaterial, fbx);
                const spinner = document.getElementById('spinner');
                spinner.parentNode.removeChild(spinner);
            },
            (xhr) => {
                console.log((xhr.loaded / xhr.total) * 100 + '% loaded');

            },
            (error) => {
                console.log(error);
            } );
            break;
    
        case 'obj':
            var objLoader = new THREE.OBJLoader( );
            objLoader.load( url, function (obj) {
                materialConfig(obj);
                renderObject(obj);
                guiInitializer(absMaterial, obj);
            },
            (xhr) => {
                console.log((xhr.loaded / xhr.total) * 100 + '% loaded');
            },
            (error) => {
                console.log(error);
            } );            
            break;
    
        case 'dae':
            const colladaL = new THREE.ColladaLoader();
            colladaL.load( url, function(dae){
                materialConfig(dae.scene);
                renderObject(dae.scene);
                guiInitializer(absMaterial, dae.scene);
            },
            (xhr) => {
                console.log((xhr.loaded / xhr.total) * 100 + '% loaded');
            },
            (error) => {
                console.log(error);
            } );
            
            break;
    
        default:
            console.log("Unsupported file type: " + extension);
    }

    function materialConfig(object){
        object.traverse( function(child){
            if(child.isMesh){
                child.material = absMaterial;
                child.shadow = false;
                child.castShadow = false;
                child.receiveShadow = false;
                child.frustumCulled = true;
            }
        });
    }

    function renderObject(object){
        scene.add(object);
        object.position.set(0, 0, 0);
        object.castShadow = true;
        object.receiveShadow = true;
        boxSize = getBoxSize(object);
        setCamera(boxSize);
    }

    function getBoxSize(object){
        let boundingBox = new THREE.Box3().setFromObject( object );
        let boxSize = new THREE.Vector3();
        boundingBox.getSize(boxSize);
        return [Math.round(boxSize.x),Math.round(boxSize.y),Math.round(boxSize.z)];
    }

    function setCamera(objectSize){
        camera.lookAt(new THREE.Vector3(0,0,0));
        let x,y,z;
    
        if(objectSize[0] != undefined && objectSize[1] != undefined && objectSize[1] != undefined){
            x = objectSize[0];
            y = objectSize[1];
            z = objectSize[2];
        } else {
            var degree = Math.PI/180;
            z = 120;
            y = 120;
            x = -45 * degree;
        }
    
        camera.position.set(y, x, z+x+y);
    
        cameraTarget = new THREE.Vector3( 0, 0, 0 );
    }

    function guiInitializer(material, object){

        var gui = new dat.GUI({autoPlace: false});
        gui.domElement.id = "gui";
        parentDiv.appendChild(gui.domElement);

        var options = { 
            wireframe: false,
            object: 0x1111111,
            background: 0xfffff0,
            lights: false,
            material: false,
        }

        var refreshMaterial = {
            reset: function() {
                material.wireframe = false;
                material.flatShading = false;
                material.opacity = 1.0;
                material.needsUpdate = true;
                scene.background = new THREE.Color(options.background);
                resetGUI();
            }
        };

        function resetGUI() {
            // Get all the folders in GUI
            const folders = gui.__folders;
        
            // Loop through each folder and reset properties
            for (let folderName in folders) {
                const folder = folders[folderName];
                const controllers = folder.__controllers;
        
                // Loop through each controller in the folderand set default
                for (let i = 0; i < controllers.length; i++) {
                    const controller = controllers[i];
                    controller.setValue(controller.initialValue);
                }
            }
        }
        
        const materialFolder = gui.addFolder('Material Control');
        materialFolder.add(material, 'opacity', 0, 1, 0.01);
        materialFolder.add(material, 'wireframe').onChange(() => material.needsUpdate = true);
        materialFolder.add(material, 'flatShading').onChange(() => material.needsUpdate = true);
        materialFolder.add(refreshMaterial, "reset").onChange(() => material.needsUpdate = true);
        const cameraFolder = gui.addFolder('Camera Control');
        cameraFolder.add(object.rotation, 'x', 0, Math.PI * 2);
        cameraFolder.add(object.rotation, 'y', 0, Math.PI * 2);
        cameraFolder.add(object.rotation, 'z', 0, Math.PI * 2);
    
        const colorFolder = gui.addFolder('Color Control');
        colorFolder.addColor(options, 'background').onChange( col => {
            scene.background = new THREE.Color(col);
        });

        
        gui.close();

    }

    //recursive function to update scene continuously
    function animate() {
        requestAnimationFrame(animate);
        controls.update();
        renderer.render(scene, camera);
    }
    animate();

    setTimeout(function() {
        if (parentDiv.clientWidth > 0){
        onWindowResize();
        }
      }, 2000);
});
