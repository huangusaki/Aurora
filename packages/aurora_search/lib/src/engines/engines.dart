library;

import '../base_search_engine.dart';
import '../search_result.dart';
import 'bing.dart';
import 'brave.dart';
import 'duckduckgo.dart';
import 'duckduckgo_images.dart';
import 'duckduckgo_news.dart';
import 'duckduckgo_videos.dart';
import 'ecosia.dart';
import 'google.dart';
import 'mojeek.dart';
import 'qwant.dart';
import 'startpage.dart';
import 'wikipedia.dart';
import 'yahoo.dart';
import 'yandex.dart';

final Map<
    String,
    Map<
        String,
        BaseSearchEngine<SearchResult> Function({
          String? proxy,
          Duration? timeout,
          bool verify,
        })>> engines = {
  'text': {
    'bing': ({proxy, timeout, verify = true}) =>
        BingEngine(proxy: proxy, timeout: timeout, verify: verify),
    'brave': ({proxy, timeout, verify = true}) =>
        BraveEngine(proxy: proxy, timeout: timeout, verify: verify),
    'duckduckgo': ({proxy, timeout, verify = true}) =>
        DuckDuckGoEngine(proxy: proxy, timeout: timeout, verify: verify),
    'ecosia': ({proxy, timeout, verify = true}) =>
        EcosiaEngine(proxy: proxy, timeout: timeout, verify: verify),
    'google': ({proxy, timeout, verify = true}) =>
        GoogleEngine(proxy: proxy, timeout: timeout, verify: verify),
    'mojeek': ({proxy, timeout, verify = true}) =>
        MojeekEngine(proxy: proxy, timeout: timeout, verify: verify),
    'qwant': ({proxy, timeout, verify = true}) =>
        QwantEngine(proxy: proxy, timeout: timeout, verify: verify),
    'startpage': ({proxy, timeout, verify = true}) =>
        StartPageEngine(proxy: proxy, timeout: timeout, verify: verify),
    'wikipedia': ({proxy, timeout, verify = true}) =>
        WikipediaEngine(proxy: proxy, timeout: timeout, verify: verify),
    'yahoo': ({proxy, timeout, verify = true}) =>
        YahooEngine(proxy: proxy, timeout: timeout, verify: verify),
    'yandex': ({proxy, timeout, verify = true}) =>
        YandexEngine(proxy: proxy, timeout: timeout, verify: verify),
  },
  'images': {
    'duckduckgo': ({proxy, timeout, verify = true}) =>
        DuckDuckGoImagesEngine(proxy: proxy, timeout: timeout, verify: verify),
    'google': ({proxy, timeout, verify = true}) =>
        GoogleImagesEngine(proxy: proxy, timeout: timeout, verify: verify),
    'qwant': ({proxy, timeout, verify = true}) =>
        QwantImagesEngine(proxy: proxy, timeout: timeout, verify: verify),
  },
  'videos': {
    'duckduckgo': ({proxy, timeout, verify = true}) =>
        DuckDuckGoVideosEngine(proxy: proxy, timeout: timeout, verify: verify),
  },
  'news': {
    'duckduckgo': ({proxy, timeout, verify = true}) =>
        DuckDuckGoNewsEngine(proxy: proxy, timeout: timeout, verify: verify),
    'qwant': ({proxy, timeout, verify = true}) =>
        QwantNewsEngine(proxy: proxy, timeout: timeout, verify: verify),
  },
  'books': {},
};
List<String> getAvailableEngines(String category) =>
    engines[category]?.keys.toList() ?? [];
List<String> get supportedCategories => engines.keys.toList();
bool isEngineAvailable(String category, String engine) =>
    engines[category]?.containsKey(engine) ?? false;
