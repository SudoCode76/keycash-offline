import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets/gemini_key.dart';

/// Servicio central para interactuar con Gemini.
///
/// NOTA: La clave está embebida en kGeminiApiKey (ver secrets/gemini_key.dart).
/// En producción real se recomienda usar un backend proxy.
///
/// Versión del paquete:
/// Asegúrate de que la versión instalada de `google_generative_ai` soporta
/// `GenerativeModel.generateContentStream` y el constructor posicional de `Content`.
class AiService {
  /// Modelo por defecto (rápido y económico). Puedes cambiar a 'gemini-1.5-pro'
  /// si necesitas más capacidad.
  final String modelName;

  GenerativeModel? _model;

  AiService({
    this.modelName = 'gemini-1.5-flash',
  });

  bool get hasKey => kGeminiApiKey.isNotEmpty;

  GenerativeModel get _ensureModel {
    if (!hasKey) {
      throw StateError(
        'Gemini API key vacía. Define kGeminiApiKey en secrets/gemini_key.dart',
      );
    }
    _model ??= GenerativeModel(
      model: modelName,
      apiKey: kGeminiApiKey,
      // Puedes añadir safetySettings / generationConfig si lo deseas:
      // generationConfig: GenerationConfig(
      //   temperature: 0.7,
      //   maxOutputTokens: 1024,
      // ),
    );
    return _model!;
  }

  /// Streaming de respuesta a partir de todo el historial.
  Stream<GenerateContentResponse> streamGenerate(List<Content> historyParts) {
    if (historyParts.isEmpty) {
      return Stream.error(
        ArgumentError('historyParts no puede estar vacío'),
      );
    }
    final model = _ensureModel;
    return model.generateContentStream(historyParts);
  }

  /// Llamada NO streaming (por si en algún momento la necesitas).
  Future<GenerateContentResponse> generate(List<Content> historyParts) async {
    if (historyParts.isEmpty) {
      throw ArgumentError('historyParts no puede estar vacío');
    }
    final model = _ensureModel;
    return model.generateContent(historyParts);
  }

  /// Crea un Content con rol explícito (contructor POSICIONAL).
  /// role: 'user' o 'model'
  static Content toContent(String role, String text) {
    return Content(role, [TextPart(text)]);
  }

  /// Inyecta un "system prompt" simulándolo como un mensaje de usuario
  /// con prefijo (ya que algunos modelos no soportan role system directo).
  static Content systemPrompt(String text) {
    return Content('user', [TextPart('SYSTEM_PROMPT: $text')]);
  }

  /// Helper rápido para crear un mensaje simple de usuario sin especificar role manualmente.
  static Content userText(String text) => Content('user', [TextPart(text)]);
  /// Helper para crear un mensaje simple del modelo (en casos de reconstrucción de historial).
  static Content modelText(String text) => Content('model', [TextPart(text)]);
}