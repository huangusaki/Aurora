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
  /// **'思考中...'**
  String get deepThinking;

  /// No description provided for @deepThoughtFinished.
  ///
  /// In zh, this message translates to:
  /// **'已思考 (用时 {duration} 秒)'**
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
  /// **'已完成'**
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
  /// **'外观设置'**
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

  /// No description provided for @agentSkills.
  ///
  /// In zh, this message translates to:
  /// **'技能'**
  String get agentSkills;

  /// No description provided for @executionModel.
  ///
  /// In zh, this message translates to:
  /// **'执行模型'**
  String get executionModel;

  /// No description provided for @defaultModelSameAsChat.
  ///
  /// In zh, this message translates to:
  /// **'默认 (跟随主对话)'**
  String get defaultModelSameAsChat;

  /// No description provided for @agentSkillsDescription.
  ///
  /// In zh, this message translates to:
  /// **'插件从应用根目录下的 \'./skills\' 文件夹加载。创建一个包含 \'SKILL.md\' 文件的文件夹即可添加新插件。'**
  String get agentSkillsDescription;

  /// No description provided for @noSkillsFound.
  ///
  /// In zh, this message translates to:
  /// **'未在 ./skills 目录下发现插件'**
  String get noSkillsFound;

  /// No description provided for @openSkillsFolder.
  ///
  /// In zh, this message translates to:
  /// **'打开插件目录'**
  String get openSkillsFolder;

  /// No description provided for @instructions.
  ///
  /// In zh, this message translates to:
  /// **'指令/说明'**
  String get instructions;

  /// No description provided for @tools.
  ///
  /// In zh, this message translates to:
  /// **'工具定义'**
  String get tools;

  /// No description provided for @newSkill.
  ///
  /// In zh, this message translates to:
  /// **'新建插件'**
  String get newSkill;

  /// No description provided for @editSkill.
  ///
  /// In zh, this message translates to:
  /// **'编辑插件'**
  String get editSkill;

  /// No description provided for @deleteSkill.
  ///
  /// In zh, this message translates to:
  /// **'删除插件'**
  String get deleteSkill;

  /// No description provided for @deleteSkillTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get deleteSkillTitle;

  /// No description provided for @deleteSkillConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这个插件吗？此操作无法撤销。'**
  String get deleteSkillConfirm;

  /// No description provided for @updateSkill.
  ///
  /// In zh, this message translates to:
  /// **'更新插件'**
  String get updateSkill;

  /// No description provided for @saveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get saveSuccess;

  /// No description provided for @skillName.
  ///
  /// In zh, this message translates to:
  /// **'插件文件夹名称'**
  String get skillName;

  /// No description provided for @skillNameHint.
  ///
  /// In zh, this message translates to:
  /// **'输入文件夹名称 (如 translation_helper)'**
  String get skillNameHint;

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

  /// No description provided for @enableAll.
  ///
  /// In zh, this message translates to:
  /// **'全部启用'**
  String get enableAll;

  /// No description provided for @disableAll.
  ///
  /// In zh, this message translates to:
  /// **'全部禁用'**
  String get disableAll;

  /// No description provided for @modelConfig.
  ///
  /// In zh, this message translates to:
  /// **'模型配置'**
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

  /// No description provided for @backup.
  ///
  /// In zh, this message translates to:
  /// **'备份'**
  String get backup;

  /// No description provided for @backupAndRestore.
  ///
  /// In zh, this message translates to:
  /// **'备份与恢复'**
  String get backupAndRestore;

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
  /// **'平均: {duration}s'**
  String averageDuration(String duration);

  /// No description provided for @averageFirstToken.
  ///
  /// In zh, this message translates to:
  /// **'TTFT: {duration}s'**
  String averageFirstToken(String duration);

  /// No description provided for @totalTokensCount.
  ///
  /// In zh, this message translates to:
  /// **'累计: {count} Tokens'**
  String totalTokensCount(int count);

  /// No description provided for @tokensPerSecond.
  ///
  /// In zh, this message translates to:
  /// **'Token/s: {tps}'**
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

  /// No description provided for @studio.
  ///
  /// In zh, this message translates to:
  /// **'工坊'**
  String get studio;

  /// No description provided for @novelWriting.
  ///
  /// In zh, this message translates to:
  /// **'小说写作'**
  String get novelWriting;

  /// No description provided for @taskOrchestration.
  ///
  /// In zh, this message translates to:
  /// **'任务编排'**
  String get taskOrchestration;

  /// No description provided for @createTask.
  ///
  /// In zh, this message translates to:
  /// **'创建任务'**
  String get createTask;

  /// No description provided for @pendingTasks.
  ///
  /// In zh, this message translates to:
  /// **'待完成任务'**
  String get pendingTasks;

  /// No description provided for @taskDescription.
  ///
  /// In zh, this message translates to:
  /// **'任务描述'**
  String get taskDescription;

  /// No description provided for @decompose.
  ///
  /// In zh, this message translates to:
  /// **'拆解任务'**
  String get decompose;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resume;

  /// No description provided for @start.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get start;

  /// No description provided for @novelName.
  ///
  /// In zh, this message translates to:
  /// **'小说名称'**
  String get novelName;

  /// No description provided for @chapterTitle.
  ///
  /// In zh, this message translates to:
  /// **'章节标题'**
  String get chapterTitle;

  /// No description provided for @chapters.
  ///
  /// In zh, this message translates to:
  /// **'章节列表'**
  String get chapters;

  /// No description provided for @novelStructure.
  ///
  /// In zh, this message translates to:
  /// **'小说结构'**
  String get novelStructure;

  /// No description provided for @reviewModel.
  ///
  /// In zh, this message translates to:
  /// **'审查'**
  String get reviewModel;

  /// No description provided for @writerModel.
  ///
  /// In zh, this message translates to:
  /// **'写作模型'**
  String get writerModel;

  /// No description provided for @decomposeModel.
  ///
  /// In zh, this message translates to:
  /// **'拆解模型'**
  String get decomposeModel;

  /// No description provided for @project.
  ///
  /// In zh, this message translates to:
  /// **'项目'**
  String get project;

  /// No description provided for @selectProject.
  ///
  /// In zh, this message translates to:
  /// **'选择项目'**
  String get selectProject;

  /// No description provided for @createProject.
  ///
  /// In zh, this message translates to:
  /// **'新建项目'**
  String get createProject;

  /// No description provided for @deleteProject.
  ///
  /// In zh, this message translates to:
  /// **'删除项目'**
  String get deleteProject;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这个项目吗？'**
  String get deleteProjectConfirm;

  /// No description provided for @deleteChapterConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这个章节吗？'**
  String get deleteChapterConfirm;

  /// No description provided for @writing.
  ///
  /// In zh, this message translates to:
  /// **'写作'**
  String get writing;

  /// No description provided for @context.
  ///
  /// In zh, this message translates to:
  /// **'设定'**
  String get context;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// No description provided for @stopTask.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stopTask;

  /// No description provided for @startWriting.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get startWriting;

  /// No description provided for @outlineSettings.
  ///
  /// In zh, this message translates to:
  /// **'大纲与设定'**
  String get outlineSettings;

  /// No description provided for @clearOutline.
  ///
  /// In zh, this message translates to:
  /// **'清除大纲'**
  String get clearOutline;

  /// No description provided for @startConceiving.
  ///
  /// In zh, this message translates to:
  /// **'开始构思你的故事'**
  String get startConceiving;

  /// No description provided for @outlineHint.
  ///
  /// In zh, this message translates to:
  /// **'在下方输入你的故事构想，AI 将为你生成详细大纲。'**
  String get outlineHint;

  /// No description provided for @outlinePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'例如：写一本关于赛博朋克世界的侦探小说，主角是...'**
  String get outlinePlaceholder;

  /// No description provided for @generateOutline.
  ///
  /// In zh, this message translates to:
  /// **'生成大纲'**
  String get generateOutline;

  /// No description provided for @editOutlinePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'在此处编辑大纲...'**
  String get editOutlinePlaceholder;

  /// No description provided for @generateChapters.
  ///
  /// In zh, this message translates to:
  /// **'生成章节列表'**
  String get generateChapters;

  /// No description provided for @regenerateChapters.
  ///
  /// In zh, this message translates to:
  /// **'重新生成章节'**
  String get regenerateChapters;

  /// No description provided for @clearChaptersWarning.
  ///
  /// In zh, this message translates to:
  /// **'这将清除现有的所有章节和写作进度。\n建议在操作前备份重要内容。\n\n确定要继续吗？'**
  String get clearChaptersWarning;

  /// No description provided for @clearAndRegenerate.
  ///
  /// In zh, this message translates to:
  /// **'清除并重新生成'**
  String get clearAndRegenerate;

  /// No description provided for @chaptersAndTasks.
  ///
  /// In zh, this message translates to:
  /// **'章节与任务'**
  String get chaptersAndTasks;

  /// No description provided for @addChapter.
  ///
  /// In zh, this message translates to:
  /// **'添加自定义章节'**
  String get addChapter;

  /// No description provided for @noTasks.
  ///
  /// In zh, this message translates to:
  /// **'暂无任务'**
  String get noTasks;

  /// No description provided for @taskDetails.
  ///
  /// In zh, this message translates to:
  /// **'任务详情'**
  String get taskDetails;

  /// No description provided for @selectTaskToView.
  ///
  /// In zh, this message translates to:
  /// **'选择一个任务查看详情'**
  String get selectTaskToView;

  /// No description provided for @taskRequirement.
  ///
  /// In zh, this message translates to:
  /// **'任务要求'**
  String get taskRequirement;

  /// No description provided for @generatedContent.
  ///
  /// In zh, this message translates to:
  /// **'生成内容'**
  String get generatedContent;

  /// No description provided for @waitingForGeneration.
  ///
  /// In zh, this message translates to:
  /// **'等待生成...'**
  String get waitingForGeneration;

  /// No description provided for @worldSettings.
  ///
  /// In zh, this message translates to:
  /// **'世界设定'**
  String get worldSettings;

  /// No description provided for @autoIncludeHint.
  ///
  /// In zh, this message translates to:
  /// **'勾选的分类会在写作时自动携带'**
  String get autoIncludeHint;

  /// No description provided for @worldRules.
  ///
  /// In zh, this message translates to:
  /// **'世界规则'**
  String get worldRules;

  /// No description provided for @characterSettings.
  ///
  /// In zh, this message translates to:
  /// **'人物设定'**
  String get characterSettings;

  /// No description provided for @relationships.
  ///
  /// In zh, this message translates to:
  /// **'人物关系'**
  String get relationships;

  /// No description provided for @locations.
  ///
  /// In zh, this message translates to:
  /// **'场景地点'**
  String get locations;

  /// No description provided for @foreshadowing.
  ///
  /// In zh, this message translates to:
  /// **'伏笔/线索'**
  String get foreshadowing;

  /// No description provided for @noDataYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据（写作后自动提取）'**
  String get noDataYet;

  /// No description provided for @pleaseSelectChapter.
  ///
  /// In zh, this message translates to:
  /// **'请先选择一个章节'**
  String get pleaseSelectChapter;

  /// No description provided for @copyFullText.
  ///
  /// In zh, this message translates to:
  /// **'复制全文'**
  String get copyFullText;

  /// No description provided for @unknownChapter.
  ///
  /// In zh, this message translates to:
  /// **'未知章节'**
  String get unknownChapter;

  /// No description provided for @noContentYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无内容'**
  String get noContentYet;

  /// No description provided for @allTasksPending.
  ///
  /// In zh, this message translates to:
  /// **'按顺序执行所有待办任务'**
  String get allTasksPending;

  /// No description provided for @noPendingTasks.
  ///
  /// In zh, this message translates to:
  /// **'没有可执行的待办任务'**
  String get noPendingTasks;

  /// No description provided for @executeTask.
  ///
  /// In zh, this message translates to:
  /// **'执行任务'**
  String get executeTask;

  /// No description provided for @reviewFeedback.
  ///
  /// In zh, this message translates to:
  /// **'审查反馈'**
  String get reviewFeedback;

  /// No description provided for @reject.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In zh, this message translates to:
  /// **'批准'**
  String get approve;

  /// No description provided for @regenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get regenerate;

  /// No description provided for @pending.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get pending;

  /// No description provided for @running.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get running;

  /// No description provided for @paused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get paused;

  /// No description provided for @reviewing.
  ///
  /// In zh, this message translates to:
  /// **'审查中'**
  String get reviewing;

  /// No description provided for @decomposing.
  ///
  /// In zh, this message translates to:
  /// **'拆解中'**
  String get decomposing;

  /// No description provided for @noProjectSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择项目'**
  String get noProjectSelected;

  /// No description provided for @createYourFirstProject.
  ///
  /// In zh, this message translates to:
  /// **'开始你的创作吧'**
  String get createYourFirstProject;

  /// No description provided for @createProjectDescription.
  ///
  /// In zh, this message translates to:
  /// **'新建一个项目来开始编写你的故事大纲和章节。'**
  String get createProjectDescription;

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

  /// No description provided for @searchResultsWithEngine.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个搜索结果 ({engine})'**
  String searchResultsWithEngine(int count, String engine);

  /// No description provided for @citationsCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个引用内容'**
  String citationsCount(int count);

  /// No description provided for @agentResponse.
  ///
  /// In zh, this message translates to:
  /// **'智能助手响应'**
  String get agentResponse;

  /// No description provided for @agentOutput.
  ///
  /// In zh, this message translates to:
  /// **'智能助手输出'**
  String get agentOutput;

  /// No description provided for @terminalError.
  ///
  /// In zh, this message translates to:
  /// **'终端错误 (错误码 {code})'**
  String terminalError(int code);

  /// No description provided for @terminalOutput.
  ///
  /// In zh, this message translates to:
  /// **'终端输出'**
  String get terminalOutput;

  /// No description provided for @noOutput.
  ///
  /// In zh, this message translates to:
  /// **'[无输出]'**
  String get noOutput;

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
  /// **'随便输入点什么吧 (Enter 换行，Ctrl + Enter 发送，@ 切换模型，/ 切换 Prompt 预设)'**
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
  /// **'预设管理'**
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

  /// No description provided for @studioDescription.
  ///
  /// In zh, this message translates to:
  /// **'在这里配置和编排你的智能助手'**
  String get studioDescription;

  /// No description provided for @cloudSync.
  ///
  /// In zh, this message translates to:
  /// **'数据云同步'**
  String get cloudSync;

  /// No description provided for @webdavConfig.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 配置'**
  String get webdavConfig;

  /// No description provided for @webdavUrl.
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 地址 (URL)'**
  String get webdavUrl;

  /// No description provided for @webdavUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'https://dav.jianguoyun.com/dav/'**
  String get webdavUrlHint;

  /// No description provided for @username.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In zh, this message translates to:
  /// **'email@example.com'**
  String get usernameHint;

  /// No description provided for @passwordOrToken.
  ///
  /// In zh, this message translates to:
  /// **'密码 / 应用授权码'**
  String get passwordOrToken;

  /// No description provided for @testConnection.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get testConnection;

  /// No description provided for @backupNow.
  ///
  /// In zh, this message translates to:
  /// **'备份'**
  String get backupNow;

  /// No description provided for @cloudBackupList.
  ///
  /// In zh, this message translates to:
  /// **'云端备份列表'**
  String get cloudBackupList;

  /// No description provided for @noBackupsOrNotConnected.
  ///
  /// In zh, this message translates to:
  /// **'暂无备份或未连接'**
  String get noBackupsOrNotConnected;

  /// No description provided for @restore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get restore;

  /// No description provided for @confirmRestore.
  ///
  /// In zh, this message translates to:
  /// **'确认恢复?'**
  String get confirmRestore;

  /// No description provided for @restoreWarning.
  ///
  /// In zh, this message translates to:
  /// **'恢复操作将尝试合并云端数据到本地。如果存在冲突可能会更新本地数据。建议先备份当前数据。'**
  String get restoreWarning;

  /// No description provided for @confirmRestoreButton.
  ///
  /// In zh, this message translates to:
  /// **'确定恢复'**
  String get confirmRestoreButton;

  /// No description provided for @connectionSuccess.
  ///
  /// In zh, this message translates to:
  /// **'连接成功'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败: 请检查配置'**
  String get connectionFailed;

  /// No description provided for @connectionError.
  ///
  /// In zh, this message translates to:
  /// **'连接异常'**
  String get connectionError;

  /// No description provided for @backupSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份上传成功'**
  String get backupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In zh, this message translates to:
  /// **'备份失败'**
  String get backupFailed;

  /// No description provided for @restoreSuccess.
  ///
  /// In zh, this message translates to:
  /// **'数据恢复成功'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'恢复失败'**
  String get restoreFailed;

  /// No description provided for @fetchBackupListFailed.
  ///
  /// In zh, this message translates to:
  /// **'获取备份列表失败'**
  String get fetchBackupListFailed;

  /// No description provided for @exportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'导出成功'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败'**
  String get exportFailed;

  /// No description provided for @importSuccess.
  ///
  /// In zh, this message translates to:
  /// **'导入成功'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败'**
  String get importFailed;

  /// No description provided for @clearDataConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认清空所有数据?'**
  String get clearDataConfirmTitle;

  /// No description provided for @clearDataConfirmContent.
  ///
  /// In zh, this message translates to:
  /// **'此操作将永久删除所有会话、消息和话题数据，且无法撤销。建议先导出备份。'**
  String get clearDataConfirmContent;

  /// No description provided for @clearDataSuccess.
  ///
  /// In zh, this message translates to:
  /// **'数据已清空'**
  String get clearDataSuccess;

  /// No description provided for @clearDataFailed.
  ///
  /// In zh, this message translates to:
  /// **'清空数据失败'**
  String get clearDataFailed;

  /// No description provided for @novelWritingDescription.
  ///
  /// In zh, this message translates to:
  /// **'配置写作、审查、大纲模型'**
  String get novelWritingDescription;

  /// No description provided for @schedulePlanning.
  ///
  /// In zh, this message translates to:
  /// **'日程规划'**
  String get schedulePlanning;

  /// No description provided for @schedulePlanningDescription.
  ///
  /// In zh, this message translates to:
  /// **'规划和管理你的创作日程'**
  String get schedulePlanningDescription;

  /// No description provided for @imageManagement.
  ///
  /// In zh, this message translates to:
  /// **'图片管理'**
  String get imageManagement;

  /// No description provided for @imageManagementDescription.
  ///
  /// In zh, this message translates to:
  /// **'整理和管理项目图片素材'**
  String get imageManagementDescription;

  /// No description provided for @comingSoon.
  ///
  /// In zh, this message translates to:
  /// **'即将推出'**
  String get comingSoon;

  /// No description provided for @generating.
  ///
  /// In zh, this message translates to:
  /// **'生成中...'**
  String get generating;

  /// No description provided for @branch.
  ///
  /// In zh, this message translates to:
  /// **'分支'**
  String get branch;

  /// No description provided for @trayShow.
  ///
  /// In zh, this message translates to:
  /// **'显示程序'**
  String get trayShow;

  /// No description provided for @trayExit.
  ///
  /// In zh, this message translates to:
  /// **'退出程序'**
  String get trayExit;

  /// No description provided for @confirmClose.
  ///
  /// In zh, this message translates to:
  /// **'确认关闭'**
  String get confirmClose;

  /// No description provided for @minimizeToTray.
  ///
  /// In zh, this message translates to:
  /// **'是否最小化到系统托盘？'**
  String get minimizeToTray;

  /// No description provided for @minimize.
  ///
  /// In zh, this message translates to:
  /// **'最小化'**
  String get minimize;

  /// No description provided for @exit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exit;

  /// No description provided for @rememberChoice.
  ///
  /// In zh, this message translates to:
  /// **'记住我的选择'**
  String get rememberChoice;

  /// No description provided for @closeBehavior.
  ///
  /// In zh, this message translates to:
  /// **'关闭行为'**
  String get closeBehavior;

  /// No description provided for @askEveryTime.
  ///
  /// In zh, this message translates to:
  /// **'每次询问'**
  String get askEveryTime;

  /// No description provided for @minimizeToTrayOption.
  ///
  /// In zh, this message translates to:
  /// **'最小化到托盘'**
  String get minimizeToTrayOption;

  /// No description provided for @exitApplicationOption.
  ///
  /// In zh, this message translates to:
  /// **'直接退出程序'**
  String get exitApplicationOption;

  /// No description provided for @novelPreset.
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get novelPreset;

  /// No description provided for @selectPreset.
  ///
  /// In zh, this message translates to:
  /// **'选择预设'**
  String get selectPreset;

  /// No description provided for @noCustomPresets.
  ///
  /// In zh, this message translates to:
  /// **'暂无自定义预设'**
  String get noCustomPresets;

  /// No description provided for @systemDefault.
  ///
  /// In zh, this message translates to:
  /// **'系统默认'**
  String get systemDefault;

  /// No description provided for @systemDefaultRestored.
  ///
  /// In zh, this message translates to:
  /// **'已恢复系统默认预设'**
  String get systemDefaultRestored;

  /// No description provided for @presetLoaded.
  ///
  /// In zh, this message translates to:
  /// **'已加载预设: {name}'**
  String presetLoaded(String name);

  /// No description provided for @newNovelPreset.
  ///
  /// In zh, this message translates to:
  /// **'新建预设'**
  String get newNovelPreset;

  /// No description provided for @savePresetHint.
  ///
  /// In zh, this message translates to:
  /// **'将保存当前所有角色的提示词配置。'**
  String get savePresetHint;

  /// No description provided for @presetSaved.
  ///
  /// In zh, this message translates to:
  /// **'预设 \"{name}\" 已保存'**
  String presetSaved(String name);

  /// No description provided for @outline.
  ///
  /// In zh, this message translates to:
  /// **'大纲'**
  String get outline;

  /// No description provided for @outlineModel.
  ///
  /// In zh, this message translates to:
  /// **'大纲模型'**
  String get outlineModel;

  /// No description provided for @savePresetOverrideHint.
  ///
  /// In zh, this message translates to:
  /// **'保存当前配置覆盖选中的预设'**
  String get savePresetOverrideHint;

  /// No description provided for @selectiveBackup.
  ///
  /// In zh, this message translates to:
  /// **'可选备份'**
  String get selectiveBackup;

  /// No description provided for @backupChatHistory.
  ///
  /// In zh, this message translates to:
  /// **'聊天记录'**
  String get backupChatHistory;

  /// No description provided for @backupChatPresets.
  ///
  /// In zh, this message translates to:
  /// **'Prompt 预设'**
  String get backupChatPresets;

  /// No description provided for @backupProviderConfigs.
  ///
  /// In zh, this message translates to:
  /// **'模型供应商配置'**
  String get backupProviderConfigs;

  /// No description provided for @backupStudioContent.
  ///
  /// In zh, this message translates to:
  /// **'Studio 内容'**
  String get backupStudioContent;

  /// No description provided for @noOptionsSelected.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一项进行备份'**
  String get noOptionsSelected;
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
