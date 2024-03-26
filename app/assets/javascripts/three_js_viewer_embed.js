$(document).ready(function () {
    $('.three_js_viewer_embed').each(function () {
        var element = $(this);
        var url = element.data('url');
        var file = element.data('file');
        var id = String(element.attr('id'));
        var extension = file.split('.').pop().toLowerCase();

        var container = document.createElement('div');

        var parentDiv = document.getElementById(String(element.attr('id')));
        parentDiv.appendChild(container);

        var scene = new THREE.Scene();
        var camera = new THREE.PerspectiveCamera(
            50, 
            window.innerWidth / window.innerHeight, 
            0.1, 
            5000
        );

        // Set Normal material
        const normalMaterial = new THREE.MeshNormalMaterial({
            wireframe: false,
            flatShading: false,
            transparent: false
        });

        // Set a larger canvas size
        var canvasWidth = 560;
        var canvasHeight = 315;

        var renderer = new THREE.WebGLRenderer();
        renderer.setSize(canvasWidth, canvasHeight);
        parentDiv.appendChild(renderer.domElement);

        var controls = new THREE.OrbitControls(camera, renderer.domElement);

        function handleError(fileType, error) {
            console.error(`Error loading ${fileType} file:`, error);
        }

        switch(extension) {
            case 'stl':
                var loader = new THREE.STLLoader();
                loader.load(url, function (geometry) {
                    var mesh = new THREE.Mesh(geometry);
                    processObject(mesh);
                    scene.add(mesh);
                    setCamera(mesh);
                    animate();
                }, undefined, handleError.bind(null, 'STL'));
                break;

            case 'ply':
                var loader = new THREE.PLYLoader();
                loader.load(url, function (geometry) {
                    geometry.computeVertexNormals();
                    var mesh = new THREE.Mesh(geometry);
                    processObject(mesh)
                    scene.add(mesh);
                    setCamera(mesh);
                    animate();
                    }, undefined, handleError.bind(null, 'PLY'));
                    break;

            case 'glb':
            case 'gltf':
                const dracoLoader = new THREE.DRACOLoader();
                dracoLoader.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.4.1/');
                dracoLoader.setDecoderConfig({ type: 'js' });
                const gltfLoader = new THREE.GLTFLoader();
                gltfLoader.setDRACOLoader(dracoLoader);
                gltfLoader.load(
                    url,
                    function (gltf) {
                        var sceneModel = gltf.scene;
                        processObject(sceneModel)
                        scene.add(sceneModel);
                        setCamera(sceneModel);
                        animate();
                    }, undefined, handleError.bind(null, 'GLTF'));
                    break;
            
            case 'fbx':
                var loader = new THREE.FBXLoader();
                loader.load(url, function (object) {
                    processObject(object)
                    scene.add(object);
                    setCamera(object);
                    animate();
                }, undefined, handleError.bind(null, 'FBX'));
                break;
                    
            case 'obj':
                var loader = new THREE.OBJLoader();
                loader.load(url, function (object) {
                    processObject(object)
                    scene.add(object);
                    setCamera(object);
                    animate();
                }, undefined, handleError.bind(null, 'OBJ'));
                break;
                    
            case 'dae':
                var loader = new THREE.ColladaLoader();
                loader.load(url, function (collada) {
                    var object = collada.scene;
                    if (object.children.length > 0) {
                        var mesh = object.children[0];
                        processObject(mesh);
                        scene.add(mesh);
                        setCamera(mesh);
                        animate();
                    } else {
                        console.error('No child meshes found.');
                    }
                }, undefined, handleError.bind(null, 'DAE'));
                break;
        
            default:
                console.error('Error loading 3D file:', error);
        }

        var animate = function () {
            requestAnimationFrame(animate);
            controls.update();
            renderer.render(scene, camera);
        };

        function processObject(object) {
            try {
                object.traverse(function (child) {
                    if (child.isMesh) {
                        child.material = normalMaterial;
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

        if (scene.background === null || scene.background === undefined ) {
            var backgroundColour = new THREE.Color(0xd8d8d8);
            scene.background = new THREE.Color( backgroundColour );
        }

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
        
    });
});
