import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'novel_state.dart';
import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/shared/services/openai_llm_service.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/settings/presentation/usage_stats_provider.dart';
import 'package:aurora/core/error/app_error_type.dart';
import 'package:aurora/core/error/app_exception.dart';

final novelProvider = StateNotifierProvider<NovelNotifier, NovelWritingState>((ref) {
  return NovelNotifier(ref);
});

// Preset prompts for model roles
class NovelPromptPresets {
  // 拆解模型-第一阶段：生成章节标题列表
  static const String chapterListPlanner = '''你是一个小说架构师。请阅读故事大纲，并将其规划为精简的章节标题列表。
  
请以JSON数组格式返回所有章节的标题：
[
  "第一章 标题",
  "第二章 标题",
  ...
]

⚠️【强制执行】只返回JSON数组，禁止包含任何闲聊、解释、开场白或结尾。不要使用Markdown代码块包裹，直接输出内容。
⚠️【全书覆盖】必须包含大纲中所有的剧情节点，不得遗漏。''';

  // 拆解模型-第二阶段：为指定章节生成详细细纲
  static const String decompose = '''你是一个顶尖的小说章节细纲规划专家。
你的任务是根据全书大纲和【前文进度总结】，为您正在处理的【特定章节】生成极其详细的剧本级细纲。

【细纲要求】⭐极重要
1. 情节起伏：分为 [起] [承] [转] [合] 四个阶段，详细描述具体事件、环境变化和动作。
2. 心理/感官焦点：重点描写的感官细节及主角心理转变曲线。
3. 核心互动：对话要点、博弈过程、关键台词。
4. 伏笔/衔接：如何自然衔接下一章。

请以JSON对象数组格式返回：
[
  {
    "title": "章节标题",
    "description": "【人称：xxx】\\n[剧情梗概]：...\\n[起]：...\\n[承]：...\\n[转]：...\\n[合]：...\\n[写作要点]：..."
  }
]

【严禁科学化/公式化】⚠️极重要
- 绝对禁止出现数学公式、物理公式或任何形式的定量分析（如：E = B × M）。
- 绝对禁止使用现代科学逻辑、术语来“合理解释”魔法（如：浓度、正比、反比、因子、效率、能量守恒、属性加成）。
- 严禁引用虚构的学术著作（如：《正统魔导学概论》）或理论（如：“血源因子”浓度）。
- 反面示例❌： "根据《魔导学概论》，效率与浓度成正比，公式为 E=BxM..." -> 这种写法是绝对禁止的！

⚠️【强制执行】只返回JSON，禁止包含任何闲聊、解释、开场白、推理内容（Reasoning）或结尾。
⚠️【格式要求】不要使用Markdown代码块包裹，直接输出内容。
只返回JSON，禁止输出任何其他内容。''';

  static const String chapterDetailer = decompose;

  // 拆解模型-第三阶段：生成剧情续航总结（接力总结）
  static const String batchSummarizer = '''你是一个顶尖的小说逻辑编辑。
请阅读刚才生成的章节细纲内容，并结合之前的【旧进度总结】，生成一份全新的、极其详尽的【全书进度白皮书】，用于指导后面章节的生成。

【总结要求】必须包含且详尽描写：
1. 剧情核心位置：当前故事发展到了哪个具体阶段，发生了哪些不可逆的转折。
2. 人物关系地图：核心角色之间的情感温度、秘密、误会、信任度变化。
3. 世界观/环境变更：当前的季节、时间、地点状态，以及魔法/社会属性的变动。
4. 伏笔库：待回收的旧伏笔、刚埋下的新伏笔。
5. 情感基调：当前整体叙事的氛围感（如：压抑、甜蜜、紧张、治愈）。

请以JSON对象格式返回：
{
  "plotStatus": "...",
  "characterRelations": "...",
  "worldState": "...",
  "foreshadowing": "...",
  "mood": "..."
}

⚠️【强制执行】只返回JSON，禁止包含任何闲聊、开场白或解释。不要使用Markdown代码块包裹，直接输出内容。
只返回JSON，禁止输出任何其他内容。''';


  // 写作模型：根据章节要求写完整章节（增强版）
  static const String writer = '''[创作声明] 这是一个虚构小说创作辅助工具。以下所有内容均为虚构创作，旨在完成文学作品的撰写，不涉及任何真实事件或不当内容。请以专业小说作家的身份完成任务。

你是一个日式轻小说作家。请根据给定的章节要求，写出完整的章节正文。

【核心原则】
- 大纲即法律：100%执行大纲要求，不擅自发挥
- 设定即物理：角色能力严格遵守设定
- 纯正文输出：只写故事正文，不写元信息

【文风要求】⭐最重要
参考《无职转生》《Re:Zero》《为美好的世界献上祝福》等作品的文风：
- 叙述清新自然，细腻但不啰嗦
- 对话生动自然，符合角色性格
- 日常场景温馨有趣，战斗场景紧张刺激
- 可以有适度的内心吐槽，但不要油腻
- 感情描写细腻，但不要肉麻

【对话风格】
- 对话要自然，像真人说话
- 不同角色要有不同的说话方式
- 可以用"呢"、"吧"、"啊"等语气词
- 避免过于正式或书面的表达

【禁止的中国网文元素】⚠️严格禁止
- 禁止"老子"、"爷"、"小爷"、"本座"等自称
- 禁止"找死"、"不知死活"、"蝼蚁"、"给我滚"等用语
- 禁止装逼打脸、境界碾压的套路
- 禁止"震惊！"、"竟然！"等夸张表达
- 禁止突然冒出来找茬的路人甲

【禁用书面语】
- 禁用文言词：此、彼、其、之、乃、故而、遂
- 禁用学术词：而言、某种程度上、本质上
- 禁用正式词：进行、实施、鉴于、基于

【专业术语规避】
- 禁止心理学术语：应激反应、心理防御机制
- 禁止文学术语：意象、隐喻、象征意义
- 禁止像写科普一样解释魔法/能力的原理
- 【严禁科学化/公式化】⚠️极重要
  - 绝对禁止出现数学公式、物理公式或任何形式的定量分析（如：E = B × M）。
  - 绝对禁止使用现代科学逻辑、术语来“合理解释”魔法（如：浓度、正比、反比、因子、效率、能量守恒、属性加成）。
  - 不要把魔法写得像理工科实验，要写得像艺术、感悟、血脉本能或某种不可理喻的神秘现象。

【AI痕迹规避】
- 禁用总结句式："这让他明白了..."、"他意识到..."
- 禁用排比句式：不要连续三个"他看到...他听到...他感到..."
- 禁止在对话后解释对话的含义
- 章节结尾不要搞升华，自然结束即可

【虚构术语规避】⚠️重要
- 禁止编造具体的书名，如《社交礼仪守则》《君臣纲纪》《草药学入门》《魔力学基础》
- 严禁借用不存在的“XX概论”、“XX理论”、“XX学说”来输出设定逻辑。
- 除非是剧情关键道具，否则只用泛称："一本讲礼仪的书"、"关于草药的典籍"
- 学科/课程也不要编名字：直说"草药课"、"魔法理论课"即可

【人称遵守】⚠️最重要
- 如果任务描述中标注了【人称：第一人称】，必须全程使用"我"作为叙述视角
- 如果任务描述中标注了【人称：第三人称】，使用角色名或"他/她"叙述
- 人称一旦确定，全章不得混用

【精简描写】⭐重要
- 形容词克制：每个名词最多1个形容词，避免"xxx的xxx的xxx"
- 环境描写从简：1-2句点到为止，不要铺陈整段环境描写
- 聚焦人物：描写为人物服务，与情节无关的景物一律省略
- 动作优先：用动作和对话推进剧情，减少静态描写
- 禁止"诗意"描写：不要用大量比喻、排比来描述日常场景，禁止使用“灵魂震颤”、“凝固”、“千万年”等空洞夸张词汇


【反面示例】❌
❌ "阳光像是被打翻的蜂蜜罐头，黏稠而甜蜜地流淌在精心修剪的灌木迷宫上..."（过度修辞）
❌ "根据《魔导学概论》，魔力输出效率与血源因子浓度成正比。公式为：E = B × M..."（严禁公式化/科学化）
✅ "茶会的空气甜腻得让人头疼。"
✅ "随着他深吸一口气，体内的血液仿佛沸腾一般，魔力如决堤的洪水般涌出。"

【字数要求】
- 本章字数：3000-5000字
- 注意节奏，张弛有度
- 对话换人换行

禁止输出任何与任务无关的内容，直接输出正文即可。''';

