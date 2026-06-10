'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "963240f17c9cda6192c3b2b76809470d",
"assets/AssetManifest.bin.json": "ea1b5d4922b1b7ed70cde5d0eb37e389",
"assets/assets/animations/arrow_down.json": "4b95cf277f91734a897069841ac12d34",
"assets/assets/animations/Congratulations.json": "e8a051ab4f77a10be7b4da1ed67467cf",
"assets/assets/animations/Target.json": "b766bd7a9e5bd8c2e204c4919e8da71f",
"assets/assets/animations/Trophy.json": "06363136e1a81639b8ae12789528088c",
"assets/assets/Before_or_after_logo.png": "b80e51b1d6f60f473b8ded2a94ba2a13",
"assets/assets/boa-logo-final-v4.png": "871061508a08be71076d674cdb5e080a",
"assets/assets/boa-logo-transparent-v3.png": "0505edb87db219ce60bed312eb69b416",
"assets/assets/boa-logo-transparent.png": "db85a01d8a3bee3f3c6ee4d19533d5f8",
"assets/assets/boa-logo-v5.png": "612bc0e1d5602e49d8998f00503617cc",
"assets/assets/chillhop.mp3": "e5864888884e0dbe7c81f9cb83b84752",
"assets/assets/correct.mp3": "4ed81ef7499c4f02f0e5e15dfc2edc65",
"assets/assets/facts_00s.json": "80436b9b98808eb98182b7e36f667cca",
"assets/assets/facts_10s.json": "80c3705e1b267ce780e9134ecc23ec52",
"assets/assets/facts_70s.json": "6dabc4bbbe52d528e65519270debda5f",
"assets/assets/facts_80s.json": "7d72a6144c8854372428819e71c3fdce",
"assets/assets/facts_90s.json": "c4d4cb755d7c8bd8b0e716961ebbcb67",
"assets/assets/facts_arabic.json": "7f8488f2e0c68b81fd3838369169e002",
"assets/assets/facts_ext_1.json": "dd7259fd82fd1f92c95ebaf19f3d8d22",
"assets/assets/facts_ext_2.json": "907ad2c8cced883622b72c215f551bd5",
"assets/assets/facts_ext_final.json": "ddb96a2e7f97a94f9a89a65f5cc169fb",
"assets/assets/facts_recent.json": "f61d4120720e22f61c551e38f05e5318",
"assets/assets/gts-logo-transparent.png": "cec9ff39b7256cb5297b0ff72ee12368",
"assets/assets/gts-logo.png": "a9fc4884fcd351c72cfc9ed550614f7c",
"assets/assets/Guess_that_song_logo.png": "993f9b016fc71149369f0620d2c18fd5",
"assets/assets/intro.mp3": "c07f40b2a6291a22ee7347df9e137128",
"assets/assets/logo_reveal.mp3": "5291cc7ad9bfa24260118a0fefa54d6d",
"assets/assets/Musica_logo.png": "e243ca96ea81dabf505b3c8dee582935",
"assets/assets/songs.json": "85eb8a3c1d37bfd8c0d10d42392564d4",
"assets/assets/songs.json.bak": "056bc94486e1c43938499a132fa7e4b6",
"assets/assets/songs_arabic.json": "b3f600131a8357e66c08f5cf21300d25",
"assets/assets/songs_arabic.json.abdel_bkp": "329a537fd3dc99d3c17970ac8fb2caa6",
"assets/assets/songs_arabic.json.ahlam_bkp": "7e934921bb740674652e2b06ce42071c",
"assets/assets/songs_arabic.json.bahar_bkp": "e557834cb74791caedf1d2ff3eb90b84",
"assets/assets/songs_arabic.json.bak": "207d3e10a4160de17cddf119df5c5735",
"assets/assets/songs_arabic.json.fadel_bkp": "859be258eb6396811d0085e962b0761c",
"assets/assets/songs_arabic.json.fairouz_bkp": "59470469d7deda7065b00af2fbfc3e32",
"assets/assets/songs_arabic.json.jasmi_bkp": "6bca2fd67d90afec7f1591a1d0697a60",
"assets/assets/songs_arabic.json.jumairi_bkp": "15084b244e3d310ddd472daaa5084f18",
"assets/assets/songs_arabic.json.kadim_bkp": "c6a729f5e340c4ec0d6624ccb97798c1",
"assets/assets/songs_arabic.json.khaled_bkp": "7e060b32f4f8e35e173230ab32678dce",
"assets/assets/songs_arabic.json.mayada_bkp": "b0573c81253ef76c756da9ca1262716d",
"assets/assets/songs_arabic.json.nawal_bkp": "d0ab40da485b61243310a5faa64ab6b0",
"assets/assets/songs_arabic.json.rowaish_bkp": "8f9eab37e28fcbc6959cba178fdaf2cb",
"assets/assets/songs_arabic.json.warda_bkp": "77cf9d7eb398e4e55dcac012e898572e",
"assets/assets/songs_arabic_backup.json": "a57fe9408771fe741bd1fdf336585be3",
"assets/assets/songs_backup_before_revert.json": "1af37b7600ed9a4e3f9d93b35fd582d3",
"assets/assets/TimeSurvival_logo.png": "0499730160a19e6e8298e35207166691",
"assets/assets/UK_flag%2520-%2520Copy.json": "8f08e243e974ee579adc3e01112d58be",
"assets/assets/UK_flag.json": "8f08e243e974ee579adc3e01112d58be",
"assets/assets/USA_flag.json": "f6fd6a8df3e39fcecbf40c3481d57a29",
"assets/assets/water_drop.mp3": "d5923af3b3ce1f5a937c93d53b2bf61a",
"assets/assets/wrong.mp3": "1506875cd2b698b595dcfcfa73fcd3b5",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "be91c371ac5b6dd75a0114312a93be3b",
"assets/NOTICES": "3af0acb17b505c07b51c1da48d56fbe8",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "ba4b5ce080219b51978974c58312b746",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "f4b6e48a2c93dbd7161208c2ef52ece6",
"/": "f4b6e48a2c93dbd7161208c2ef52ece6",
"main.dart.js": "40bbbecb9c7c5f06239c99d01ac8d47c",
"manifest.json": "86e67dcad05570aedf4fbff8a9c96efe",
"version.json": "d44fc5974cf70d54bd77614c9daaf6b3"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
