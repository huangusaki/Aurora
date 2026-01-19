import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Aurora'**
  String get appTitle;

  /// No description provided for @newChat.
  ///
  /// In zh, this message translates to:
  /// **'新对话'**
  String get newChat;

  /// No description provided for @searchChatHistory.
  ///
  /// In zh, this message translates to:
  /// **'搜索聊天记录'**
  String get searchChatHistory;

  /// No description provided for @send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @history.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get history;

  /// No description provided for @modelNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择模型'**
  String get modelNotSelected;

  /// No description provided for @closeComparison.
  ///
  /// In zh, this message translates to:
  /// **'关闭对照'**
  String get closeComparison;

  /// No description provided for @bilingualComparison.
  ///
  /// In zh, this message translates to:
  /// **'双语对照'**
  String get bilingualComparison;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clear;

  /// No description provided for @translating.
  ///
  /// In zh, this message translates to:
  /// **'翻译中...'**
  String get translating;

  /// No description provided for @translationResultPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'翻译结果将显示在这里'**
  String get translationResultPlaceholder;

  /// No description provided for @selectModel.
  ///
  /// In zh, this message translates to:
  /// **'选择模型'**
  String get selectModel;

  /// No description provided for @switchModel.
  ///
  /// In zh, this message translates to:
  /// **'切换模型'**
  String get switchModel;

  /// No description provided for @deepThinking.
  ///
  /// In zh, this message translates to:
  /// **'深度思考中...'**
  String get deepThinking;

  /// No description provided for @deepThoughtFinished.
  ///
  /// In zh, this message translates to:
  /// **'已深度思考 (用时 {duration} 秒)'**
  String deepThoughtFinished(String duration);

  /// No description provided for @thoughtChain.
  ///
  /// In zh, this message translates to:
  /// **'思维链'**
  String get thoughtChain;

  /// No description provided for @camera.
  ///
  /// In zh, this message translates to:
  /// **'相机'**
  String get camera;

  /// No description provided for @photos.
  ///
  /// In zh, this message translates to:
  /// **'相册'**
  String get photos;

  /// No description provided for @userSettings.
  ///
  /// In zh, this message translates to:
  /// **'用户设置'**
  String get userSettings;

  /// No description provided for @chatExperience.
  ///
  /// In zh, this message translates to:
  /// **'对话体验'**
  String get chatExperience;

  /// No description provided for @smartTopicGeneration.
  ///
  /// In zh, this message translates to:
  /// **'智能话题生成'**
  String get smartTopicGeneration;

  /// No description provided for @smartTopicDescription.
  ///
  /// In zh, this message translates to:
  /// **'使用 LLM 自动总结作为话题标题'**
  String get smartTopicDescription;

  /// No description provided for @generationModel.
  ///
  /// In zh, this message translates to:
  /// **'生成模型'**
  String get generationModel;

  /// No description provided for @notSelectedFallback.
  ///
  /// In zh, this message translates to:
  /// **'未选择 (回退到截断)'**
  String get notSelectedFallback;

  /// No description provided for @userInfo.
  ///
  /// In zh, this message translates to:
  /// **'用户信息'**
  String get userInfo;

  /// No description provided for @userName.
  ///
  /// In zh, this message translates to:
  /// **'用户名称'**
  String get userName;

  /// No description provided for @userAvatar.
  ///
  /// In zh, this message translates to:
  /// **'用户头像'**
  String get userAvatar;

  /// No description provided for @assistantAvatar.
  ///
  /// In zh, this message translates to:
  /// **'助理头像'**
  String get assistantAvatar;

  /// No description provided for @globalConfig.
  ///
  /// In zh, this message translates to:
  /// **'全局配置'**
  String get globalConfig;

  /// No description provided for @excludedModels.
  ///
  /// In zh, this message translates to:
  /// **'排除模型'**
  String get excludedModels;

  /// No description provided for @excludedModelsHint.
  ///
  /// In zh, this message translates to:
  /// **'全局配置在这些模型上不生效'**
  String get excludedModelsHint;

  /// No description provided for @enterModelNameHint.
  ///
  /// In zh, this message translates to:
  /// **'输入模型名称并回车添加'**
  String get enterModelNameHint;

  /// No description provided for @clickToChangeAvatar.
  ///
  /// In zh, this message translates to:
  /// **'点击更换头像'**
  String get clickToChangeAvatar;

  /// No description provided for @aiInfo.
  ///
  /// In zh, this message translates to:
  /// **'AI 信息'**
  String get aiInfo;

  /// No description provided for @aiName.
  ///
  /// In zh, this message translates to:
  /// **'AI 名称'**
  String get aiName;

  /// No description provided for @aiAvatar.
  ///
  /// In zh, this message translates to:
  /// **'AI 头像'**
  String get aiAvatar;

  /// No description provided for @pleaseEnter.
  ///
  /// In zh, this message translates to:
  /// **'请输入'**
  String get pleaseEnter;

  /// No description provided for @changeAvatarTitle.
  ///
  /// In zh, this message translates to:
  /// **'更换{target}头像'**
  String changeAvatarTitle(String target);

  /// No description provided for @removeAvatar.
  ///
  /// In zh, this message translates to:
  /// **'移除头像'**
  String get removeAvatar;

  /// No description provided for @permissionRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要{name}权限'**
  String permissionRequired(String name);

  /// No description provided for @permissionContent.
  ///
  /// In zh, this message translates to:
  /// **'请在设置中允许应用访问{name}，以便拍摄头像。'**
  String permissionContent(String name);

  /// No description provided for @goToSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get goToSettings;

  /// No description provided for @selectGenerationModel.
  ///
  /// In zh, this message translates to:
  /// **'选择话题生成模型'**
  String get selectGenerationModel;

  /// No description provided for @pickImageFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择图片失败'**
  String get pickImageFailed;

  /// No description provided for @textTranslation.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get textTranslation;

  /// No description provided for @selectLanguage.
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get selectLanguage;

  /// No description provided for @sourceText.
  ///
  /// In zh, this message translates to:
  /// **'原文'**
  String get sourceText;

  /// No description provided for @targetText.
  ///
  /// In zh, this message translates to:
  /// **'译文'**
  String get targetText;

  /// No description provided for @enterTextToTranslate.
  ///
  /// In zh, this message translates to:
  /// **'在此输入要翻译的文本...'**
  String get enterTextToTranslate;

  /// No description provided for @translateButton.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get translateButton;

  /// No description provided for @compareMode.
  ///
  /// In zh, this message translates to:
  /// **'双语对照'**
  String get compareMode;

  /// No description provided for @enableCompare.
  ///
  /// In zh, this message translates to:
  /// **'开启双语对照'**
  String get enableCompare;

  /// No description provided for @disableCompare.
  ///
  /// In zh, this message translates to:
  /// **'关闭双语对照'**
  String get disableCompare;

  /// No description provided for @translationPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'翻译结果将显示在这里'**
  String get translationPlaceholder;

  /// No description provided for @sessionDetails.
  ///
  /// In zh, this message translates to:
  /// **'会话详情'**
  String get sessionDetails;

  /// No description provided for @selectOrNewTopic.
  ///
  /// In zh, this message translates to:
  /// **'请选择或新建一个话题'**
  String get selectOrNewTopic;

  /// No description provided for @startNewChat.
  ///
  /// In zh, this message translates to:
  /// **'新对话'**
  String get startNewChat;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @enabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get disabled;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get error;

  /// No description provided for @success.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get failed;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @modelProvider.
  ///
  /// In zh, this message translates to:
  /// **'模型提供'**
  String get modelProvider;

  /// No description provided for @chatSettings.
  ///
  /// In zh, this message translates to:
  /// **'对话设置'**
  String get chatSettings;

  /// No description provided for @displaySettings.
  ///
  /// In zh, this message translates to:
  /// **'界面设置'**
  String get displaySettings;

  /// No description provided for @dataSettings.
  ///
  /// In zh, this message translates to:
  /// **'数据设置'**
  String get dataSettings;

  /// No description provided for @usageStats.
  ///
  /// In zh, this message translates to:
  /// **'数据统计'**
  String get usageStats;

  /// No description provided for @providerName.
  ///
  /// In zh, this message translates to:
  /// **'供应商名称'**
  String get providerName;

  /// No description provided for @currentProvider.
  ///
  /// In zh, this message translates to:
  /// **'当前供应商'**
  String get currentProvider;

  /// No description provided for @selectProvider.
  ///
  /// In zh, this message translates to:
  /// **'选择供应商'**
  String get selectProvider;

  /// No description provided for @addProvider.
  ///
  /// In zh, this message translates to:
  /// **'添加供应商'**
  String get addProvider;

  /// No description provided for @deleteProvider.
  ///
  /// In zh, this message translates to:
  /// **'删除供应商'**
  String get deleteProvider;

  /// No description provided for @deleteProviderConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此供应商配置吗？此操作无法撤销。'**
  String get deleteProviderConfirm;

  /// No description provided for @renameProvider.
  ///
  /// In zh, this message translates to:
  /// **'重命名供应商'**
  String get renameProvider;

  /// No description provided for @enterProviderName.
  ///
  /// In zh, this message translates to:
  /// **'请输入供应商名称'**
  String get enterProviderName;

  /// No description provided for @notConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get notConfigured;

  /// No description provided for @noModelSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择模型'**
  String get noModelSelected;

  /// No description provided for @enabledStatus.
  ///
  /// In zh, this message translates to:
  /// **'启用状态'**
  String get enabledStatus;

  /// No description provided for @availableModels.
  ///
  /// In zh, this message translates to:
  /// **'可用模型'**
  String get availableModels;

  /// No description provided for @refreshList.
  ///
  /// In zh, this message translates to:
  /// **'刷新列表'**
  String get refreshList;

  /// No description provided for @fetchModelList.
  ///
  /// In zh, this message translates to:
  /// **'获取模型列表'**
  String get fetchModelList;

  /// No description provided for @noModelsData.
  ///
  /// In zh, this message translates to:
  /// **'暂无模型数据，请配置后点击获取'**
  String get noModelsData;

  /// No description provided for @noModelsFetch.
  ///
  /// In zh, this message translates to:
  /// **'暂无模型，请点击右上角获取'**
  String get noModelsFetch;

  /// No description provided for @modelConfig.
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get modelConfig;

  /// No description provided for @configureModelParams.
  ///
  /// In zh, this message translates to:
  /// **'为该模型配置专属参数'**
  String get configureModelParams;

  /// No description provided for @paramsHigherPriority.
  ///
  /// In zh, this message translates to:
  /// **'这些参数优先级高于全局设置'**
  String get paramsHigherPriority;

  /// No description provided for @noCustomParams.
  ///
  /// In zh, this message translates to:
  /// **'暂无自定义参数'**
  String get noCustomParams;

  /// No description provided for @addCustomParam.
  ///
  /// In zh, this message translates to:
  /// **'添加自定义参数'**
  String get addCustomParam;

  /// No description provided for @editParam.
  ///
  /// In zh, this message translates to:
  /// **'编辑参数'**
  String get editParam;

  /// No description provided for @paramKey.
  ///
  /// In zh, this message translates to:
  /// **'参数名 (Key)'**
  String get paramKey;

  /// No description provided for @paramValue.
  ///
  /// In zh, this message translates to:
  /// **'值 (Value)'**
  String get paramValue;

  /// No description provided for @paramType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get paramType;

  /// No description provided for @typeText.
  ///
  /// In zh, this message translates to:
  /// **'文本'**
  String get typeText;

  /// No description provided for @typeNumber.
  ///
  /// In zh, this message translates to:
  /// **'数字'**
  String get typeNumber;

  /// No description provided for @typeBoolean.
  ///
  /// In zh, this message translates to:
  /// **'布尔值'**
  String get typeBoolean;

  /// No description provided for @typeJson.
  ///
  /// In zh, this message translates to:
  /// **'JSON'**
  String get typeJson;

  /// No description provided for @formatError.
  ///
  /// In zh, this message translates to:
  /// **'格式错误'**
  String get formatError;

  /// No description provided for @selectTopicModel.
  ///
  /// In zh, this message translates to:
  /// **'选择话题生成模型'**
  String get selectTopicModel;

  /// No description provided for @noModelFallback.
  ///
  /// In zh, this message translates to:
  /// **'未选择模型将回退到默认截断逻辑'**
  String get noModelFallback;

  /// No description provided for @selectImage.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get selectImage;

  /// No description provided for @cropAvatar.
  ///
  /// In zh, this message translates to:
  /// **'裁剪头像'**
  String get cropAvatar;

  /// No description provided for @themeAndUiComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'主题和 UI 样式设置 (即将推出)'**
  String get themeAndUiComingSoon;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'中文 (简体)'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @exportData.
  ///
  /// In zh, this message translates to:
  /// **'导出数据'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get importData;

  /// No description provided for @clearAllData.
  ///
  /// In zh, this message translates to:
  /// **'清除所有数据'**
  String get clearAllData;

  /// No description provided for @totalCalls.
  ///
  /// In zh, this message translates to:
  /// **'总调用'**
  String get totalCalls;

  /// No description provided for @modelCallDistribution.
  ///
  /// In zh, this message translates to:
  /// **'模型调用分布'**
  String get modelCallDistribution;

  /// No description provided for @clearStats.
  ///
  /// In zh, this message translates to:
  /// **'清除数据'**
  String get clearStats;

  /// No description provided for @clearStatsConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有统计数据吗？此操作无法撤销。'**
  String get clearStatsConfirm;

  /// No description provided for @clearData.
  ///
  /// In zh, this message translates to:
  /// **'清除数据'**
  String get clearData;

  /// No description provided for @clearDataConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有统计数据吗？'**
  String get clearDataConfirm;

  /// No description provided for @noUsageData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noUsageData;

  /// No description provided for @callsCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次调用'**
  String callsCount(int count);

  /// No description provided for @successCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 成功'**
  String successCount(int count);

  /// No description provided for @failureCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 失败'**
  String failureCount(int count);

  /// No description provided for @averageDuration.
  ///
  /// In zh, this message translates to:
  /// **'平均'**
  String averageDuration(String duration);

  /// No description provided for @averageFirstToken.
  ///
  /// In zh, this message translates to:
  /// **'FirstToken'**
  String averageFirstToken(String duration);

  /// No description provided for @totalTokensCount.
  ///
  /// In zh, this message translates to:
  /// **'累计: {count} Tokens'**
  String totalTokensCount(int count);

  /// No description provided for @tokensPerSecond.
  ///
  /// In zh, this message translates to:
  /// **'Token/s'**
  String tokensPerSecond(String tps);

  /// No description provided for @mobileSettings.
  ///
  /// In zh, this message translates to:
  /// **'移动端设置'**
  String get mobileSettings;

  /// No description provided for @mobileSettingsHint.
  ///
  /// In zh, this message translates to:
  /// **'请使用顶部导航栏的设置按钮访问完整设置页面'**
  String get mobileSettingsHint;

  /// No description provided for @user.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get user;

  /// No description provided for @translation.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get translation;

  /// No description provided for @theme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// No description provided for @model.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get model;

  /// No description provided for @stats.
  ///
  /// In zh, this message translates to:
  /// **'统计'**
  String get stats;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @aboutAurora.
  ///
  /// In zh, this message translates to:
  /// **'关于 Aurora'**
  String get aboutAurora;

  /// No description provided for @crossPlatformLlmClient.
  ///
  /// In zh, this message translates to:
  /// **'一个跨平台 LLM 客户端'**
  String get crossPlatformLlmClient;

  /// No description provided for @githubProject.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 项目'**
  String get githubProject;

  /// No description provided for @takePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get takePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择'**
  String get selectFromGallery;

  /// No description provided for @selectFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get selectFile;

  /// No description provided for @stopGenerating.
  ///
  /// In zh, this message translates to:
  /// **'停止生成'**
  String get stopGenerating;

  /// No description provided for @regenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get regenerate;

  /// No description provided for @copyCode.
  ///
  /// In zh, this message translates to:
  /// **'复制代码'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In zh, this message translates to:
  /// **'代码已复制'**
  String get codeCopied;

  /// No description provided for @contentCopied.
  ///
  /// In zh, this message translates to:
  /// **'内容已复制'**
  String get contentCopied;

  /// No description provided for @thinking.
  ///
  /// In zh, this message translates to:
  /// **'思考中'**
  String get thinking;

  /// No description provided for @thinkingProcess.
  ///
  /// In zh, this message translates to:
  /// **'思考过程'**
  String get thinkingProcess;

  /// No description provided for @expandThinking.
  ///
  /// In zh, this message translates to:
  /// **'展开思考过程'**
  String get expandThinking;

  /// No description provided for @collapseThinking.
  ///
  /// In zh, this message translates to:
  /// **'收起思考过程'**
  String get collapseThinking;

  /// No description provided for @searchWeb.
  ///
  /// In zh, this message translates to:
  /// **'搜索网页'**
  String get searchWeb;

  /// No description provided for @searchResults.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果'**
  String get searchResults;

  /// No description provided for @imageGenerated.
  ///
  /// In zh, this message translates to:
  /// **'图片已生成'**
  String get imageGenerated;

  /// No description provided for @saveImage.
  ///
  /// In zh, this message translates to:
  /// **'保存图片'**
  String get saveImage;

  /// No description provided for @imageSaved.
  ///
  /// In zh, this message translates to:
  /// **'图片已保存'**
  String get imageSaved;

  /// No description provided for @imageSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片保存失败'**
  String get imageSaveFailed;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get yesterday;

  /// No description provided for @last7Days.
  ///
  /// In zh, this message translates to:
  /// **'最近 7 天'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In zh, this message translates to:
  /// **'最近 30 天'**
  String get last30Days;

  /// No description provided for @earlier.
  ///
  /// In zh, this message translates to:
  /// **'更早'**
  String get earlier;

  /// No description provided for @deleteChat.
  ///
  /// In zh, this message translates to:
  /// **'删除对话'**
  String get deleteChat;

  /// No description provided for @deleteChatConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此对话吗？'**
  String get deleteChatConfirm;

  /// No description provided for @pinChat.
  ///
  /// In zh, this message translates to:
  /// **'置顶对话'**
  String get pinChat;

  /// No description provided for @unpinChat.
  ///
  /// In zh, this message translates to:
  /// **'取消置顶'**
  String get unpinChat;

  /// No description provided for @noMessages.
  ///
  /// In zh, this message translates to:
  /// **'暂无消息'**
  String get noMessages;

  /// No description provided for @typeMessage.
  ///
  /// In zh, this message translates to:
  /// **'输入消息...'**
  String get typeMessage;

  /// No description provided for @editApiKey.
  ///
  /// In zh, this message translates to:
  /// **'编辑 API Key'**
  String get editApiKey;

  /// No description provided for @editBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'编辑 API Base URL'**
  String get editBaseUrl;

  /// No description provided for @sourceLanguage.
  ///
  /// In zh, this message translates to:
  /// **'源语言'**
  String get sourceLanguage;

  /// No description provided for @targetLanguage.
  ///
  /// In zh, this message translates to:
  /// **'目标语言'**
  String get targetLanguage;

  /// No description provided for @autoDetect.
  ///
  /// In zh, this message translates to:
  /// **'自动检测'**
  String get autoDetect;

  /// No description provided for @english.
  ///
  /// In zh, this message translates to:
  /// **'英语'**
  String get english;

  /// No description provided for @japanese.
  ///
  /// In zh, this message translates to:
  /// **'日语'**
  String get japanese;

  /// No description provided for @korean.
  ///
  /// In zh, this message translates to:
  /// **'韩语'**
  String get korean;

  /// No description provided for @simplifiedChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @traditionalChinese.
  ///
  /// In zh, this message translates to:
  /// **'繁体中文'**
  String get traditionalChinese;

  /// No description provided for @russian.
  ///
  /// In zh, this message translates to:
  /// **'俄语'**
  String get russian;

  /// No description provided for @french.
  ///
  /// In zh, this message translates to:
  /// **'法语'**
  String get french;

  /// No description provided for @german.
  ///
  /// In zh, this message translates to:
  /// **'德语'**
  String get german;

  /// No description provided for @streamOutput.
  ///
  /// In zh, this message translates to:
  /// **'流式输出'**
  String get streamOutput;

  /// No description provided for @enableSearch.
  ///
  /// In zh, this message translates to:
  /// **'启用搜索'**
  String get enableSearch;

  /// No description provided for @searchEngine.
  ///
  /// In zh, this message translates to:
  /// **'搜索引擎'**
  String get searchEngine;

  /// No description provided for @clearContext.
  ///
  /// In zh, this message translates to:
  /// **'清空上下文'**
  String get clearContext;

  /// No description provided for @clearContextConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空当前对话的历史记录吗？此操作不可撤销。'**
  String get clearContextConfirm;

  /// No description provided for @streamEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启流式传输'**
  String get streamEnabled;

  /// No description provided for @streamDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已关闭流式传输'**
  String get streamDisabled;

  /// No description provided for @searchEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启联网搜索'**
  String get searchEnabled;

  /// No description provided for @searchDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已关闭联网搜索'**
  String get searchDisabled;

  /// No description provided for @desktopInputHint.
  ///
  /// In zh, this message translates to:
  /// **'随便输入点什么吧 (Enter 换行，Ctrl + Enter 发送，@ 切换模型)'**
  String get desktopInputHint;

  /// No description provided for @mobileInputHint.
  ///
  /// In zh, this message translates to:
  /// **'随便输入点什么吧'**
  String get mobileInputHint;

  /// No description provided for @topics.
  ///
  /// In zh, this message translates to:
  /// **'话题分组'**
  String get topics;

  /// No description provided for @createTopic.
  ///
  /// In zh, this message translates to:
  /// **'新建分组'**
  String get createTopic;

  /// No description provided for @editTopic.
  ///
  /// In zh, this message translates to:
  /// **'编辑分组'**
  String get editTopic;

  /// No description provided for @deleteTopic.
  ///
  /// In zh, this message translates to:
  /// **'删除分组'**
  String get deleteTopic;

  /// No description provided for @deleteTopicConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此分组吗？该分组下的会话将移至默认分组。'**
  String get deleteTopicConfirm;

  /// No description provided for @topicNamePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'分组名称'**
  String get topicNamePlaceholder;

  /// No description provided for @allChats.
  ///
  /// In zh, this message translates to:
  /// **'所有'**
  String get allChats;

  /// No description provided for @thinkingConfig.
  ///
  /// In zh, this message translates to:
  /// **'思考配置'**
  String get thinkingConfig;

  /// No description provided for @enableThinking.
  ///
  /// In zh, this message translates to:
  /// **'启用思考'**
  String get enableThinking;

  /// No description provided for @thinkingBudget.
  ///
  /// In zh, this message translates to:
  /// **'思考预算'**
  String get thinkingBudget;

  /// No description provided for @thinkingBudgetHint.
  ///
  /// In zh, this message translates to:
  /// **'输入数字 (如 1024) 或级别 (如 low, high)'**
  String get thinkingBudgetHint;

  /// No description provided for @transmissionMode.
  ///
  /// In zh, this message translates to:
  /// **'传输模式'**
  String get transmissionMode;

  /// No description provided for @modeAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动智能'**
  String get modeAuto;

  /// No description provided for @modeExtraBody.
  ///
  /// In zh, this message translates to:
  /// **'Extra Body (Google)'**
  String get modeExtraBody;

  /// No description provided for @modeReasoningEffort.
  ///
  /// In zh, this message translates to:
  /// **'Reasoning Effort (OpenAI)'**
  String get modeReasoningEffort;

  /// No description provided for @providers.
  ///
  /// In zh, this message translates to:
  /// **'服务商'**
  String get providers;

  /// No description provided for @promptPresets.
  ///
  /// In zh, this message translates to:
  /// **'Prompt 预设'**
  String get promptPresets;

  /// No description provided for @defaultPreset.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get defaultPreset;

  /// No description provided for @newPreset.
  ///
  /// In zh, this message translates to:
  /// **'新建自定义预设'**
  String get newPreset;

  /// No description provided for @editPreset.
  ///
  /// In zh, this message translates to:
  /// **'编辑预设'**
  String get editPreset;

  /// No description provided for @managePresets.
  ///
  /// In zh, this message translates to:
  /// **'管理预设'**
  String get managePresets;

  /// No description provided for @presetName.
  ///
  /// In zh, this message translates to:
  /// **'预设名称'**
  String get presetName;

  /// No description provided for @presetDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述 (可选)'**
  String get presetDescription;

  /// No description provided for @systemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'系统提示词'**
  String get systemPrompt;

  /// No description provided for @savePreset.
  ///
  /// In zh, this message translates to:
  /// **'保存预设'**
  String get savePreset;

  /// No description provided for @selectPresetHint.
  ///
  /// In zh, this message translates to:
  /// **'选择左侧预设进行编辑，或新建预设。'**
  String get selectPresetHint;

  /// No description provided for @presetNamePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'例如：Python 专家'**
  String get presetNamePlaceholder;

  /// No description provided for @presetDescriptionPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'可选描述...'**
  String get presetDescriptionPlaceholder;

  /// No description provided for @systemPromptPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'在此输入系统提示词...'**
  String get systemPromptPlaceholder;

  /// No description provided for @noPresets.
  ///
  /// In zh, this message translates to:
  /// **'暂无预设'**
  String get noPresets;

  /// No description provided for @deletePreset.
  ///
  /// In zh, this message translates to:
  /// **'删除预设'**
  String get deletePreset;

  /// No description provided for @deletePresetConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除预设 \"{name}\" 吗？'**
  String deletePresetConfirmation(String name);

  /// No description provided for @fillRequiredFields.
  ///
  /// In zh, this message translates to:
  /// **'请填写所有必填字段'**
  String get fillRequiredFields;

  /// No description provided for @callTrend.
  ///
  /// In zh, this message translates to:
  /// **'调用趋势 (最近30天)'**
  String get callTrend;

  /// No description provided for @errorDistribution.
  ///
  /// In zh, this message translates to:
  /// **'错误分布'**
  String get errorDistribution;

  /// No description provided for @errorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'超时'**
  String get errorTimeout;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络错误'**
  String get errorNetwork;

  /// No description provided for @errorBadRequest.
  ///
  /// In zh, this message translates to:
  /// **'请求错误 (400)'**
  String get errorBadRequest;

  /// No description provided for @errorUnauthorized.
  ///
  /// In zh, this message translates to:
  /// **'鉴权失败 (401)'**
  String get errorUnauthorized;

  /// No description provided for @errorServerError.
  ///
  /// In zh, this message translates to:
  /// **'服务器错误 (5XX)'**
  String get errorServerError;

  /// No description provided for @errorRateLimit.
  ///
  /// In zh, this message translates to:
  /// **'限流 (429)'**
  String get errorRateLimit;

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'其他错误'**
  String get errorUnknown;

  /// No description provided for @cumulativeToken.
  ///
  /// In zh, this message translates to:
  /// **'累计Token'**
  String get cumulativeToken;

  /// No description provided for @bgDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get bgDefault;

  /// No description provided for @bgPureBlack.
  ///
  /// In zh, this message translates to:
  /// **'纯黑'**
  String get bgPureBlack;

  /// No description provided for @bgWarm.
  ///
  /// In zh, this message translates to:
  /// **'暖色'**
  String get bgWarm;

  /// No description provided for @bgCool.
  ///
  /// In zh, this message translates to:
  /// **'冷色'**
  String get bgCool;

  /// No description provided for @bgRose.
  ///
  /// In zh, this message translates to:
  /// **'玫瑰'**
  String get bgRose;

  /// No description provided for @bgLavender.
  ///
  /// In zh, this message translates to:
  /// **'薰衣草'**
  String get bgLavender;

  /// No description provided for @bgMint.
  ///
  /// In zh, this message translates to:
  /// **'薄荷'**
  String get bgMint;

  /// No description provided for @bgSky.
  ///
  /// In zh, this message translates to:
  /// **'天空'**
  String get bgSky;

  /// No description provided for @bgGray.
  ///
  /// In zh, this message translates to:
  /// **'高级灰'**
  String get bgGray;

  /// No description provided for @bgSunset.
  ///
  /// In zh, this message translates to:
  /// **'日落'**
  String get bgSunset;

  /// No description provided for @bgOcean.
  ///
  /// In zh, this message translates to:
  /// **'海洋'**
  String get bgOcean;

  /// No description provided for @bgForest.
  ///
  /// In zh, this message translates to:
  /// **'森林'**
  String get bgForest;

  /// No description provided for @bgDream.
  ///
  /// In zh, this message translates to:
  /// **'梦境'**
  String get bgDream;

  /// No description provided for @bgAurora.
  ///
  /// In zh, this message translates to:
  /// **'极光'**
  String get bgAurora;

  /// No description provided for @bgVolcano.
  ///
  /// In zh, this message translates to:
  /// **'火山'**
  String get bgVolcano;

  /// No description provided for @bgMidnight.
  ///
  /// In zh, this message translates to:
  /// **'午夜'**
  String get bgMidnight;

  /// No description provided for @bgDawn.
  ///
  /// In zh, this message translates to:
  /// **'晨曦'**
  String get bgDawn;

  /// No description provided for @bgNeon.
  ///
  /// In zh, this message translates to:
  /// **'霓虹'**
  String get bgNeon;

  /// No description provided for @bgBlossom.
  ///
  /// In zh, this message translates to:
  /// **'樱花'**
  String get bgBlossom;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @accentColor.
  ///
  /// In zh, this message translates to:
  /// **'强调色'**
  String get accentColor;

  /// No description provided for @backgroundStyle.
  ///
  /// In zh, this message translates to:
  /// **'背景风格'**
  String get backgroundStyle;

  /// No description provided for @renameSession.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get renameSession;

  /// No description provided for @renameSessionHint.
  ///
  /// In zh, this message translates to:
  /// **'输入新名称'**
  String get renameSessionHint;

  /// No description provided for @providerColor.
  ///
  /// In zh, this message translates to:
  /// **'颜色 (Hex)'**
  String get providerColor;

  /// No description provided for @apiKeyPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'sk-xxxxxxxx'**
  String get apiKeyPlaceholder;

  /// No description provided for @baseUrlPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'https://api.openai.com/v1'**
  String get baseUrlPlaceholder;

  /// No description provided for @apiKeys.
  ///
  /// In zh, this message translates to:
  /// **'API Keys'**
  String get apiKeys;

  /// No description provided for @addApiKey.
  ///
  /// In zh, this message translates to:
  /// **'添加 Key'**
  String get addApiKey;

  /// No description provided for @autoRotateKeys.
  ///
  /// In zh, this message translates to:
  /// **'自动轮询'**
  String get autoRotateKeys;

  /// No description provided for @generationConfig.
  ///
  /// In zh, this message translates to:
  /// **'生成配置'**
  String get generationConfig;

  /// No description provided for @customParams.
  ///
  /// In zh, this message translates to:
  /// **'自定义参数'**
  String get customParams;

  /// No description provided for @temperature.
  ///
  /// In zh, this message translates to:
  /// **'温度'**
  String get temperature;

  /// No description provided for @temperatureHint.
  ///
  /// In zh, this message translates to:
  /// **'0.0 - 2.0，越低越聚焦'**
  String get temperatureHint;

  /// No description provided for @maxTokens.
  ///
  /// In zh, this message translates to:
  /// **'最大Token数'**
  String get maxTokens;

  /// No description provided for @maxTokensHint.
  ///
  /// In zh, this message translates to:
  /// **'最大输出 Token 数（如 4096）'**
  String get maxTokensHint;

  /// No description provided for @contextLength.
  ///
  /// In zh, this message translates to:
  /// **'上下文长度'**
  String get contextLength;

  /// No description provided for @contextLengthHint.
  ///
  /// In zh, this message translates to:
  /// **'上下文中包含的消息数量'**
  String get contextLengthHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
