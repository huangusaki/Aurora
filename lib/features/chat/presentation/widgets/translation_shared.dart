import 'package:aurora/l10n/app_localizations.dart';

const String translationAutoLanguageCode = 'auto';
const String translationSimplifiedChineseLanguageCode = 'zh-Hans';
const String translationTraditionalChineseLanguageCode = 'zh-Hant';
const String translationDefaultSourceLanguageCode = translationAutoLanguageCode;
const String translationDefaultTargetLanguageCode =
    translationSimplifiedChineseLanguageCode;
const bool translationDefaultShowComparison = true;

const List<String> translationSourceLanguageCodes = <String>[
  translationAutoLanguageCode,
  'en',
  'ja',
  'ko',
  translationSimplifiedChineseLanguageCode,
  translationTraditionalChineseLanguageCode,
  'ru',
  'fr',
  'de',
];

const List<String> translationTargetLanguageCodes = <String>[
  translationSimplifiedChineseLanguageCode,
  'en',
  'ja',
  'ko',
  translationTraditionalChineseLanguageCode,
  'ru',
  'fr',
  'de',
];

String normalizeTranslationLanguageCode(String code) {
  switch (code.toLowerCase()) {
    case 'zh_hans':
    case 'zh-hans':
      return translationSimplifiedChineseLanguageCode;
    case 'zh_hant':
    case 'zh-hant':
      return translationTraditionalChineseLanguageCode;
    default:
      return code;
  }
}

String translationLanguageLabel(AppLocalizations l10n, String code) {
  switch (normalizeTranslationLanguageCode(code)) {
    case translationAutoLanguageCode:
      return l10n.autoDetect;
    case 'en':
      return l10n.english;
    case 'ja':
      return l10n.japanese;
    case 'ko':
      return l10n.korean;
    case translationSimplifiedChineseLanguageCode:
      return l10n.simplifiedChinese;
    case translationTraditionalChineseLanguageCode:
      return l10n.traditionalChinese;
    case 'ru':
      return l10n.russian;
    case 'fr':
      return l10n.french;
    case 'de':
      return l10n.german;
    default:
      return code;
  }
}

String buildTranslationPrompt(
  AppLocalizations l10n, {
  required String sourceLanguageCode,
  required String targetLanguageCode,
  required String sourceText,
}) {
  final normalizedSourceLanguageCode =
      normalizeTranslationLanguageCode(sourceLanguageCode);
  final normalizedTargetLanguageCode =
      normalizeTranslationLanguageCode(targetLanguageCode);
  final sourceLanguageLabel =
      translationLanguageLabel(l10n, normalizedSourceLanguageCode);
  final targetLanguageLabel =
      translationLanguageLabel(l10n, normalizedTargetLanguageCode);

  final sb = StringBuffer();
  sb.writeln(normalizedSourceLanguageCode == translationAutoLanguageCode
      ? l10n.translationPromptIntroAuto(targetLanguageLabel)
      : l10n.translationPromptIntro(
          sourceLanguageLabel,
          targetLanguageLabel,
        ));
  sb.writeln(l10n.translationPromptRequirements);
  sb.writeln(l10n.translationPromptRequirement1);
  sb.writeln(l10n.translationPromptRequirement2);
  sb.writeln(l10n.translationPromptRequirement3);
  sb.writeln();
  sb.writeln(l10n.translationPromptSourceText);
  sb.writeln(sourceText);
  return sb.toString();
}