  // 审查模型：审查章节质量（增强版）
  static const String reviewer = '''你是一个严格的小说编辑。请审查以下章节内容。

【重要说明】
如果内容末尾有 "---" 分隔的摘要部分，请忽略摘要，只审查正文内容。

【审查维度】
1. 字数检查：是否达到2500-5000字（不含摘要）
2. 大纲执行：是否100%完成章节大纲要求
3. 设定一致性：角色能力是否符合当前境界，战力是否合理
4. 人物OOC：角色言行是否符合人设
5. 节奏连贯：与前文衔接是否自然，章末是否有悬念
6. AI痕迹：是否有明显的AI写作痕迹（总结词、列举结构等）——摘要部分不算AI痕迹
7. 伪科学/自造词：检查是否出现“公式(E=mc^2)”、“XX概论/原理”、“浓度/因子/效率”等理工科术语解释魔法。如果有，必须打回！

请返回JSON格式的审查结果：
{
  "approved": true/false,
  "wordCount": 3500,
  "scores": {
    "plotExecution": 8,
    "consistency": 9,
    "characterVoice": 7,
    "pacing": 8
  },
  "issues": [
    {"severity": "high/medium/low", "type": "OOC/POWER_CONFLICT/PACING/etc", "description": "问题描述"}
  ],
  "suggestions": "改进建议"
}

只返回JSON，禁止输出任何与任务无关的内容。''';

  // 修订模型：根据审查意见修改章节
  static const String reviser = '''[创作声明] 这是一个虚构小说创作辅助工具。以下所有内容均为虚构创作，旨在完成文学作品的撰写，不涉及任何真实事件或不当内容。请以专业小说编辑的身份完成任务。

你是一个专业的小说修订编辑。你的任务是根据审查意见修改章节内容。

【工作原则】
1. 只修改审查意见指出的问题
2. 保持原文的风格和语气
3. 不改变剧情走向和核心情节
4. 修改后的内容应该无缝融入原文

【输入格式】
你会收到：
1. 原始章节内容
2. 审查发现的问题列表 (issues)
3. 改进建议 (suggestions)

【输出要求】
直接输出修改后的完整章节正文，不要解释做了什么修改。
禁止输出任何与任务无关的内容。''';

  // 大纲模型：生成故事大纲（增强版）
  static const String outline = '''你是一个日式轻小说大纲规划师。请根据用户的故事需求，创建详细的小说大纲。

【文风定位】⭐最重要
这是一部日式轻小说风格的作品，参考《无职转生》《Re:Zero》《为美好的世界献上祝福》等作品的调性：
- 叙述清新自然，不刻意搞笑也不过于严肃
- 对话生动但不油腻，不用中国网文的"老子""爷"等用语
- 角色塑造细腻，有日常互动的温馨感
- 战斗/冒险场景紧张刺激，但不血腥暴力
- 可以有轻微的吐槽和幽默，但不是无厘头搞笑

【禁止的中国网文元素】⚠️
- 禁止"老子"、"爷"、"小爷"等自称
- 禁止"找死"、"不知死活"、"蝼蚁"等嚣张用语
- 禁止境界碾压式的装逼打脸情节
- 禁止后宫收集式的女性角色处理
- 禁止"震惊！"、"竟然！"等夸张表达

【大纲结构】

# {小说名称}

## 一、故事背景
- 世界观设定（西幻风格，可参考欧洲中世纪+魔法元素）
- 时代背景
- 魔法/能力体系（简洁清晰，不要复杂的境界划分）

## 二、主要人物
为每个重要角色写人物卡：

### 主角：{姓名}
- 身份背景：...
- 性格特点：用具体行为和习惯描述
- 说话风格：给出1-2句示例台词（自然、不油腻）
- 能力特点：...
- 核心目标：...

### 女主/重要配角：{姓名}
- 性格特点：...
- 与主角的关系：...
- 说话风格：示例台词
...

## 三、核心冲突
- 主线矛盾：{具体的威胁或目标}
- 主角动机：{为什么要行动}
- 成长方向：{主角会如何变化}

## 四、剧情规划
详细规划每个阶段：

### 第一阶段（第1-X章）：{阶段名称}
- 核心事件：...
- 角色互动亮点：{写1-2个温馨或有趣的日常场景}
- 主角成长：...
- 阶段结尾：{悬念或转折}

### 第二阶段（第X-Y章）：{阶段名称}
...

## 五、节奏规划
- 主线剧情/冒险：50-60%
- 日常/角色互动：30-40%（日式轻小说很重视日常戏）
- 世界观展开：10-15%

## 六、伏笔规划
| 埋设章节 | 伏笔内容 | 回收章节 |
|---------|---------|---------|
| ... | ... | ... |

## 七、结局走向
{描述结局的发展方向}

【禁止事项】⚠️
- 禁止使用文学批评术语
- 禁止使用心理学专业术语
- 禁止过度解释魔法/能力的原理
- 绝对禁止出现数学公式、定量分析或类似 E=MC^2 的理工科逻辑
- 严禁在设定中使用“效率”、“浓度”、“因子”、“参数”等现代科研词汇
- 严禁引用虚构的学术著作（如《正统魔导学概论》）或理论（如“血源因子”浓度）
- 角色对话要自然，不要书面化

请输出不少于3000字的详细大纲。禁止输出任何与任务无关的内容。''';

  // 上下文提取模型：从章节内容中提取设定变化（增强版 v2）
  static const String contextExtractor = '''你是一个小说分析助手。请从以下章节内容中提取关键信息的变化。

请返回JSON格式：
{
  "newCharacters": {"角色名": "描述"},
  "characterUpdates": {"已有角色名": "状态变化描述，如境界提升、获得物品等"},
  "newRules": {"规则名": "描述"},
  "ruleUpdates": {"已有规则名": "规则变化或补充描述"},
  "updatedRelationships": {"关系key": "关系描述"},
  "newLocations": {"地点名": "描述"},
  "newForeshadowing": ["伏笔1", "伏笔2"],
  "resolvedForeshadowing": ["已解决的伏笔"],
  "stateChanges": [
    {"entity": "实体名", "field": "变化字段", "oldValue": "旧值", "newValue": "新值", "reason": "变化原因"}
  ],
  "chapterSummary": "本章核心事件的一句话摘要"
}

只返回JSON，禁止输出任何与任务无关的内容。如果没有变化，返回空对象。''';

  // 上下文构建模型：智能筛选本章需要的上下文（Context Agent）
  static const String contextBuilder = '''你是一个小说上下文规划师。你的任务是分析本章大纲，从设定库中筛选出写作本章真正需要的信息。

输入：
1. 本章大纲/任务描述
2. 当前可用的设定 Keys 列表

请返回JSON格式：
{
  "neededCharacters": ["角色名1", "角色名2"],
  "neededLocations": ["地点名1"],
  "neededRules": ["规则名1"],
  "neededRelationships": ["关系key1"],
  "reasoning": "简述为什么需要这些信息"
}

筛选原则：
- 只选择本章剧情**直接涉及**的实体
- 如果大纲提到某角色，选择该角色
- 如果大纲提到某地点，选择该地点
- 如果涉及战斗/修炼，选择相关的修炼体系规则
- 宁缺毋滥，不确定的不要选

只返回JSON，禁止输出任何与任务无关的内容。''';
}

class NovelNotifier extends StateNotifier<NovelWritingState> {
  final Ref _ref;
  bool _shouldStop = false;
  
  NovelNotifier(this._ref) : super(const NovelWritingState()) {
    _loadState();
  }

