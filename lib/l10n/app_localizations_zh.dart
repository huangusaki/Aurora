// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Aurora';

  @override
  String get newChat => '新对话';

  @override
  String get searchChatHistory => '搜索聊天记录';

  @override
  String get send => '发送';

  @override
  String get retry => '重试';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get save => '保存';

  @override
  String get done => '完成';

  @override
  String get close => '关闭';

  @override
  String get history => '历史';

  @override
  String get modelNotSelected => '未选择模型';

  @override
  String get closeComparison => '关闭对照';

  @override
  String get bilingualComparison => '双语对照';

  @override
  String get clear => '清空';

  @override
  String get translating => '翻译中...';

  @override
  String get translationResultPlaceholder => '翻译结果将显示在这里';

  @override
  String get selectModel => '选择模型';

  @override
  String get switchModel => '切换模型';

  @override
  String get deepThinking => '思考中...';

  @override
  String deepThoughtFinished(String duration) {
    return '已思考 (用时 $duration 秒)';
  }

  @override
  String get thoughtChain => '思维链';

  @override
  String get camera => '相机';

  @override
  String get photos => '相册';

  @override
  String get userSettings => '用户设置';

  @override
  String get chatExperience => '对话体验';

  @override
  String get smartTopicGeneration => '智能话题生成';

  @override
  String get smartTopicDescription => '使用 LLM 自动总结作为话题标题';

  @override
  String get generationModel => '生成模型';

  @override
  String get notSelectedFallback => '未选择 (回退到截断)';

  @override
  String get userInfo => '用户信息';

  @override
  String get userName => '用户名称';

  @override
  String get userAvatar => '用户头像';

  @override
  String get assistantAvatar => '助理头像';

  @override
  String get globalConfig => '全局配置';

  @override
  String get excludedModels => '排除模型';

  @override
  String get excludedModelsHint => '全局配置在这些模型上不生效';

  @override
  String get enterModelNameHint => '输入模型名称并回车添加';

  @override
  String get clickToChangeAvatar => '点击更换头像';

  @override
  String get aiInfo => 'AI 信息';

  @override
  String get aiName => 'AI 名称';

  @override
  String get aiAvatar => 'AI 头像';

  @override
  String get pleaseEnter => '请输入';

  @override
  String changeAvatarTitle(String target) {
    return '更换$target头像';
  }

  @override
  String get removeAvatar => '移除头像';

  @override
  String permissionRequired(String name) {
    return '需要$name权限';
  }

  @override
  String permissionContent(String name) {
    return '请在设置中允许应用访问$name，以便拍摄头像。';
  }

  @override
  String get goToSettings => '去设置';

  @override
  String get selectGenerationModel => '选择话题生成模型';

  @override
  String get pickImageFailed => '选择图片失败';

  @override
  String get textTranslation => '翻译';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get sourceText => '原文';

  @override
  String get targetText => '译文';

  @override
  String get enterTextToTranslate => '在此输入要翻译的文本...';

  @override
  String get translateButton => '翻译';

  @override
  String get compareMode => '双语对照';

  @override
  String get enableCompare => '开启双语对照';

  @override
  String get disableCompare => '关闭双语对照';

  @override
  String get translationPlaceholder => '翻译结果将显示在这里';

  @override
  String get sessionDetails => '会话详情';

  @override
  String get selectOrNewTopic => '请选择或新建一个话题';

  @override
  String get startNewChat => '新对话';

  @override
  String get edit => '编辑';

  @override
  String get add => '添加';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get loading => '加载中';

  @override
  String get error => '错误';

  @override
  String get success => '已完成';

  @override
  String get failed => '失败';

  @override
  String get settings => '设置';

  @override
  String get modelProvider => '模型提供';

  @override
  String get chatSettings => '对话设置';

  @override
  String get displaySettings => '外观设置';

  @override
  String get dataSettings => '数据设置';

  @override
  String get usageStats => '数据统计';

  @override
  String get agentSkills => '技能';

  @override
  String get executionModel => '执行模型';

  @override
  String get defaultModelSameAsChat => '默认 (跟随主对话)';

  @override
  String get agentSkillsDescription =>
      '插件从应用根目录下的 \'./skills\' 文件夹加载。创建一个包含 \'SKILL.md\' 文件的文件夹即可添加新插件。';

  @override
  String get noSkillsFound => '未在 ./skills 目录下发现插件';

  @override
  String get openSkillsFolder => '打开插件目录';

  @override
  String get instructions => '指令/说明';

  @override
  String get tools => '工具定义';

  @override
  String get newSkill => '新建插件';

  @override
  String get editSkill => '编辑插件';

  @override
  String get deleteSkill => '删除插件';

  @override
  String get deleteSkillTitle => '确认删除';

  @override
  String get deleteSkillConfirm => '确定要删除这个插件吗？此操作无法撤销。';

  @override
  String get updateSkill => '更新插件';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get skillName => '插件文件夹名称';

  @override
  String get skillNameHint => '输入文件夹名称 (如 translation_helper)';

  @override
  String get providerName => '供应商名称';

  @override
  String get currentProvider => '当前供应商';

  @override
  String get selectProvider => '选择供应商';

  @override
  String get addProvider => '添加供应商';

  @override
  String get deleteProvider => '删除供应商';

  @override
  String get deleteProviderConfirm => '确定要删除此供应商配置吗？此操作无法撤销。';

  @override
  String get renameProvider => '重命名供应商';

  @override
  String get enterProviderName => '请输入供应商名称';

  @override
  String get notConfigured => '未配置';

  @override
  String get noModelSelected => '未选择模型';

  @override
  String get enabledStatus => '启用状态';

  @override
  String get availableModels => '可用模型';

  @override
  String get refreshList => '刷新列表';

  @override
  String get fetchModelList => '获取模型列表';

  @override
  String get noModelsData => '暂无模型数据，请配置后点击获取';

  @override
  String get noModelsFetch => '暂无模型，请点击右上角获取';

  @override
  String get enableAll => '全部启用';

  @override
  String get disableAll => '全部禁用';

  @override
  String get modelConfig => '模型配置';

  @override
  String get configureModelParams => '为该模型配置专属参数';

  @override
  String get paramsHigherPriority => '这些参数优先级高于全局设置';

  @override
  String get noCustomParams => '暂无自定义参数';

  @override
  String get addCustomParam => '添加自定义参数';

  @override
  String get editParam => '编辑参数';

  @override
  String get paramKey => '参数名 (Key)';

  @override
  String get paramValue => '值 (Value)';

  @override
  String get paramType => '类型';

  @override
  String get typeText => '文本';

  @override
  String get typeNumber => '数字';

  @override
  String get typeBoolean => '布尔值';

  @override
  String get typeJson => 'JSON';

  @override
  String get formatError => '格式错误';

  @override
  String get selectTopicModel => '选择话题生成模型';

  @override
  String get noModelFallback => '未选择模型将回退到默认截断逻辑';

  @override
  String get selectImage => '选择图片';

  @override
  String get cropAvatar => '裁剪头像';

  @override
  String get themeAndUiComingSoon => '主题和 UI 样式设置 (即将推出)';

  @override
  String get language => '语言';

  @override
  String get languageChinese => '中文 (简体)';

  @override
  String get languageEnglish => 'English';

  @override
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get backup => '备份';

  @override
  String get backupAndRestore => '备份与恢复';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get totalCalls => '总调用';

  @override
  String get modelCallDistribution => '模型调用分布';

  @override
  String get clearStats => '清除数据';

  @override
  String get clearStatsConfirm => '确定要清除所有统计数据吗？此操作无法撤销。';

  @override
  String get clearData => '清除数据';

  @override
  String get clearDataConfirm => '确定要清除所有统计数据吗？';

  @override
  String get noUsageData => '暂无数据';

  @override
  String callsCount(int count) {
    return '$count 次调用';
  }

  @override
  String successCount(int count) {
    return '$count 成功';
  }

  @override
  String failureCount(int count) {
    return '$count 失败';
  }

  @override
  String averageDuration(String duration) {
    return '平均: ${duration}s';
  }

  @override
  String averageFirstToken(String duration) {
    return 'TTFT: ${duration}s';
  }

  @override
  String totalTokensCount(int count) {
    return '累计: $count Tokens';
  }

  @override
  String tokensPerSecond(String tps) {
    return 'Token/s: $tps';
  }

  @override
  String get mobileSettings => '移动端设置';

  @override
  String get mobileSettingsHint => '请使用顶部导航栏的设置按钮访问完整设置页面';

  @override
  String get user => '用户';

  @override
  String get translation => '翻译';

  @override
  String get theme => '主题';

  @override
  String get model => '模型';

  @override
  String get stats => '统计';

  @override
  String get about => '关于';

  @override
  String get studio => '工坊';

  @override
  String get novelWriting => '小说写作';

  @override
  String get taskOrchestration => '任务编排';

  @override
  String get createTask => '创建任务';

  @override
  String get pendingTasks => '待完成任务';

  @override
  String get taskDescription => '任务描述';

  @override
  String get decompose => '拆解任务';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get start => '开始';

  @override
  String get novelName => '小说名称';

  @override
  String get chapterTitle => '章节标题';

  @override
  String get chapters => '章节列表';

  @override
  String get novelStructure => '小说结构';

  @override
  String get reviewModel => '审查';

  @override
  String get writerModel => '写作模型';

  @override
  String get decomposeModel => '拆解模型';

  @override
  String get project => '项目';

  @override
  String get selectProject => '选择项目';

  @override
  String get createProject => '新建项目';

  @override
  String get deleteProject => '删除项目';

  @override
  String get deleteProjectConfirm => '确定要删除这个项目吗？';

  @override
  String get deleteChapterConfirm => '确定要删除这个章节吗？';

  @override
  String get writing => '写作';

  @override
  String get context => '设定';

  @override
  String get preview => '预览';

  @override
  String get stopTask => '停止';

  @override
  String get startWriting => '开始';

  @override
  String get outlineSettings => '大纲与设定';

  @override
  String get clearOutline => '清除大纲';

  @override
  String get startConceiving => '开始构思你的故事';

  @override
  String get outlineHint => '在下方输入你的故事构想，AI 将为你生成详细大纲。';

  @override
  String get outlinePlaceholder => '例如：写一本关于赛博朋克世界的侦探小说，主角是...';

  @override
  String get generateOutline => '生成大纲';

  @override
  String get editOutlinePlaceholder => '在此处编辑大纲...';

  @override
  String get generateChapters => '生成章节列表';

  @override
  String get regenerateChapters => '重新生成章节';

  @override
  String get clearChaptersWarning =>
      '这将清除现有的所有章节和写作进度。\n建议在操作前备份重要内容。\n\n确定要继续吗？';

  @override
  String get clearAndRegenerate => '清除并重新生成';

  @override
  String get chaptersAndTasks => '章节与任务';

  @override
  String get addChapter => '添加自定义章节';

  @override
  String get noTasks => '暂无任务';

  @override
  String get taskDetails => '任务详情';

  @override
  String get selectTaskToView => '选择一个任务查看详情';

  @override
  String get taskRequirement => '任务要求';

  @override
  String get generatedContent => '生成内容';

  @override
  String get waitingForGeneration => '等待生成...';

  @override
  String get worldSettings => '世界设定';

  @override
  String get autoIncludeHint => '勾选的分类会在写作时自动携带';

  @override
  String get worldRules => '世界规则';

  @override
  String get characterSettings => '人物设定';

  @override
  String get relationships => '人物关系';

  @override
  String get locations => '场景地点';

  @override
  String get foreshadowing => '伏笔/线索';

  @override
  String get noDataYet => '暂无数据（写作后自动提取）';

  @override
  String get pleaseSelectChapter => '请先选择一个章节';

  @override
  String get copyFullText => '复制全文';

  @override
  String get unknownChapter => '未知章节';

  @override
  String get noContentYet => '暂无内容';

  @override
  String get allTasksPending => '按顺序执行所有待办任务';

  @override
  String get noPendingTasks => '没有可执行的待办任务';

  @override
  String get executeTask => '执行任务';

  @override
  String get reviewFeedback => '审查反馈';

  @override
  String get reject => '拒绝';

  @override
  String get approve => '批准';

  @override
  String get regenerate => '重新生成';

  @override
  String get pending => '待处理';

  @override
  String get running => '进行中';

  @override
  String get paused => '已暂停';

  @override
  String get reviewing => '审查中';

  @override
  String get decomposing => '拆解中';

  @override
  String get noProjectSelected => '未选择项目';

  @override
  String get createYourFirstProject => '开始你的创作吧';

  @override
  String get createProjectDescription => '新建一个项目来开始编写你的故事大纲和章节。';

  @override
  String get aboutAurora => '关于 Aurora';

  @override
  String get crossPlatformLlmClient => '一个跨平台 LLM 客户端';

  @override
  String get githubProject => 'GitHub 项目';

  @override
  String get takePhoto => '拍照';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get selectFile => '选择文件';

  @override
  String get stopGenerating => '停止生成';

  @override
  String get copyCode => '复制代码';

  @override
  String get codeCopied => '代码已复制';

  @override
  String get contentCopied => '内容已复制';

  @override
  String get thinking => '思考中';

  @override
  String get thinkingProcess => '思考过程';

  @override
  String get expandThinking => '展开思考过程';

  @override
  String get collapseThinking => '收起思考过程';

  @override
  String get searchWeb => '搜索网页';

  @override
  String get searchResults => '搜索结果';

  @override
  String searchResultsWithEngine(int count, String engine) {
    return '$count 个搜索结果 ($engine)';
  }

  @override
  String citationsCount(int count) {
    return '$count 个引用内容';
  }

  @override
  String get agentResponse => '智能助手响应';

  @override
  String get agentOutput => '智能助手输出';

  @override
  String terminalError(int code) {
    return '终端错误 (错误码 $code)';
  }

  @override
  String get terminalOutput => '终端输出';

  @override
  String get noOutput => '[无输出]';

  @override
  String get imageGenerated => '图片已生成';

  @override
  String get saveImage => '保存图片';

  @override
  String get imageSaved => '图片已保存';

  @override
  String get imageSaveFailed => '图片保存失败';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get last7Days => '最近 7 天';

  @override
  String get last30Days => '最近 30 天';

  @override
  String get earlier => '更早';

  @override
  String get deleteChat => '删除对话';

  @override
  String get deleteChatConfirm => '确定要删除此对话吗？';

  @override
  String get pinChat => '置顶对话';

  @override
  String get unpinChat => '取消置顶';

  @override
  String get noMessages => '暂无消息';

  @override
  String get typeMessage => '输入消息...';

  @override
  String get editApiKey => '编辑 API Key';

  @override
  String get editBaseUrl => '编辑 API Base URL';

  @override
  String get sourceLanguage => '源语言';

  @override
  String get targetLanguage => '目标语言';

  @override
  String get autoDetect => '自动检测';

  @override
  String get english => '英语';

  @override
  String get japanese => '日语';

  @override
  String get korean => '韩语';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁体中文';

  @override
  String get russian => '俄语';

  @override
  String get french => '法语';

  @override
  String get german => '德语';

  @override
  String get streamOutput => '流式输出';

  @override
  String get enableSearch => '启用搜索';

  @override
  String get searchEngine => '搜索引擎';

  @override
  String get clearContext => '清空上下文';

  @override
  String get clearContextConfirm => '确定要清空当前对话的历史记录吗？此操作不可撤销。';

  @override
  String get streamEnabled => '已开启流式传输';

  @override
  String get streamDisabled => '已关闭流式传输';

  @override
  String get searchEnabled => '已开启联网搜索';

  @override
  String get searchDisabled => '已关闭联网搜索';

  @override
  String get desktopInputHint =>
      '随便输入点什么吧 (Enter 换行，Ctrl + Enter 发送，@ 切换模型，/ 切换 Prompt 预设)';

  @override
  String get mobileInputHint => '随便输入点什么吧';

  @override
  String get topics => '话题分组';

  @override
  String get createTopic => '新建分组';

  @override
  String get editTopic => '编辑分组';

  @override
  String get deleteTopic => '删除分组';

  @override
  String get deleteTopicConfirm => '确定要删除此分组吗？该分组下的会话将移至默认分组。';

  @override
  String get topicNamePlaceholder => '分组名称';

  @override
  String get allChats => '所有';

  @override
  String get thinkingConfig => '思考配置';

  @override
  String get enableThinking => '启用思考';

  @override
  String get thinkingBudget => '思考预算';

  @override
  String get thinkingBudgetHint => '输入数字 (如 1024) 或级别 (如 low, high)';

  @override
  String get transmissionMode => '传输模式';

  @override
  String get modeAuto => '自动智能';

  @override
  String get modeExtraBody => 'Extra Body (Google)';

  @override
  String get modeReasoningEffort => 'Reasoning Effort (OpenAI)';

  @override
  String get providers => '服务商';

  @override
  String get promptPresets => 'Prompt 预设';

  @override
  String get defaultPreset => '默认';

  @override
  String get newPreset => '新建自定义预设';

  @override
  String get editPreset => '编辑预设';

  @override
  String get managePresets => '预设管理';

  @override
  String get presetName => '预设名称';

  @override
  String get presetDescription => '描述 (可选)';

  @override
  String get systemPrompt => '系统提示词';

  @override
  String get savePreset => '保存预设';

  @override
  String get selectPresetHint => '选择左侧预设进行编辑，或新建预设。';

  @override
  String get presetNamePlaceholder => '例如：Python 专家';

  @override
  String get presetDescriptionPlaceholder => '可选描述...';

  @override
  String get systemPromptPlaceholder => '在此输入系统提示词...';

  @override
  String get noPresets => '暂无预设';

  @override
  String get deletePreset => '删除预设';

  @override
  String deletePresetConfirmation(String name) {
    return '确定要删除预设 \"$name\" 吗？';
  }

  @override
  String get fillRequiredFields => '请填写所有必填字段';

  @override
  String get callTrend => '调用趋势 (最近30天)';

  @override
  String get errorDistribution => '错误分布';

  @override
  String get errorTimeout => '超时';

  @override
  String get errorNetwork => '网络错误';

  @override
  String get errorBadRequest => '请求错误 (400)';

  @override
  String get errorUnauthorized => '鉴权失败 (401)';

  @override
  String get errorServerError => '服务器错误 (5XX)';

  @override
  String get errorRateLimit => '限流 (429)';

  @override
  String get errorUnknown => '其他错误';

  @override
  String get bgDefault => '默认';

  @override
  String get bgPureBlack => '纯黑';

  @override
  String get bgWarm => '暖色';

  @override
  String get bgCool => '冷色';

  @override
  String get bgRose => '玫瑰';

  @override
  String get bgLavender => '薰衣草';

  @override
  String get bgMint => '薄荷';

  @override
  String get bgSky => '天空';

  @override
  String get bgGray => '高级灰';

  @override
  String get bgSunset => '日落';

  @override
  String get bgOcean => '海洋';

  @override
  String get bgForest => '森林';

  @override
  String get bgDream => '梦境';

  @override
  String get bgAurora => '极光';

  @override
  String get bgVolcano => '火山';

  @override
  String get bgMidnight => '午夜';

  @override
  String get bgDawn => '晨曦';

  @override
  String get bgNeon => '霓虹';

  @override
  String get bgBlossom => '樱花';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get accentColor => '强调色';

  @override
  String get backgroundStyle => '背景风格';

  @override
  String get renameSession => '重命名';

  @override
  String get renameSessionHint => '输入新名称';

  @override
  String get providerColor => '颜色 (Hex)';

  @override
  String get apiKeyPlaceholder => 'sk-xxxxxxxx';

  @override
  String get baseUrlPlaceholder => 'https://api.openai.com/v1';

  @override
  String get apiKeys => 'API Keys';

  @override
  String get addApiKey => '添加 Key';

  @override
  String get autoRotateKeys => '自动轮询';

  @override
  String get generationConfig => '生成配置';

  @override
  String get customParams => '自定义参数';

  @override
  String get temperature => '温度';

  @override
  String get temperatureHint => '0.0 - 2.0，越低越聚焦';

  @override
  String get maxTokens => '最大Token数';

  @override
  String get maxTokensHint => '最大输出 Token 数（如 4096）';

  @override
  String get contextLength => '上下文长度';

  @override
  String get contextLengthHint => '上下文中包含的消息数量';

  @override
  String get studioDescription => '在这里配置和编排你的智能助手';

  @override
  String get cloudSync => '数据云同步';

  @override
  String get webdavConfig => 'WebDAV 配置';

  @override
  String get webdavUrl => 'WebDAV 地址 (URL)';

  @override
  String get webdavUrlHint => 'https://dav.jianguoyun.com/dav/';

  @override
  String get username => '用户名';

  @override
  String get usernameHint => 'email@example.com';

  @override
  String get passwordOrToken => '密码 / 应用授权码';

  @override
  String get testConnection => '连接';

  @override
  String get backupNow => '备份';

  @override
  String get cloudBackupList => '云端备份列表';

  @override
  String get noBackupsOrNotConnected => '暂无备份或未连接';

  @override
  String get restore => '恢复';

  @override
  String get confirmRestore => '确认恢复?';

  @override
  String get restoreWarning => '恢复操作将尝试合并云端数据到本地。如果存在冲突可能会更新本地数据。建议先备份当前数据。';

  @override
  String get confirmRestoreButton => '确定恢复';

  @override
  String get connectionSuccess => '连接成功';

  @override
  String get connectionFailed => '连接失败: 请检查配置';

  @override
  String get connectionError => '连接异常';

  @override
  String get backupSuccess => '备份上传成功';

  @override
  String get backupFailed => '备份失败';

  @override
  String get restoreSuccess => '数据恢复成功';

  @override
  String get restoreFailed => '恢复失败';

  @override
  String get fetchBackupListFailed => '获取备份列表失败';

  @override
  String get exportSuccess => '导出成功';

  @override
  String get exportFailed => '导出失败';

  @override
  String get importSuccess => '导入成功';

  @override
  String get importFailed => '导入失败';

  @override
  String get clearDataConfirmTitle => '确认清空所有数据?';

  @override
  String get clearDataConfirmContent => '此操作将永久删除所有会话、消息和话题数据，且无法撤销。建议先导出备份。';

  @override
  String get clearDataSuccess => '数据已清空';

  @override
  String get clearDataFailed => '清空数据失败';

  @override
  String get novelWritingDescription => '配置写作、审查、大纲模型';

  @override
  String get schedulePlanning => '日程规划';

  @override
  String get schedulePlanningDescription => '规划和管理你的创作日程';

  @override
  String get imageManagement => '图片管理';

  @override
  String get imageManagementDescription => '整理和管理项目图片素材';

  @override
  String get comingSoon => '即将推出';

  @override
  String get generating => '生成中...';

  @override
  String get branch => '分支';

  @override
  String get trayShow => '显示程序';

  @override
  String get trayExit => '退出程序';

  @override
  String get confirmClose => '确认关闭';

  @override
  String get minimizeToTray => '是否最小化到系统托盘？';

  @override
  String get minimize => '最小化';

  @override
  String get exit => '退出';

  @override
  String get rememberChoice => '记住我的选择';

  @override
  String get closeBehavior => '关闭行为';

  @override
  String get askEveryTime => '每次询问';

  @override
  String get minimizeToTrayOption => '最小化到托盘';

  @override
  String get exitApplicationOption => '直接退出程序';

  @override
  String get novelPreset => '预设';

  @override
  String get selectPreset => '选择预设';

  @override
  String get noCustomPresets => '暂无自定义预设';

  @override
  String get systemDefault => '系统默认';

  @override
  String get systemDefaultRestored => '已恢复系统默认预设';

  @override
  String presetLoaded(String name) {
    return '已加载预设: $name';
  }

  @override
  String get newNovelPreset => '新建预设';

  @override
  String get savePresetHint => '将保存当前所有角色的提示词配置。';

  @override
  String presetSaved(String name) {
    return '预设 \"$name\" 已保存';
  }

  @override
  String get outline => '大纲';

  @override
  String get outlineModel => '大纲模型';

  @override
  String get savePresetOverrideHint => '保存当前配置覆盖选中的预设';

  @override
  String get selectiveBackup => '可选备份';

  @override
  String get backupChatHistory => '聊天记录';

  @override
  String get backupChatPresets => 'Prompt 预设';

  @override
  String get backupProviderConfigs => '模型供应商配置';

  @override
  String get backupStudioContent => 'Studio 内容';

  @override
  String get noOptionsSelected => '请至少选择一项进行备份';
}
