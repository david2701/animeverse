import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/model_anime.dart';
import 'direct_video_player_screen.dart'; // Asegúrate de importar correctamente
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Episode episode;

  const VideoPlayerScreen({required this.episode, Key? key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();

    if (widget.episode.videoOptions.isNotEmpty) {
      _currentVideoUrl = widget.episode.videoOptions.first.url;
    }
  }

  // Función para manejar la selección de una opción de video
  void _onVideoOptionSelected(String optionName, String url) async {
    print('Seleccionando opción: $optionName, URL: $url');

    // Obtener el enlace directo al video
    final directUrl = await fetchDirectVideoUrl(url);
    if (directUrl != null) {
      // Navegar al reproductor de video nativo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DirectVideoPlayerScreen(videoPath: '',
          ),
        ),
      );
    } else {
      // Fallback: usar WebView si no se pudo extraer la URL directa
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmbeddedWebViewScreen(embedUrl: url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episode.title),
        actions: [
          // Botón para recargar la pantalla (opcional)
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Implementa lógica de recarga si es necesario
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              'Selecciona una Opción de Video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Mostrar la URL del video para depuración
            if (_currentVideoUrl != null)
              Text(
                'URL del Video: $_currentVideoUrl',
                style: TextStyle(color: Colors.blue),
              ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.episode.videoOptions.length,
                itemBuilder: (context, index) {
                  final option = widget.episode.videoOptions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _onVideoOptionSelected(option.optionName, option.url);
                      },
                      child: Text(option.optionName),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Función para obtener el enlace directo del video
Future<String?> fetchDirectVideoUrl(String embeddedUrl) async {
  try {
    final response = await http.get(Uri.parse(embeddedUrl));
    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);

      // Dependiendo del servicio, busca diferentes selectores
      // Este es un ejemplo genérico y puede necesitar ajustes
      final videoElement = document.querySelector('video');
      if (videoElement != null) {
        final src = videoElement.attributes['src'];
        if (src != null && src.isNotEmpty) {
          return src;
        }
      }

      // Ejemplo para Mega usando meta tag
      final ogVideo = document.querySelector('meta[property="og:video"]');
      if (ogVideo != null) {
        final content = ogVideo.attributes['content'];
        if (content != null && content.isNotEmpty) {
          return content;
        }
      }

      // Otros métodos para extraer el enlace directo pueden ser necesarios
      // Como analizar scripts o llamadas AJAX
    } else {
      print('Error al cargar la página: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al obtener el enlace directo: $e');
  }
  return null;
}

// Función para descargar el video temporalmente
Future<File?> downloadVideo(String url) async {
  try {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await Dio().download(url, filePath);
    return File(filePath);
  } catch (e) {
    print('Error al descargar el video: $e');
    return null;
  }
}

// Pantalla de WebView como fallback
class EmbeddedWebViewScreen extends StatefulWidget {
  final String embedUrl;

  const EmbeddedWebViewScreen({required this.embedUrl, Key? key}) : super(key: key);

  @override
  _EmbeddedWebViewScreenState createState() => _EmbeddedWebViewScreenState();
}

class _EmbeddedWebViewScreenState extends State<EmbeddedWebViewScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reproducción de Video'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _webViewController?.reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de Progreso
          (_progress < 1.0)
              ? LinearProgressIndicator(value: _progress)
              : SizedBox.shrink(),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(widget.embedUrl),
                  ),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      javaScriptEnabled: true,
                      mediaPlaybackRequiresUserGesture: false,
                      useShouldOverrideUrlLoading: true,
                      cacheEnabled: true,
                    ),
                    android: AndroidInAppWebViewOptions(
                      useHybridComposition: true,
                      builtInZoomControls: false,
                      displayZoomControls: false,
                      domStorageEnabled: true,
                    ),
                    ios: IOSInAppWebViewOptions(
                      allowsInlineMediaPlayback: true,
                      allowsAirPlayForMediaPlayback: true,
                      allowsPictureInPictureMediaPlayback: true,
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _webViewController?.addJavaScriptHandler(
                      handlerName: 'extractVideoUrl',
                      callback: (args) {
                        if (args.isNotEmpty && args[0] != null) {
                          String videoUrl = args[0];
                          _playVideo(videoUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No se pudo extraer la URL del video')),
                          );
                        }
                      },
                    );
                  },
                  onLoadStart: (controller, url) {
                    print('Página iniciada: $url'); // Debug print
                    setState(() {
                      _progress = 0;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    print('Página terminada: $url'); // Debug print
                    _injectAdBlocker();
                    _extractVideoUrl(); // Intentar extraer la URL del video
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onLoadError: (controller, url, code, message) {
                    print('Error en WebView: $message'); // Debug print
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error cargando el video: $message')),
                    );
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    var uri = navigationAction.request.url;

                    // Permitir navegaciones dentro del dominio principal
                    if (uri != null && !uri.toString().startsWith('https://tioanime.com')) {
                      // Opcional: Abre en el navegador externo
                      if (await canLaunch(uri.toString())) {
                        await launch(uri.toString());
                        return NavigationActionPolicy.CANCEL;
                      }
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print("Console Message: ${consoleMessage.message}");
                  },
                  // Manejo de Solicitudes de Autenticación SSL
                  onReceivedServerTrustAuthRequest:
                      (controller, challenge) async {
                    // Lista de hosts permitidos para confiar en el certificado
                    List<String> allowedHosts = [
                      'mega.nz',
                      'g.api.mega.co.nz',
                      // Agrega otros hosts si es necesario
                    ];

                    if (allowedHosts.contains(challenge.protectionSpace.host)) {
                      return ServerTrustAuthResponse(
                        action: ServerTrustAuthResponseAction.PROCEED,
                      );
                    } else {
                      return ServerTrustAuthResponse(
                        action: ServerTrustAuthResponseAction.CANCEL,
                      );
                    }
                  },
                ),
                // Indicador de Carga Centrado
                (_progress < 1.0)
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Método para inyectar JavaScript que oculta elementos de publicidad
  void _injectAdBlocker() {
    // Bloqueo de anuncios mediante bloqueo de elementos conocidos
    String jsCode = """
      // Bloquear anuncios mediante bloqueo de elementos conocidos
      const adSelectors = [
        '.ad', '.popup', '.banner', '.advertisement', '#ads', '.adsbygoogle',
        '.iframe-ad', '.advert', '.google-ad', '.ad-container'
      ];
      
      adSelectors.forEach(function(selector) {
        const ads = document.querySelectorAll(selector);
        ads.forEach(function(ad) {
          ad.remove();
        });
      });
      
      // Bloquear solicitudes de recursos de anuncios
      const originalFetch = window.fetch;
      window.fetch = function() {
        const args = arguments;
        const url = args[0];
        if (url.includes('ads') || url.includes('advertisement') || url.includes('doubleclick')) {
          return Promise.reject('Ad blocked');
        }
        return originalFetch.apply(this, args);
      };
      
      // Similar para XMLHttpRequest
      const originalXHROpen = XMLHttpRequest.prototype.open;
      XMLHttpRequest.prototype.open = function() {
        const url = arguments[1];
        if (url.includes('ads') || url.includes('advertisement') || url.includes('doubleclick')) {
          console.log('Ad blocked: ' + url);
          return;
        }
        return originalXHROpen.apply(this, arguments);
      };
      
      // Bloquear ventanas emergentes
      window.open = function() {};
      
      // Observador para elementos dinámicos
      const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          adSelectors.forEach(function(selector) {
            const ads = document.querySelectorAll(selector);
            ads.forEach(function(ad) {
              ad.remove();
            });
          });
        });
      });
      
      observer.observe(document.body, { childList: true, subtree: true });
    """;

    _webViewController?.evaluateJavascript(source: jsCode).then((_) {
      print('JavaScript para bloquear ads inyectado.'); // Debug print
    }).catchError((error) {
      print('Error al inyectar JavaScript: $error'); // Debug print
    });
  }

  /// Método para extraer la URL del video
  void _extractVideoUrl() {
    String jsCode = """
      // Buscar el elemento de video y extraer la URL
      var video = document.querySelector('video');
      if (video && video.src) {
        // Enviar la URL al Flutter
        window.flutter_inappwebview.callHandler('extractVideoUrl', video.src);
      } else {
        // Buscar en meta tags
        var metaOgVideo = document.querySelector('meta[property="og:video"]');
        if (metaOgVideo && metaOgVideo.content) {
          window.flutter_inappwebview.callHandler('extractVideoUrl', metaOgVideo.content);
        } else {
          // Intentar extraer de otros scripts o variables globales
          // Esto puede requerir análisis más profundo de la página
          window.flutter_inappwebview.callHandler('extractVideoUrl', null);
        }
      }
    """;

    _webViewController?.evaluateJavascript(source: jsCode).then((_) {
      print('JavaScript para extraer URL de video inyectado.');
    }).catchError((error) {
      print('Error al inyectar JavaScript para extraer URL de video: $error');
    });
  }

  /// Método para reproducir el video descargado
  void _playVideo(String videoUrl) async {
    // Descargar el video temporalmente
    File? videoFile = await downloadVideo(videoUrl);
    if (videoFile != null) {
      // Navegar al reproductor de video nativo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DirectVideoPlayerScreen(videoPath: videoFile.path),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar el video')),
      );
    }
  }

  /// Función para descargar el video temporalmente
  Future<File?> downloadVideo(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await Dio().download(url, filePath);
      return File(filePath);
    } catch (e) {
      print('Error al descargar el video: $e');
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}