  Future<File> get _stateFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/novel_writing_state.json');
  }

  Future<void> _loadState() async {
    try {
      final file = await _stateFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        state = NovelWritingState.fromJson(json);
        
        // Fix stuck tasks: reset 'running', 'reviewing', or 'needsRevision' tasks to 'pending' on startup
        // since the workflow is not actually running after a restart
        final fixedTasks = state.allTasks.map((t) {
          if (t.status == TaskStatus.running || t.status == TaskStatus.reviewing || t.status == TaskStatus.needsRevision) {
            return t.copyWith(status: TaskStatus.pending, retryCount: 0);
          }
          return t;
        }).toList();
        
        if (state.allTasks.any((t) => t.status == TaskStatus.running || t.status == TaskStatus.reviewing || t.status == TaskStatus.needsRevision)) {
          state = state.copyWith(
            allTasks: fixedTasks,
            isRunning: false,
            isPaused: false,
          );
          _saveState();
        }
      }
    } catch (e) {
      // Ignore load errors, start with empty state
    }
  }

  Future<void> _saveState() async {
    try {
      final file = await _stateFile;
      final json = state.toJson();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      // Ignore save errors
    }
  }

  // ========== LLM Call Helper ==========
  Future<String> _callLLM(NovelModelConfig config, String systemPrompt, String userMessage) async {
    final startTime = DateTime.now();
    final settings = _ref.read(settingsProvider);
    
    // Find the provider config
    final provider = settings.providers.firstWhere(
      (p) => p.id == config.providerId,
      orElse: () => settings.activeProvider,
    );
    
    // Create a temporary settings state with the selected model
    final tempSettings = settings.copyWith(
      activeProviderId: provider.id,
    );
    
    // Update the provider's selected model temporarily
    final updatedProvider = provider.copyWith(selectedModel: config.modelId);
    final updatedProviders = tempSettings.providers.map((p) {
      return p.id == updatedProvider.id ? updatedProvider : p;
    }).toList();
    
    final finalSettings = tempSettings.copyWith(providers: updatedProviders);
    
    final llmService = OpenAILLMService(finalSettings);
    
    final messages = [
      Message(
        id: const Uuid().v4(),
        content: systemPrompt,
        isUser: false,
        timestamp: DateTime.now(),
        role: 'system',
      ),
      Message.user(userMessage),
    ];
    
    int attempts = 0;
    const maxAttempts = 3;
    
    while (true) {
      attempts++;
      final requestStartTime = DateTime.now();
      
      try {
        final response = await llmService.getResponse(messages);
        final durationMs = DateTime.now().difference(requestStartTime).inMilliseconds;
        
        // Check for truncation (Content Filter)
        final isTruncated = response.finishReason == 'prohibited_content' || 
                           response.finishReason == 'content_filter';
                           
        if (isTruncated) {
          print('⚠️ LLM Request Truncated (Reason: ${response.finishReason}). Retrying... ($attempts/$maxAttempts)');
          
          // Still track usage since tokens were consumed
          _ref.read(usageStatsProvider.notifier).incrementUsage(
            config.modelId,
            success: true,
            durationMs: durationMs,
            tokenCount: response.usage ?? 0,
          );
          
          if (attempts < maxAttempts) {
            continue; // Retry loop
          } else {
            throw Exception('Generation stopped due to ${response.finishReason} (Max retries reached)');
          }
        }
        
        // Success case
        _ref.read(usageStatsProvider.notifier).incrementUsage(
          config.modelId,
          success: true,
          durationMs: durationMs,
          tokenCount: response.usage ?? 0,
        );
        
        return response.content ?? '';
        
      } catch (e) {
        // Track failed usage
        final durationMs = DateTime.now().difference(requestStartTime).inMilliseconds;
        AppErrorType errorType = AppErrorType.unknown;
        if (e is AppException) {
          errorType = e.type;
        }
        _ref.read(usageStatsProvider.notifier).incrementUsage(
          config.modelId,
          success: false,
          durationMs: durationMs,
          errorType: errorType,
        );
        rethrow;
      }
    }
  }

  // ========== Workflow Engine ==========
  Future<void> runWorkflow() async {
    if (state.isRunning) return;
    _shouldStop = false;
    state = state.copyWith(isRunning: true, isPaused: false);
    _saveState();
    
    await _processTaskQueue();
  }
  
  Future<void> _processTaskQueue() async {
    while (!_shouldStop && mounted) {
      // Find next pending task for current project
      // We look for tasks that are 'pending' OR 'needsRevision' (if we want to auto-retry those, 
      // though typically they transition back to 'reviewing' immediately)
      final allTasks = state.allTasks;
      final pendingTask = allTasks.firstWhere(
        (t) => t.status == TaskStatus.pending && _isTaskInCurrentProject(t),
        orElse: () => NovelTask(id: '', chapterId: '', description: ''),
      );
      
      if (pendingTask.id.isEmpty) {
        // No more pending tasks
        print('✅ No more pending tasks found, stopping loop.');
        state = state.copyWith(isRunning: false);
        _saveState();
        return;
      }
      
      // Check if paused
      while (state.isPaused && !_shouldStop) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (_shouldStop) {
        print('⏹ Workflow stopped by _shouldStop flag.');
        break;
      }
      
      // Execute the task
      await _executeTask(pendingTask.id);
      
      // Safety: wait a tiny bit to ensure state updates propagate
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    state = state.copyWith(isRunning: false);
    _saveState();
  }
  
  bool _isTaskInCurrentProject(NovelTask task) {
    if (state.selectedProject == null) return false;
    return state.selectedProject!.chapters.any((c) => c.id == task.chapterId);
  }
  
  Future<void> _executeTask(String taskId) async {
    // Mark task as running
    _updateTaskStatus(taskId, TaskStatus.running);
    
    final task = state.allTasks.firstWhere((t) => t.id == taskId);
    
    try {
      // Use writer model to execute the task
      final writerConfig = state.writerModel;
      if (writerConfig == null) {
        throw Exception('Writer model not configured');
      }
      
      final systemPrompt = writerConfig.systemPrompt.isNotEmpty 
          ? writerConfig.systemPrompt 
          : NovelPromptPresets.writer;
      
      // Build context from all chapters in the project (outlines only, not full content)
      final allChapters = state.selectedProject?.chapters ?? [];
      final currentChapterIndex = allChapters.indexWhere((c) => c.id == task.chapterId);
      
      // Get chapter title for context
      final chapter = currentChapterIndex >= 0 ? allChapters[currentChapterIndex] : null;
      final chapterTitle = chapter?.title ?? '未知章节';
      final projectName = state.selectedProject?.name ?? '未知项目';
      final worldContext = state.selectedProject?.worldContext ?? const WorldContext();
      
      // ========== Step 1: Context Agent - 智能筛选上下文 ==========
      // 使用大纲模型（或降级到写作模型）进行上下文筛选
      final contextModel = state.outlineModel ?? writerConfig;
      final filteredContextStr = await _buildFilteredContext(
        contextModel,
        task.description,
        chapterTitle,
        worldContext,
      );
      
      final StringBuffer contextBuffer = StringBuffer();
      
      // Add project info
      contextBuffer.writeln('【项目】$projectName');
      contextBuffer.writeln();
      
      // Add filtered world context (smart selection)
      if (filteredContextStr.isNotEmpty) {
        contextBuffer.writeln(filteredContextStr);
      }
      
      // Add outline of all chapters (descriptions only, not full content)
      if (allChapters.length > 1) {
        contextBuffer.writeln('【全书大纲】');
        for (int i = 0; i < allChapters.length; i++) {
          final c = allChapters[i];
          final tasks = state.tasksForChapter(c.id);
          final taskDesc = tasks.isNotEmpty ? tasks.first.description : '';
          final marker = c.id == task.chapterId ? '→' : ' ';
          contextBuffer.writeln('$marker ${c.title}: $taskDesc');
        }
        contextBuffer.writeln();
      }
      
      // Add recent chapter summaries (if available)
      final recentSummaries = _getRecentChapterSummaries(task.chapterId, 3);
      if (recentSummaries.isNotEmpty) {
        contextBuffer.writeln('【前情提要】');
        contextBuffer.writeln(recentSummaries);
        contextBuffer.writeln();
      }
      
      // Add previous chapter full content for cohesion (避免情节重复和跳变)
      final prevChapterContent = _getPreviousChapterContent(task.chapterId);
      if (prevChapterContent.isNotEmpty) {
        contextBuffer.writeln('【上一章完整内容】⚠️重要：请仔细阅读，确保剧情连贯衔接，避免重复已写过的情节');
        contextBuffer.writeln(prevChapterContent);
        contextBuffer.writeln();
      }
      
      // Add current chapter info
      contextBuffer.writeln('【当前章节】$chapterTitle');
      contextBuffer.writeln();
      
      // Add current task requirement
      contextBuffer.writeln('【本章要求】');
      contextBuffer.writeln(task.description);
      contextBuffer.writeln();
      contextBuffer.writeln('请根据以上大纲和本章要求，写出本章完整正文（2000-5000字）。');
      
      final String fullPrompt = contextBuffer.toString();
      
      // ========== Step 2: Writer - 写作 ==========
      final result = await _callLLM(writerConfig, systemPrompt, fullPrompt);
      
      // Update task with content
      final updatedTasks = state.allTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(content: result, status: state.isReviewEnabled ? TaskStatus.reviewing : TaskStatus.success);
        }
        return t;
      }).toList();
      state = state.copyWith(allTasks: updatedTasks);
      _saveState();
      
      // 保存写作上下文（用于审查失败时的修订）
      final writingContextForRevision = contextBuffer.toString().split('请根据以上大纲和本章要求')[0];
      
      // If review is enabled, run the review (extraction happens after review passes)
      if (state.isReviewEnabled && !_shouldStop) {
        await _reviewTask(taskId, result, writingContext: writingContextForRevision);
      } else {
        // Review not enabled, extract context updates directly
        await _extractContextUpdates(result);
      }
      
    } catch (e) {
      _updateTaskStatus(taskId, TaskStatus.failed);
      // Store error in reviewFeedback field
      final updatedTasks = state.allTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(reviewFeedback: 'Error: $e');
        }
        return t;
      }).toList();
      state = state.copyWith(allTasks: updatedTasks);
      _saveState();
    }
  }

  /// Context Agent: 智能筛选本章需要的上下文
  Future<String> _buildFilteredContext(
    NovelModelConfig config,
    String taskDescription,
    String chapterTitle,
    WorldContext worldContext,
  ) async {
    // 如果设定很少（少于10项），直接全量返回，不需要筛选
    final totalItems = worldContext.characters.length + 
                       worldContext.locations.length + 
                       worldContext.rules.length + 
                       worldContext.relationships.length;
    if (totalItems < 10) {
      return worldContext.toPromptString();
    }
    
    try {
      // 构建可用的 keys 列表
      final availableKeys = StringBuffer();
      availableKeys.writeln('可用角色: ${worldContext.characters.keys.join(", ")}');
      availableKeys.writeln('可用地点: ${worldContext.locations.keys.join(", ")}');
      availableKeys.writeln('可用规则: ${worldContext.rules.keys.join(", ")}');
      availableKeys.writeln('可用关系: ${worldContext.relationships.keys.join(", ")}');
      
      final prompt = '''本章任务：$taskDescription
章节标题：$chapterTitle

${availableKeys.toString()}

请分析本章需要哪些设定信息。''';
      
      final result = await _callLLM(config, NovelPromptPresets.contextBuilder, prompt);
      final selection = jsonDecode(result) as Map<String, dynamic>;
      
      // 根据筛选结果，构建精简的上下文
      final buffer = StringBuffer();
      
      // 筛选角色
      final neededCharacters = List<String>.from(selection['neededCharacters'] ?? []);
      if (neededCharacters.isNotEmpty && worldContext.includeCharacters) {
        buffer.writeln('【相关人物】');
        for (final charName in neededCharacters) {
          if (worldContext.characters.containsKey(charName)) {
            buffer.writeln('- $charName: ${worldContext.characters[charName]}');
          }
        }
        buffer.writeln();
      }
      
      // 筛选地点
      final neededLocations = List<String>.from(selection['neededLocations'] ?? []);
      if (neededLocations.isNotEmpty && worldContext.includeLocations) {
        buffer.writeln('【相关场景】');
        for (final locName in neededLocations) {
          if (worldContext.locations.containsKey(locName)) {
            buffer.writeln('- $locName: ${worldContext.locations[locName]}');
          }
        }
        buffer.writeln();
      }
      
      // 筛选规则
      final neededRules = List<String>.from(selection['neededRules'] ?? []);
      if (neededRules.isNotEmpty && worldContext.includeRules) {
        buffer.writeln('【相关规则】');
        for (final ruleName in neededRules) {
          if (worldContext.rules.containsKey(ruleName)) {
            buffer.writeln('- $ruleName: ${worldContext.rules[ruleName]}');
          }
        }
        buffer.writeln();
      }
      
      // 筛选关系
      final neededRelationships = List<String>.from(selection['neededRelationships'] ?? []);
      if (neededRelationships.isNotEmpty && worldContext.includeRelationships) {
        buffer.writeln('【相关关系】');
        for (final relKey in neededRelationships) {
          if (worldContext.relationships.containsKey(relKey)) {
            buffer.writeln('- $relKey: ${worldContext.relationships[relKey]}');
          }
        }
        buffer.writeln();
      }
      
      // 伏笔总是全量包含（通常不多）
      if (worldContext.includeForeshadowing && worldContext.foreshadowing.isNotEmpty) {
        buffer.writeln('【伏笔/线索】');
        for (final f in worldContext.foreshadowing) {
          buffer.writeln('- $f');
        }
        buffer.writeln();
      }
      
      return buffer.toString();
      
    } catch (e) {
      // 如果筛选失败，降级为全量返回
      return worldContext.toPromptString();
    }
  }

  /// 获取最近几章的摘要（用于前情提要）
  String _getRecentChapterSummaries(String currentChapterId, int count) {
    final project = state.selectedProject;
    if (project == null) return '';
    
    final currentIndex = project.chapters.indexWhere((c) => c.id == currentChapterId);
    if (currentIndex <= 0) return '';
    
    final buffer = StringBuffer();
    final startIndex = (currentIndex - count).clamp(0, currentIndex);
    
    for (int i = startIndex; i < currentIndex; i++) {
      final chapter = project.chapters[i];
      final tasks = state.tasksForChapter(chapter.id);
      
      // 查找该章节的摘要（如果有的话，从 task 内容中提取）
      for (final task in tasks) {
        if (task.status == TaskStatus.success && task.content != null) {
          // 取前100个字符作为简要摘要
          final preview = task.content!.length > 100 
              ? '${task.content!.substring(0, 100)}...' 
              : task.content!;
          buffer.writeln('${chapter.title}: $preview');
          break;
        }
      }
    }
    
    return buffer.toString();
  }

  /// 获取上一章的完整内容（用于剧情衔接，避免重复和跳变）
  String _getPreviousChapterContent(String currentChapterId) {
    final project = state.selectedProject;
    if (project == null) return '';
    
    final currentIndex = project.chapters.indexWhere((c) => c.id == currentChapterId);
    if (currentIndex <= 0) return '';
    
    final prevChapter = project.chapters[currentIndex - 1];
    final tasks = state.tasksForChapter(prevChapter.id);
    
    // 查找上一章的生成内容
    for (final task in tasks) {
      if (task.status == TaskStatus.success && task.content != null && task.content!.isNotEmpty) {
        String content = task.content!;
        // 去除章节摘要部分（--- 后的内容），只保留正文
        final summaryIndex = content.indexOf('\n---\n');
        if (summaryIndex > 0) {
          content = content.substring(0, summaryIndex).trim();
        }
        return content;
      }
    }
    
    return '';
  }

  String exportChapterContent(String chapterId) {
    final tasks = state.tasksForChapter(chapterId);
    final buffer = StringBuffer();
    
    // Find chapter title
    final chapter = state.selectedProject?.chapters.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => NovelChapter(id: '', title: 'Unknown Chapter', order: 0),
    );
    
    if (chapter != null) {
      buffer.writeln('# ${chapter.title}');
      buffer.writeln();
    }
    
    for (final task in tasks) {
      if (task.status == TaskStatus.success && task.content != null) {
        buffer.writeln(task.content);
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }

  /// 导出全书内容（所有章节）
  String exportFullNovel() {
    final project = state.selectedProject;
    if (project == null) return '';
    
    final buffer = StringBuffer();
    
    // 添加书名
    buffer.writeln('# ${project.name}');
    buffer.writeln();
    
    // 按顺序导出每个章节
    for (final chapter in project.chapters) {
      final chapterContent = exportChapterContent(chapter.id);
      if (chapterContent.isNotEmpty) {
        buffer.writeln(chapterContent);
        buffer.writeln('---'); // 章节分隔符
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }

  /// 获取全书统计信息
  Map<String, dynamic> getNovelStats() {
    final project = state.selectedProject;
    if (project == null) return {};
    
    int totalChapters = project.chapters.length;
    int completedChapters = 0;
    int totalWords = 0;
    
    for (final chapter in project.chapters) {
      final tasks = state.tasksForChapter(chapter.id);
      bool hasContent = false;
      for (final task in tasks) {
        if (task.status == TaskStatus.success && task.content != null) {
          hasContent = true;
          totalWords += task.content!.length;
        }
      }
      if (hasContent) completedChapters++;
    }
    
    return {
      'totalChapters': totalChapters,
      'completedChapters': completedChapters,
      'totalWords': totalWords,
    };
  }
  
  Future<void> _reviewTask(String taskId, String content, {String writingContext = ''}) async {
    final reviewerConfig = state.reviewerModel;
    if (reviewerConfig == null) {
      // No reviewer configured, auto-approve and reset retry count
      final updatedTasks = state.allTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(status: TaskStatus.success, retryCount: 0);
        }
        return t;
      }).toList();
      state = state.copyWith(allTasks: updatedTasks);
      _saveState();
      return;
    }
    
    final task = state.allTasks.firstWhere((t) => t.id == taskId);
    
    try {
      final systemPrompt = reviewerConfig.systemPrompt.isNotEmpty 
          ? reviewerConfig.systemPrompt 
          : NovelPromptPresets.reviewer;
      
      final reviewPrompt = '''
任务描述: ${task.description}

生成的内容:
$content

请审查以上内容。''';
      
      final reviewResult = await _callLLM(reviewerConfig, systemPrompt, reviewPrompt);
      
      // Strip markdown code blocks if present (```json ... ```)
      String jsonStr = reviewResult.trim();
      if (jsonStr.startsWith('```')) {
        // Remove opening ``` or ```json
        final firstNewline = jsonStr.indexOf('\n');
        if (firstNewline > 0) {
          jsonStr = jsonStr.substring(firstNewline + 1);
        }
        // Remove closing ```
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3).trim();
        }
      }
      
      // Try to parse review result
      try {
        final reviewJson = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        // approved 字段必须存在且为 bool，否则视为格式错误
        if (!reviewJson.containsKey('approved') || reviewJson['approved'] is! bool) {
          throw FormatException('Missing or invalid "approved" field in review result');
        }
        final approved = reviewJson['approved'] as bool;
        
        if (approved) {
          // ✅ 审查通过 → success
          final updatedTasks = state.allTasks.map((t) {
            if (t.id == taskId) {
              return t.copyWith(
                status: TaskStatus.success,
                content: content,
                reviewFeedback: reviewResult,
                retryCount: 0, // Reset retry count on success
              );
            }
            return t;
          }).toList();
          state = state.copyWith(allTasks: updatedTasks);
          _saveState();
          
          // 审查通过后：提取伏笔和人物信息变化
          await _extractContextUpdates(content);
        } else {
          // ❌ 审查不通过
          final currentRetryCount = task.retryCount;
          
          if (currentRetryCount == 0) {
            // 第一次失败 → needsRevision，进行修订
            final issues = reviewJson['issues'] as List<dynamic>? ?? [];
            final suggestions = reviewJson['suggestions'] as String? ?? '';
            
            // 更新状态为 needsRevision
            final updatedTasks = state.allTasks.map((t) {
              if (t.id == taskId) {
                return t.copyWith(
                  status: TaskStatus.needsRevision,
                  reviewFeedback: '第1次审查未通过，正在修订...\n$reviewResult',
                  retryCount: 1,
                );
              }
              return t;
            }).toList();
            state = state.copyWith(allTasks: updatedTasks);
            _saveState();
            
            // 调用修订
            final revisedContent = await _reviseContent(content, issues, suggestions, task.description, writingContext);
            
            // 更新状态为 reviewing 并重新审查
            _updateTaskStatus(taskId, TaskStatus.reviewing);
            await _reviewTask(taskId, revisedContent, writingContext: writingContext);
            return; // 递归调用结束后直接返回，避免执行后续逻辑
            
          } else {
            // 第二次失败 → failed，停止队列
            final updatedTasks = state.allTasks.map((t) {
              if (t.id == taskId) {
                return t.copyWith(
                  status: TaskStatus.failed,
                  content: content,
                  reviewFeedback: '审查失败（连续2次未通过）\n$reviewResult',
                  retryCount: currentRetryCount + 1,
                );
              }
              return t;
            }).toList();
            state = state.copyWith(allTasks: updatedTasks);
            _saveState();
            
            // 停止后续任务执行，等待人工处理
            _shouldStop = true;
            return;
          }
        }
        
      } catch (e) {
        // Review result is not valid JSON, mark as error
        print('⚠️ Review JSON parse error: $e');
        print('⚠️ Raw result: $reviewResult');
        final updatedTasks = state.allTasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(
              status: TaskStatus.failed,
              reviewFeedback: '审查结果解析失败\n$reviewResult',
            );
          }
          return t;
        }).toList();
        state = state.copyWith(allTasks: updatedTasks);
        _saveState();
        _shouldStop = true;
      }
      
    } catch (e) {
      // Review failed, mark task as failed and needing attention
      final updatedTasks = state.allTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(
            status: TaskStatus.failed,
            reviewFeedback: 'Review error: $e',
          );
        }
        return t;
      }).toList();
      state = state.copyWith(allTasks: updatedTasks);
      _saveState();
    }
  }

  /// 根据审查意见修订内容
  Future<String> _reviseContent(
    String originalContent, 
    List<dynamic> issues, 
    String suggestions, 
    String taskDescription,
    String writingContext,  // 新增：原始写作上下文
  ) async {
    final writerConfig = state.writerModel;
    if (writerConfig == null) {
      return originalContent; // 无法修订，返回原内容
    }
    
    // 构建问题列表
    final issuesList = StringBuffer();
    for (int i = 0; i < issues.length; i++) {
      final issue = issues[i] as Map<String, dynamic>;
      final severity = issue['severity'] ?? 'medium';
      final type = issue['type'] ?? 'unknown';
      final desc = issue['description'] ?? '';
      issuesList.writeln('${i + 1}. [$severity] $type: $desc');
    }
    
    final revisionPrompt = '''【写作约束】（修订时必须遵守）
$writingContext

【本章任务】
$taskDescription

【原始章节内容】
$originalContent

【审查发现的问题】
${issuesList.toString()}

【改进建议】
$suggestions

请根据以上审查意见修改章节内容。
- 必须严格遵守【写作约束】中的设定
- 不可编造约束中没有的角色、能力、事件
- 只输出修改后的完整章节正文''';
    
    try {
      final revisedContent = await _callLLM(writerConfig, NovelPromptPresets.reviser, revisionPrompt);
      return revisedContent;
    } catch (e) {
      return originalContent; // 修订失败，返回原内容
    }
  }

  /// 更新任务的审查反馈（不改变状态）
  void _updateTaskFeedback(String taskId, String feedback) {
    final updatedTasks = state.allTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(reviewFeedback: feedback);
      }
      return t;
    }).toList();
    state = state.copyWith(allTasks: updatedTasks);
    _saveState();
  }
  
  void _updateTaskStatus(String taskId, TaskStatus status) {
    final updatedTasks = state.allTasks.map((t) {
      return t.id == taskId ? t.copyWith(status: status) : t;
    }).toList();
    state = state.copyWith(allTasks: updatedTasks);
    _saveState();
  }

  // ========== Project Management ==========
  void createProject(String name, {WorldContext? worldContext}) {
    final project = NovelProject.create(name, worldContext: worldContext);
    state = state.copyWith(
      projects: [...state.projects, project],
      selectedProjectId: project.id,
      selectedChapterId: project.chapters.isNotEmpty ? project.chapters.first.id : null,
    );
    _saveState();
  }

  void selectProject(String projectId) {
    final project = state.projects.firstWhere((p) => p.id == projectId);
    state = state.copyWith(
      selectedProjectId: projectId,
      selectedChapterId: project.chapters.isNotEmpty ? project.chapters.first.id : null,
      selectedTaskId: null,
    );
    _saveState();
  }

  void deleteProject(String projectId) {
    final updatedProjects = state.projects.where((p) => p.id != projectId).toList();
    final project = state.projects.firstWhere((p) => p.id == projectId);
    final updatedTasks = state.allTasks.where((t) {
      return !project.chapters.any((c) => c.id == t.chapterId);
    }).toList();
    
    state = state.copyWith(
      projects: updatedProjects,
      allTasks: updatedTasks,
      selectedProjectId: updatedProjects.isNotEmpty ? updatedProjects.first.id : null,
      selectedChapterId: null,
      selectedTaskId: null,
    );
    _saveState();
  }

  // ========== Outline Management ==========
  Future<void> generateOutline(String requirement) async {
    if (state.selectedProject == null) return;
    
    // 开始生成大纲，设置 loading 状态
    state = state.copyWith(isGeneratingOutline: true);
    
    final outlineConfig = state.outlineModel;
    
    if (outlineConfig == null) {
      // Fallback: use requirement as outline directly
      _updateProjectOutline('【故事需求】\n$requirement\n\n（请编辑此大纲后点击"生成章节"）');
      state = state.copyWith(isGeneratingOutline: false);
      return;
    }
    
    try {
      final systemPrompt = outlineConfig.systemPrompt.isNotEmpty 
          ? outlineConfig.systemPrompt 
          : NovelPromptPresets.outline;
      
      final result = await _callLLM(outlineConfig, systemPrompt, requirement);
      _updateProjectOutline(result);
      
    } catch (e) {
      _updateProjectOutline('生成大纲失败：$e\n\n原始需求：\n$requirement');
    }
    
    // 生成完成，清除 loading 状态
    state = state.copyWith(isGeneratingOutline: false);
  }

  void _updateProjectOutline(String outline) {
    if (state.selectedProject == null) return;
    
    final updatedProject = state.selectedProject!.copyWith(outline: outline);
    final updatedProjects = state.projects.map((p) => p.id == updatedProject.id ? updatedProject : p).toList();
    
    state = state.copyWith(projects: updatedProjects);
    _saveState();
  }

  void updateProjectOutline(String outline) {
    _updateProjectOutline(outline);
  }

  void clearChaptersAndTasks() {
    if (state.selectedProject == null) return;
    
    final updatedProject = state.selectedProject!.copyWith(chapters: []);
    final updatedProjects = state.projects.map((p) => p.id == updatedProject.id ? updatedProject : p).toList();
    
    // Remove all tasks for this project's chapters
    final projectChapterIds = state.selectedProject!.chapters.map((c) => c.id).toSet();
    final updatedTasks = state.allTasks.where((t) => !projectChapterIds.contains(t.chapterId)).toList();
    
    state = state.copyWith(
      projects: updatedProjects,
      allTasks: updatedTasks,
      selectedChapterId: null,
      selectedTaskId: null,
    );
    _saveState();
  }

  /// 重新执行所有任务：重置所有任务状态，清空已生成内容，从头开始
  void restartAllTasks() {
    if (state.selectedProject == null) return;
    
    final projectChapterIds = state.selectedProject!.chapters.map((c) => c.id).toSet();
    
    // Reset all tasks in this project to pending status, clear content and feedback
    final updatedTasks = state.allTasks.map((t) {
      if (projectChapterIds.contains(t.chapterId)) {
        return t.copyWith(
          status: TaskStatus.pending,
          content: null,
          reviewFeedback: null,
          retryCount: 0,
        );
      }
      return t;
    }).toList();
    
    state = state.copyWith(
      allTasks: updatedTasks,
      isRunning: false,
      isPaused: false,
    );
    _saveState();
  }

  // ========== World Context Management ==========
  void updateWorldContext(WorldContext context) {
    if (state.selectedProject == null) return;
    
    final updatedProject = state.selectedProject!.copyWith(worldContext: context);
    final updatedProjects = state.projects.map((p) => p.id == updatedProject.id ? updatedProject : p).toList();
    
    state = state.copyWith(projects: updatedProjects);
    _saveState();
  }

  /// 清空世界设定数据，但保留开关状态
  void clearWorldContext() {
    if (state.selectedProject == null) return;
    
    final ctx = state.selectedProject!.worldContext;
    final clearedContext = WorldContext(
      rules: const {},
      characters: const {},
      relationships: const {},
      locations: const {},
      foreshadowing: const [],
      // 保留 include 开关状态
      includeRules: ctx.includeRules,
      includeCharacters: ctx.includeCharacters,
      includeRelationships: ctx.includeRelationships,
      includeLocations: ctx.includeLocations,
      includeForeshadowing: ctx.includeForeshadowing,
    );
    updateWorldContext(clearedContext);
  }

  void toggleContextCategory(String category, bool enabled) {
    if (state.selectedProject == null) return;
    
    final ctx = state.selectedProject!.worldContext;
    WorldContext updated;
    switch (category) {
      case 'characters':
        updated = ctx.copyWith(includeCharacters: enabled);
        break;
      case 'relationships':
        updated = ctx.copyWith(includeRelationships: enabled);
        break;
      case 'locations':
        updated = ctx.copyWith(includeLocations: enabled);
        break;
      case 'foreshadowing':
        updated = ctx.copyWith(includeForeshadowing: enabled);
        break;
      case 'rules':
        updated = ctx.copyWith(includeRules: enabled);
        break;
      default:
        return;
    }
    updateWorldContext(updated);
  }

  /// Auto-extract context changes from completed chapter content (Data Agent)
  Future<void> _extractContextUpdates(String content) async {
    if (state.selectedProject == null) return;
    
    // 使用大纲模型（或降级到写作模型）进行数据提取
    final extractorModel = state.outlineModel ?? state.writerModel;
    if (extractorModel == null) return;
    
    try {
      final result = await _callLLM(
        extractorModel, 
        NovelPromptPresets.contextExtractor, 
        content,
      );
      
      final updates = jsonDecode(result) as Map<String, dynamic>;
      final ctx = state.selectedProject!.worldContext;
      
      // Merge updates into existing context
      final newCharacters = Map<String, String>.from(ctx.characters);
      final newRules = Map<String, String>.from(ctx.rules);
      final newRelationships = Map<String, String>.from(ctx.relationships);
      final newLocations = Map<String, String>.from(ctx.locations);
      final newForeshadowing = List<String>.from(ctx.foreshadowing);
      
      // 处理新角色
      if (updates['newCharacters'] != null) {
        newCharacters.addAll(Map<String, String>.from(updates['newCharacters'] as Map));
      }
      
      // 处理角色状态更新（Data Agent 核心功能）
      // 当角色发生变化时（如升级、获得物品），更新其描述
      if (updates['characterUpdates'] != null) {
        final charUpdates = Map<String, String>.from(updates['characterUpdates'] as Map);
        for (final entry in charUpdates.entries) {
          final charName = entry.key;
          final updateDesc = entry.value;
          if (newCharacters.containsKey(charName)) {
            // 追加状态变化到现有描述
            final existing = newCharacters[charName]!;
            newCharacters[charName] = '$existing【最新】$updateDesc';
          } else {
            // 如果角色不存在，作为新角色添加
            newCharacters[charName] = updateDesc;
          }
        }
      }

      // 处理新规则
      if (updates['newRules'] != null) {
        newRules.addAll(Map<String, String>.from(updates['newRules'] as Map));
      }

      // 处理规则状态更新
      if (updates['ruleUpdates'] != null) {
        final ruleUpdates = Map<String, String>.from(updates['ruleUpdates'] as Map);
        for (final entry in ruleUpdates.entries) {
          final ruleName = entry.key;
          final updateDesc = entry.value;
          if (newRules.containsKey(ruleName)) {
            final existing = newRules[ruleName]!;
            newRules[ruleName] = '$existing【最新】$updateDesc';
          } else {
            newRules[ruleName] = updateDesc;
          }
        }
      }
      
      if (updates['updatedRelationships'] != null) {
        newRelationships.addAll(Map<String, String>.from(updates['updatedRelationships'] as Map));
      }
      if (updates['newLocations'] != null) {
        newLocations.addAll(Map<String, String>.from(updates['newLocations'] as Map));
      }
      if (updates['newForeshadowing'] != null) {
        final newItems = List<String>.from(updates['newForeshadowing'] as List);
        for (final item in newItems) {
          if (!newForeshadowing.contains(item)) {
            newForeshadowing.add(item);
          }
        }
      }
      if (updates['resolvedForeshadowing'] != null) {
        final resolved = List<String>.from(updates['resolvedForeshadowing'] as List);
        newForeshadowing.removeWhere((f) => resolved.contains(f));
      }
      
      updateWorldContext(ctx.copyWith(
        characters: newCharacters,
        rules: newRules,
        relationships: newRelationships,
        locations: newLocations,
        foreshadowing: newForeshadowing,
      ));
      
    } catch (e) {
      // Silently ignore extraction errors
    }
  }

  // ========== Chapter Management ==========
  void addChapter(String title) {
    if (state.selectedProject == null) return;
    
    final newChapter = NovelChapter(
      id: const Uuid().v4(),
      title: title,
      order: state.selectedProject!.chapters.length,
    );
    
    final updatedProject = state.selectedProject!.copyWith(
      chapters: [...state.selectedProject!.chapters, newChapter],
    );
    
    final updatedProjects = state.projects.map((p) {
      return p.id == updatedProject.id ? updatedProject : p;
    }).toList();
    
    state = state.copyWith(
      projects: updatedProjects,
      selectedChapterId: newChapter.id,
    );
    _saveState();
  }

  void selectChapter(String chapterId) {
    state = state.copyWith(selectedChapterId: chapterId, selectedTaskId: null);
    _saveState();
  }

  void deleteChapter(String chapterId) {
    if (state.selectedProject == null) return;
    
    final updatedChapters = state.selectedProject!.chapters.where((c) => c.id != chapterId).toList();
    final updatedProject = state.selectedProject!.copyWith(chapters: updatedChapters);
    final updatedProjects = state.projects.map((p) => p.id == updatedProject.id ? updatedProject : p).toList();
    final updatedTasks = state.allTasks.where((t) => t.chapterId != chapterId).toList();
    
    state = state.copyWith(
      projects: updatedProjects,
      allTasks: updatedTasks,
      selectedChapterId: updatedChapters.isNotEmpty ? updatedChapters.first.id : null,
    );
    _saveState();
  }

  // ========== Task Management ==========
  void addTask(String description) {
    if (state.selectedChapterId == null) return;
    
    final task = NovelTask(
      id: const Uuid().v4(),
      chapterId: state.selectedChapterId!,
      description: description,
      status: TaskStatus.pending,
    );
    state = state.copyWith(allTasks: [...state.allTasks, task]);
    _saveState();
  }

  void selectTask(String taskId) {
    state = state.copyWith(selectedTaskId: taskId);
  }

  /// Decompose the project's outline into chapters (Multi-stage Batch Processing)
  Future<void> decomposeFromOutline() async {
    if (state.selectedProject == null) return;
    
    final outline = state.selectedProject!.outline;
    if (outline == null || outline.isEmpty) return;
    
    // 开始拆解，设置 loading 状态
    state = state.copyWith(isDecomposing: true);
    
    final decomposeConfig = state.decomposeModel;
    if (decomposeConfig == null) {
      state = state.copyWith(isDecomposing: false);
      return;
    }
    
    try {
      // --- 第一阶段：获取完整的章节标题列表 ---
      print('🚀 Phase 1: Planning chapter list...');
      final listResult = await _callLLM(
        decomposeConfig, 
        NovelPromptPresets.chapterListPlanner, 
        '大纲内容如下：\n$outline'
      );
      
      final List<String> allTitles = List<String>.from(jsonDecode(_cleanJson(listResult)));
      if (allTitles.isEmpty) throw Exception('No chapters planned.');
      
      print('✅ Planned ${allTitles.length} chapters. Starting batch detailing...');
      
      // 清空当前项目的现有章节和任务（因为是重新生成）
      // 注意：这里建议用户手动清空，或者我们在这里帮他清空
      // 为了安全，我们这里采用“渐进式添加”，但如果用户点击了重新生成，通常期望是覆盖。
      // 先记录已有的任务（如果想保留可以不清空，这里我们选择清空当前项目关联的任务）
      
      // --- 第二阶段：分批次填充详细细纲 ---
      const int batchSize = 10; // 每批处理10章，提高效率的同时保持足够的描述细节
      final List<NovelChapter> allNewChapters = [];
      final List<NovelTask> allNewTasks = [];
      String runningContext = '书籍初始状态：一切尚待开始。';
      
      for (int i = 0; i < allTitles.length; i += batchSize) {
        if (_shouldStop) break;
        
        const int maxRetries = 2;
        bool batchSuccess = false;
        
        for (int retry = 0; retry <= maxRetries; retry++) {
          try {
            if (retry > 0) {
              print('🔄 Retrying batch ${i + 1} (Attempt ${retry + 1}/3)...');
              await Future.delayed(const Duration(seconds: 1));
            }

            final end = (i + batchSize < allTitles.length) ? i + batchSize : allTitles.length;
            final batchTitles = allTitles.sublist(i, end);
            
            print('📦 Processing batch: ${i + 1} - $end / ${allTitles.length}');
            
            final detailPrompt = '以下是全书大纲：\n$outline\n\n'
                '【前文进度总结】：\n$runningContext\n\n'
                '请针对以下章节列表生成剧本级细纲：\n${batchTitles.join('\n')}';
            
            final systemPrompt = decomposeConfig.systemPrompt.isNotEmpty 
                ? decomposeConfig.systemPrompt 
                : NovelPromptPresets.decompose;
                
            final detailResult = await _callLLM(decomposeConfig, systemPrompt, detailPrompt);
            final dynamic decodedData = jsonDecode(_cleanJson(detailResult));
            
            List<dynamic> detailedChapters = [];
            if (decodedData is List) {
              detailedChapters = decodedData;
            } else if (decodedData is Map && decodedData.containsKey('chapters')) {
              detailedChapters = decodedData['chapters'] as List<dynamic>;
            }
            
            String batchContentForSummary = '';
            for (var chapterData in detailedChapters) {
              final chapterId = const Uuid().v4();
              final title = chapterData['title'] as String;
              final description = chapterData['description'] as String;
              
              batchContentForSummary += '标题：$title\n内容概要：$description\n---\n';
              
              final chapter = NovelChapter(
                id: chapterId,
                title: title,
                order: allNewChapters.length,
              );
              
              final task = NovelTask(
                id: const Uuid().v4(),
                chapterId: chapterId,
                description: description,
                status: TaskStatus.pending,
              );
              
              allNewChapters.add(chapter);
              allNewTasks.add(task);
            }
            
            // --- 专项总结阶段：解耦调用总结官 ---
            try {
              print('📝 Summarizing batch for next context...');
              final summaryInput = '【本批次细纲内容】：\n$batchContentForSummary\n\n【旧进度总结】：\n$runningContext';
              final summaryResult = await _callLLM(decomposeConfig, NovelPromptPresets.batchSummarizer, summaryInput);
              runningContext = _cleanJson(summaryResult);
            } catch (e) {
              print('⚠️ Summarization failed, using basic concatenation: $e');
              runningContext += '\n(由于总结失败，仅记录标题) ' + batchTitles.join(', ');
            }
            
            // 每一批次更新一次 UI 进度
            final currentProject = state.selectedProject!;
            final updatedProject = currentProject.copyWith(
              chapters: [...allNewChapters],
            );
            final updatedProjects = state.projects.map((p) => p.id == updatedProject.id ? updatedProject : p).toList();
            
            state = state.copyWith(
              projects: updatedProjects,
              allTasks: [...state.allTasks.where((t) => !_isTaskInCurrentProject(t)), ...allNewTasks],
            );
            _saveState();
            
            batchSuccess = true;
            break; // 成功则跳出重试循环
            
          } catch (e) {
            print('⚠️ Batch attempt ${retry + 1} failed: $e');
            if (retry == maxRetries) {
              print('❌ Max retries reached for batch starting at index $i. Pausing decomposition.');
              state = state.copyWith(isDecomposing: false);
              _shouldStop = true;
              return; 
            }
          }
        }
        
        if (!batchSuccess) break;
      }
      
    } catch (e) {
      print('❌ Decomposition failed: $e');
    } finally {
      state = state.copyWith(isDecomposing: false);
    }
  }

  String _cleanJson(String content) {
    if (content.isEmpty) return '[]';
    
    String jsonContent = content.trim();
    
    // 1. 提取 Markdown 代码块中的内容
    if (jsonContent.contains('```')) {
      // 尝试匹配 ```json ... ``` 或 ``` ... ```
      final RegExp codeBlockRegExp = RegExp(r'```(?:json)?\s*([\s\S]*?)(?:```|$)');
      final match = codeBlockRegExp.firstMatch(jsonContent);
      if (match != null && match.groupCount >= 1) {
        jsonContent = match.group(1)!.trim();
      }
    }
    
    // 2. 找到第一个 [ 或 {
    int firstBracket = jsonContent.indexOf('[');
    int firstBrace = jsonContent.indexOf('{');
    int start = -1;
    if (firstBracket != -1 && firstBrace != -1) {
      start = firstBracket < firstBrace ? firstBracket : firstBrace;
    } else {
      start = firstBracket != -1 ? firstBracket : firstBrace;
    }
    
    if (start == -1) return '[]'; // 没找到 JSON 结构
    
    jsonContent = jsonContent.substring(start);
    
    // 3. 尝试修复截断的 JSON
    return _repairJson(jsonContent);
  }

  String _repairJson(String json) {
    if (json.isEmpty) return '[]';
    
    String repaired = json.trim();
    List<String> stack = [];
    bool inString = false;
    bool escaped = false;
    
    int lastValidPos = -1;
    
    for (int i = 0; i < repaired.length; i++) {
        String char = repaired[i];
        
        if (escaped) {
            escaped = false;
            continue;
        }
        
        if (char == '\\') {
            escaped = true;
            continue;
        }
        
        if (char == '"') {
            inString = !inString;
            continue;
        }
        
        if (!inString) {
            if (char == '[' || char == '{') {
                stack.add(char);
            } else if (char == ']') {
                if (stack.isNotEmpty && stack.last == '[') {
                    stack.removeLast();
                    if (stack.isEmpty) lastValidPos = i;
                }
            } else if (char == '}') {
                if (stack.isNotEmpty && stack.last == '{') {
                    stack.removeLast();
                    if (stack.isEmpty) lastValidPos = i;
                }
            }
        }
    }
    
    // 如果 JSON 已经完整（栈为空），但后面跟着杂质（如 extra quotes）
    if (stack.isEmpty && lastValidPos != -1 && lastValidPos < repaired.length - 1) {
        repaired = repaired.substring(0, lastValidPos + 1);
    }
    
    // 如果在字符串内部截断，先闭合字符串
    if (inString) {
        repaired += '"';
    }
    
    // 补齐缺失的括号（倒序补齐）
    while (stack.isNotEmpty) {
        String last = stack.removeLast();
        if (last == '[') {
            repaired += ']';
        } else if (last == '{') {
            repaired += '}';
        }
    }
    
    try {
      jsonDecode(repaired);
      return repaired;
    } catch (_) {
      return repaired;
    }
  }

  void updateTaskStatus(String taskId, TaskStatus status) {
    _updateTaskStatus(taskId, status);
  }

  /// Execute a single task (called when user clicks "Run Task" button)
  Future<void> runSingleTask(String taskId) async {
    final task = state.allTasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => NovelTask(id: '', chapterId: '', description: '', status: TaskStatus.pending),
    );
    
    if (task.id.isEmpty) return;
    if (task.status == TaskStatus.running) return; // Already running
    
    await _executeTask(taskId);
  }

  void updateTaskDescription(String taskId, String newDescription) {
    final updatedTasks = state.allTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(description: newDescription);
      }
      return t;
    }).toList();
    state = state.copyWith(allTasks: updatedTasks);
    _saveState();
  }
  
  void deleteTask(String taskId) {
    state = state.copyWith(
      allTasks: state.allTasks.where((t) => t.id != taskId).toList(),
      selectedTaskId: state.selectedTaskId == taskId ? null : state.selectedTaskId,
    );
    _saveState();
  }

  // ========== Controls ==========
  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
    _saveState();
  }

  void toggleReviewMode(bool enabled) {
    state = state.copyWith(isReviewEnabled: enabled);
    _saveState();
  }
  
  void startQueue() {
    runWorkflow();
  }
  
  void stopQueue() {
    _shouldStop = true;
    
    // 重置所有正在运行的任务状态为 pending，避免一直转圈
    final updatedTasks = state.allTasks.map((t) {
      if (t.status == TaskStatus.running || t.status == TaskStatus.reviewing) {
        return t.copyWith(status: TaskStatus.pending);
      }
      return t;
    }).toList();
    
    state = state.copyWith(
      isRunning: false, 
      isPaused: false,
      isDecomposing: false,  // 也重置拆解状态
      allTasks: updatedTasks,
    );
    _saveState();
  }

  // ========== Model Configuration ==========
  void setOutlineModel(NovelModelConfig? config) {
    state = state.copyWith(outlineModel: config);
    _saveState();
  }
  
  void setOutlinePrompt(String prompt) {
    if (state.outlineModel != null) {
      state = state.copyWith(outlineModel: state.outlineModel!.copyWith(systemPrompt: prompt));
      _saveState();
    }
  }

  void setDecomposeModel(NovelModelConfig? config) {
    state = state.copyWith(decomposeModel: config);
    _saveState();
  }
  
  void setDecomposePrompt(String prompt) {
    if (state.decomposeModel != null) {
      state = state.copyWith(decomposeModel: state.decomposeModel!.copyWith(systemPrompt: prompt));
      _saveState();
    }
  }

  void setWriterModel(NovelModelConfig? config) {
    state = state.copyWith(writerModel: config);
    _saveState();
  }
  
  void setWriterPrompt(String prompt) {
    if (state.writerModel != null) {
      state = state.copyWith(writerModel: state.writerModel!.copyWith(systemPrompt: prompt));
      _saveState();
    }
  }

  void setReviewerModel(NovelModelConfig? config) {
    state = state.copyWith(reviewerModel: config);
    _saveState();
  }
  
  void setReviewerPrompt(String prompt) {
    if (state.reviewerModel != null) {
      state = state.copyWith(reviewerModel: state.reviewerModel!.copyWith(systemPrompt: prompt));
      _saveState();
    }
  }

  // ========== Novel Prompt Presets ==========
  void addPromptPreset(NovelPromptPreset preset) {
    state = state.copyWith(
      promptPresets: [...state.promptPresets, preset],
    );
    _saveState();
  }

  void deletePromptPreset(String presetId) {
    state = state.copyWith(
      promptPresets: state.promptPresets.where((p) => p.id != presetId).toList(),
    );
    _saveState();
  }
}
