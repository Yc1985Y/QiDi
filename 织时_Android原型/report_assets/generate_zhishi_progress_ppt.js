const fs = require("fs");
const path = require("path");
const PptxGenJS = require("pptxgenjs");

const OUT_DIR = path.join(__dirname);
const OUT_FILE = path.join(OUT_DIR, "织时_项目汇报_20260609.pptx");
const ICON_PATH = path.join(
  __dirname,
  "..",
  "app",
  "src",
  "main",
  "res",
  "drawable-nodpi",
  "ic_launcher_foreground_exact.png",
);

const COLORS = {
  bg: "F8F5EF",
  panel: "FFFCF6",
  panelSoft: "F2ECE2",
  panelBlue: "EEF7F9",
  panelGold: "FFF4D1",
  panelGreen: "EFF7EF",
  ink: "4A3517",
  body: "705B33",
  muted: "9A875E",
  primary: "F4C64A",
  primaryDeep: "D7A82C",
  sky: "A8D7E2",
  skyDeep: "74BACA",
  green: "89B68A",
  warning: "E7B060",
  line: "E7D9B6",
  white: "FFFFFF",
  softRed: "F6E6DE",
};

const FONT_TITLE = "Microsoft YaHei";
const FONT_BODY = "Microsoft YaHei";
const FONT_MONO = "Consolas";

fs.mkdirSync(OUT_DIR, { recursive: true });

const pptx = new PptxGenJS();
pptx.layout = "LAYOUT_WIDE";
pptx.author = "Codex";
pptx.company = "织时 TimeWeaver";
pptx.subject = "《织时》项目阶段汇报";
pptx.title = "织时_项目汇报_20260609";
pptx.lang = "zh-CN";
pptx.theme = {
  headFontFace: FONT_TITLE,
  bodyFontFace: FONT_BODY,
  lang: "zh-CN",
};

function addAmbient(slide, deep = false) {
  slide.background = { color: deep ? "F4EFD9" : COLORS.bg };
  slide.addShape(pptx.ShapeType.ellipse, {
    x: -0.2,
    y: 5.4,
    w: 3.1,
    h: 2.0,
    line: { color: COLORS.bg, transparency: 100 },
    fill: { color: COLORS.primary, transparency: 82 },
  });
  slide.addShape(pptx.ShapeType.ellipse, {
    x: 9.8,
    y: -0.3,
    w: 3.2,
    h: 2.1,
    line: { color: COLORS.bg, transparency: 100 },
    fill: { color: COLORS.sky, transparency: 84 },
  });
  slide.addShape(pptx.ShapeType.ellipse, {
    x: 10.9,
    y: 5.9,
    w: 1.4,
    h: 0.8,
    line: { color: COLORS.bg, transparency: 100 },
    fill: { color: COLORS.primary, transparency: 88 },
  });
}

function addFooter(slide, pageNo, total, source = "资料依据：README / 作品描述 / 进度说明 / 配置说明") {
  slide.addText(source, {
    x: 0.7,
    y: 7.05,
    w: 8.8,
    h: 0.2,
    fontFace: FONT_BODY,
    fontSize: 8.5,
    color: COLORS.muted,
    margin: 0,
  });
  slide.addText(`${pageNo}/${total}`, {
    x: 11.9,
    y: 7.0,
    w: 0.7,
    h: 0.22,
    fontFace: FONT_MONO,
    fontSize: 9,
    color: COLORS.muted,
    bold: true,
    align: "right",
    margin: 0,
  });
}

function addKicker(slide, text, x = 0.72, y = 0.45, w = 1.4, h = 0.34) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x,
    y,
    w,
    h,
    rectRadius: 0.08,
    line: { color: COLORS.primary, transparency: 100 },
    fill: { color: COLORS.primary },
  });
  slide.addText(text, {
    x,
    y: y + 0.02,
    w,
    h: h - 0.03,
    fontFace: FONT_BODY,
    fontSize: 10,
    color: COLORS.white,
    bold: true,
    align: "center",
    valign: "mid",
    margin: 0,
  });
}

function addHeader(slide, kicker, title, subtitle) {
  addKicker(slide, kicker);
  slide.addText(title, {
    x: 0.72,
    y: 0.9,
    w: 11.0,
    h: 0.72,
    fontFace: FONT_TITLE,
    fontSize: 24,
    color: COLORS.ink,
    bold: true,
    margin: 0,
  });
  if (subtitle) {
    slide.addText(subtitle, {
      x: 0.72,
      y: 1.58,
      w: 11.2,
      h: 0.38,
      fontFace: FONT_BODY,
      fontSize: 11.5,
      color: COLORS.body,
      margin: 0,
    });
  }
  slide.addShape(pptx.ShapeType.line, {
    x: 0.72,
    y: 1.98,
    w: 11.72,
    h: 0,
    line: { color: COLORS.line, pt: 1.2 },
  });
}

function addCard(slide, {
  x, y, w, h,
  title,
  body,
  fill = COLORS.panel,
  titleColor = COLORS.ink,
  bodyColor = COLORS.body,
  accent = COLORS.primary,
  radius = 0.16,
  titleSize = 15,
  bodySize = 11.2,
  mono = false,
}) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x, y, w, h,
    rectRadius: radius,
    line: { color: COLORS.white, transparency: 40, pt: 1 },
    fill: { color: fill },
    shadow: {
      type: "outer",
      color: "D9CCAA",
      blur: 2,
      angle: 45,
      distance: 1,
      opacity: 0.12,
    },
  });
  slide.addShape(pptx.ShapeType.rect, {
    x: x + 0.02,
    y: y + 0.02,
    w: 0.07,
    h: h - 0.04,
    line: { color: accent, transparency: 100 },
    fill: { color: accent },
  });
  if (title) {
    slide.addText(title, {
      x: x + 0.18,
      y: y + 0.14,
      w: w - 0.3,
      h: 0.34,
      fontFace: FONT_TITLE,
      fontSize: titleSize,
      color: titleColor,
      bold: true,
      margin: 0,
      fit: "shrink",
    });
  }
  slide.addText(body, {
    x: x + 0.18,
    y: y + 0.52,
    w: w - 0.28,
    h: h - 0.64,
    fontFace: mono ? FONT_MONO : FONT_BODY,
    fontSize: bodySize,
    color: bodyColor,
    margin: 0,
    breakLine: false,
    fit: "shrink",
    valign: "top",
  });
}

function addNumberBadge(slide, n, x, y, fill) {
  slide.addShape(pptx.ShapeType.ellipse, {
    x,
    y,
    w: 0.46,
    h: 0.46,
    line: { color: fill, transparency: 100 },
    fill: { color: fill },
  });
  slide.addText(String(n), {
    x,
    y: y + 0.02,
    w: 0.46,
    h: 0.4,
    align: "center",
    valign: "mid",
    fontFace: FONT_MONO,
    fontSize: 11,
    color: COLORS.white,
    bold: true,
    margin: 0,
  });
}

function addTimelineNode(slide, { x, y, date, title, body, up = true }) {
  slide.addShape(pptx.ShapeType.ellipse, {
    x,
    y,
    w: 0.22,
    h: 0.22,
    line: { color: COLORS.primary, pt: 1.4 },
    fill: { color: COLORS.white },
  });
  slide.addShape(pptx.ShapeType.ellipse, {
    x: x + 0.05,
    y: y + 0.05,
    w: 0.12,
    h: 0.12,
    line: { color: COLORS.primary, transparency: 100 },
    fill: { color: COLORS.primary },
  });
  const cardY = up ? y - 1.45 : y + 0.32;
  slide.addShape(pptx.ShapeType.line, {
    x: x + 0.11,
    y: up ? y : y + 0.22,
    w: 0,
    h: up ? -0.42 : 0.42,
    line: { color: COLORS.line, pt: 1 },
  });
  addCard(slide, {
    x: x - 0.64,
    y: cardY,
    w: 1.58,
    h: 1.12,
    title: date,
    body: `${title}\n${body}`,
    fill: COLORS.panel,
    accent: up ? COLORS.primary : COLORS.skyDeep,
    titleSize: 12.2,
    bodySize: 9.5,
  });
}

function slide01() {
  const slide = pptx.addSlide();
  addAmbient(slide, true);

  slide.addShape(pptx.ShapeType.roundRect, {
    x: 0.72,
    y: 0.82,
    w: 5.65,
    h: 5.82,
    rectRadius: 0.22,
    line: { color: COLORS.white, transparency: 70 },
    fill: { color: COLORS.panel },
  });

  slide.addText("织时", {
    x: 1.05,
    y: 1.18,
    w: 2.4,
    h: 0.6,
    fontFace: FONT_TITLE,
    fontSize: 30,
    bold: true,
    color: COLORS.ink,
    margin: 0,
  });
  slide.addText("TimeWeaver", {
    x: 1.05,
    y: 1.8,
    w: 2.2,
    h: 0.3,
    fontFace: FONT_MONO,
    fontSize: 12,
    bold: true,
    color: COLORS.primaryDeep,
    margin: 0,
  });
  slide.addText("项目阶段汇报", {
    x: 1.05,
    y: 2.36,
    w: 4.1,
    h: 0.5,
    fontFace: FONT_TITLE,
    fontSize: 22,
    bold: true,
    color: COLORS.ink,
    margin: 0,
  });
  slide.addText("从设计思维流程到项目推进全过程", {
    x: 1.05,
    y: 2.92,
    w: 4.6,
    h: 0.35,
    fontFace: FONT_BODY,
    fontSize: 12.5,
    color: COLORS.body,
    margin: 0,
  });
  slide.addText("将校园信息碎片整理成清晰时间线", {
    x: 1.05,
    y: 3.56,
    w: 4.4,
    h: 0.35,
    fontFace: FONT_BODY,
    fontSize: 15.5,
    color: COLORS.primaryDeep,
    bold: true,
    margin: 0,
  });
  addCard(slide, {
    x: 1.02,
    y: 4.14,
    w: 4.78,
    h: 1.28,
    title: "本次汇报关注三件事",
    body: "• 我们为什么要做“信息降噪”\n• 设计如何转成可落地的交互结构\n• 工程如何把大模型能力约束为可信闭环",
    fill: COLORS.panelGold,
    accent: COLORS.primary,
    titleSize: 14.2,
    bodySize: 10.6,
  });
  slide.addText("团队：________________", {
    x: 1.06,
    y: 6.18,
    w: 3.2,
    h: 0.22,
    fontFace: FONT_BODY,
    fontSize: 10.8,
    color: COLORS.muted,
    margin: 0,
  });

  slide.addImage({
    path: ICON_PATH,
    x: 7.65,
    y: 1.2,
    w: 4.2,
    h: 4.2,
  });

  addCard(slide, {
    x: 7.22,
    y: 5.56,
    w: 5.1,
    h: 0.92,
    title: "汇报定位",
    body: "这是一份“过程型项目汇报”，重点展示问题洞察、产品定义、架构设计、迭代修复与当前交付状态。",
    fill: COLORS.panelBlue,
    accent: COLORS.skyDeep,
    titleSize: 13.4,
    bodySize: 10.3,
  });
  addFooter(slide, 1, 14);
}

function slide02() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "AGENDA", "本次汇报围绕“问题—方案—落地—进展”四条线展开", "不再把《织时》当作单点功能，而是把它作为一个逐步收口成型的产品系统来讲述。");

  const items = [
    ["01", "设计思维起点", "从校园信息焦虑、跨 App 录入成本和认知负担出发，明确真正要解决的问题。", COLORS.panelGold],
    ["02", "产品定义收敛", "把“能识别”推进为“能理解、能确认、能执行、能沉淀”的 Visual-to-Tool 智能体。", COLORS.panel],
    ["03", "设计原则与界面", "Today-First、信息降噪、Bento UI、人在回路，形成三页主结构和交互边界。", COLORS.panelBlue],
    ["04", "工程架构与风控", "多模态输入、OCR+LLM、结构化 JSON、RiskPolicyEngine、系统 Intent 调度。", COLORS.panel],
    ["05", "项目推进与修复", "从 API 接入、账号闭环到多事项识别、提醒语义和“我的页”分层持续迭代。", COLORS.panelGold],
    ["06", "当前成果与后续", "总结已经打通的主链路、仍需继续优化的边界，以及后续演示/实机推进方向。", COLORS.panelGreen],
  ];

  let idx = 0;
  for (let r = 0; r < 2; r += 1) {
    for (let c = 0; c < 3; c += 1) {
      const [n, t, b, fill] = items[idx];
      const x = 0.88 + c * 4.1;
      const y = 2.36 + r * 2.0;
      addCard(slide, {
        x, y, w: 3.58, h: 1.55,
        title: t,
        body: b,
        fill,
        accent: c === 1 ? COLORS.skyDeep : COLORS.primary,
        titleSize: 15,
        bodySize: 10.5,
      });
      addNumberBadge(slide, n, x + 2.94, y + 0.14, c === 1 ? COLORS.skyDeep : COLORS.primaryDeep);
      idx += 1;
    }
  }

  addFooter(slide, 2, 14);
}

function slide03() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "DESIGN THINKING", "设计思维让项目从“做功能”转向“解决真实场景里的混乱输入”", "《织时》的形成不是先画页面，而是先把校园通知场景里的用户摩擦梳理清楚。");

  const steps = [
    { t: "共情\nEmpathize", b: "观察群通知、讲座海报、截图和口头提醒。\n发现用户最痛苦的是“知道有事，但没法立刻转成安排”。", fill: COLORS.panelGold, accent: COLORS.primary },
    { t: "定义\nDefine", b: "问题不只是“识别文本”。\n真正的断层发生在：碎片信息无法稳定变成时间动作。", fill: COLORS.panel, accent: COLORS.skyDeep },
    { t: "构思\nIdeate", b: "提出 Visual-to-Tool。\n让 AI 适应无序输入，而不是继续要求用户学表单规则。", fill: COLORS.panelBlue, accent: COLORS.skyDeep },
    { t: "原型\nPrototype", b: "用 Today-First、Bento UI、确认卡和三页主壳层，把理念落成一个可操作 App。", fill: COLORS.panel, accent: COLORS.primary },
    { t: "测试\nTest", b: "围绕 API 接入、交互闭环、提醒语义、异常边界与实机表现持续修复和验证。", fill: COLORS.panelGreen, accent: COLORS.green },
  ];

  slide.addShape(pptx.ShapeType.line, {
    x: 1.05,
    y: 4.06,
    w: 11.1,
    h: 0,
    line: { color: COLORS.line, pt: 1.4 },
  });

  steps.forEach((s, i) => {
    const x = 0.82 + i * 2.48;
    addCard(slide, {
      x,
      y: 2.55,
      w: 2.02,
      h: 2.38,
      title: s.t,
      body: s.b,
      fill: s.fill,
      accent: s.accent,
      titleSize: 13.5,
      bodySize: 9.6,
    });
    slide.addShape(pptx.ShapeType.ellipse, {
      x: x + 0.82,
      y: 3.95,
      w: 0.34,
      h: 0.34,
      line: { color: s.accent, pt: 1.2 },
      fill: { color: COLORS.white },
    });
    slide.addShape(pptx.ShapeType.ellipse, {
      x: x + 0.91,
      y: 4.04,
      w: 0.16,
      h: 0.16,
      line: { color: s.accent, transparency: 100 },
      fill: { color: s.accent },
    });
  });

  addFooter(slide, 3, 14);
}

function slide04() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "PROBLEM", "校园通知的问题不是“看不懂”，而是“看懂以后仍然要重复劳动”", "传统流程把用户卡在跨应用切换和手动再录入里，《织时》要做的是把这段操作压缩到最短。");

  addCard(slide, {
    x: 0.92, y: 2.32, w: 5.72, h: 3.8,
    title: "传统路径：信息知道了，但秩序没有建立",
    body: "1. 看懂海报/通知/截图\n2. 记住时间、地点、要求\n3. 再打开日历、地图或备忘录\n4. 手动录入并重新检查\n5. 忘记、漏办、错记仍然高频发生",
    fill: COLORS.softRed,
    accent: COLORS.warning,
    titleSize: 15.5,
    bodySize: 13,
  });
  addCard(slide, {
    x: 6.84, y: 2.32, w: 5.56, h: 3.8,
    title: "织时路径：把无序输入压缩成一次可确认执行",
    body: "1. 拍照 / 分享 / 粘贴 / 语音输入\n2. AI 提取结构化事件和建议动作\n3. 用户在确认卡上完成最后授权\n4. 系统写入日历、发起导航、安排提醒\n5. 结果沉淀到个人时间线与本地资产",
    fill: COLORS.panelBlue,
    accent: COLORS.skyDeep,
    titleSize: 15.5,
    bodySize: 13,
  });
  slide.addShape(pptx.ShapeType.chevron, {
    x: 6.24,
    y: 3.73,
    w: 0.42,
    h: 0.54,
    line: { color: COLORS.primaryDeep, transparency: 100 },
    fill: { color: COLORS.primaryDeep },
  });
  slide.addText("AI 去适应用户的无序输入，而不是让用户先学系统规则。", {
    x: 1.22,
    y: 6.36,
    w: 10.4,
    h: 0.28,
    fontFace: FONT_BODY,
    fontSize: 13.2,
    color: COLORS.primaryDeep,
    bold: true,
    align: "center",
    margin: 0,
  });
  addFooter(slide, 4, 14);
}

function slide05() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "DEFINITION", "《织时》把 AI 从聊天工具改造成了一个 Visual-to-Tool 智能体中间层", "它不是单点 OCR，也不是自由对话，而是把输入、理解、风控和系统执行串成完整闭环。");

  addCard(slide, {
    x: 0.9, y: 2.28, w: 3.9, h: 1.8,
    title: "多模态收敛",
    body: "拍照、相册、系统分享、粘贴文本、语音输入统一进入同一条理解链路。",
    fill: COLORS.panelGold,
    accent: COLORS.primary,
  });
  addCard(slide, {
    x: 4.96, y: 2.28, w: 3.9, h: 1.8,
    title: "结构化意图输出",
    body: "大模型被约束为 strict JSON：action + confidence + payload，而不是发散式自然语言。",
    fill: COLORS.panelBlue,
    accent: COLORS.skyDeep,
  });
  addCard(slide, {
    x: 9.02, y: 2.28, w: 3.4, h: 1.8,
    title: "执行前风险闸门",
    body: "RiskPolicyEngine + HITL 负责把“能识别”提升为“敢执行”。",
    fill: COLORS.panelGreen,
    accent: COLORS.green,
  });

  addCard(slide, {
    x: 0.92, y: 4.38, w: 5.24, h: 1.62,
    title: "一句话定位",
    body: "面向高校场景的智能体原型：把校园通知、海报、截图和语音，重构为可确认、可提醒、可回看的个人时间线。",
    fill: COLORS.panel,
    accent: COLORS.primary,
    bodySize: 11.4,
  });
  addCard(slide, {
    x: 6.42, y: 4.38, w: 5.98, h: 1.62,
    title: "不是这些，而是这些",
    body: "不是：只会识别图片的 Demo / 传统手填日历 / 无边界聊天助手\n而是：校园信息降噪器 / 时间秩序重构器 / 系统能力调度中间层",
    fill: COLORS.panel,
    accent: COLORS.skyDeep,
    bodySize: 11.2,
  });

  addFooter(slide, 5, 14);
}

function slide06() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "PRINCIPLES", "Today-First、信息降噪与先解释再执行共同塑造了产品体验基线", "设计不是装饰层，而是把复杂 AI 链路压缩成用户一眼就能做决定的界面秩序。");

  const cards = [
    ["Today-First", "首页优先展示“下一件最重要的事”，而不是先让用户面对复杂日历。", COLORS.panelGold, COLORS.primary],
    ["信息降噪", "只保留时间、地点、事件和建议动作，把解释性噪音从首屏剥离。", COLORS.panel, COLORS.skyDeep],
    ["卡片化表达", "Bento UI 为不同任务建立清晰边界，让输入、确认、沉淀各自归位。", COLORS.panelBlue, COLORS.skyDeep],
    ["先解释，再执行", "AI 不越权代办，中高风险动作必须先展示依据，再由用户确认。", COLORS.panel, COLORS.primary],
    ["正常 App 化", "保持首页 / 时间线 / 我的三页结构，避免产品停留在工具演示感。", COLORS.panelGreen, COLORS.green],
  ];

  addCard(slide, {
    x: 0.9, y: 2.35, w: 4.0, h: 1.45,
    title: cards[0][0], body: cards[0][1], fill: cards[0][2], accent: cards[0][3], bodySize: 11,
  });
  addCard(slide, {
    x: 5.05, y: 2.35, w: 3.55, h: 1.45,
    title: cards[1][0], body: cards[1][1], fill: cards[1][2], accent: cards[1][3], bodySize: 11,
  });
  addCard(slide, {
    x: 8.78, y: 2.35, w: 3.62, h: 1.45,
    title: cards[2][0], body: cards[2][1], fill: cards[2][2], accent: cards[2][3], bodySize: 11,
  });
  addCard(slide, {
    x: 0.9, y: 4.02, w: 5.32, h: 1.48,
    title: cards[3][0], body: cards[3][1], fill: cards[3][2], accent: cards[3][3], bodySize: 11,
  });
  addCard(slide, {
    x: 6.46, y: 4.02, w: 5.94, h: 1.48,
    title: cards[4][0], body: cards[4][1], fill: cards[4][2], accent: cards[4][3], bodySize: 11,
  });

  slide.addText("视觉风格基线：Material Design 3 × Bento UI × Glassmorphism × 低饱和暖色系", {
    x: 0.96,
    y: 6.05,
    w: 11.0,
    h: 0.24,
    fontFace: FONT_BODY,
    fontSize: 11.2,
    color: COLORS.primaryDeep,
    bold: true,
    align: "center",
    margin: 0,
  });

  addFooter(slide, 6, 14);
}

function slide07() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "FLOW", "完整主链路已经从多源导入打通到系统执行与时间线沉淀", "产品价值不在某一个识别动作，而在“输入 → 理解 → 决策 → 执行 → 沉淀”的整条链路。");

  const steps = [
    ["01", "多源收敛", "拍照 / 相册 / 分享 / 粘贴 / 语音"],
    ["02", "统一建模", "CampusNoticeInput 屏蔽底层来源差异"],
    ["03", "OCR + LLM", "图片先 OCR，文本与 OCR 结果再送结构化理解"],
    ["04", "结构化输出", "action + confidence + payload + fallback_query"],
    ["05", "风险判定", "字段完整性、阈值与动作等级进入 Policy Engine"],
    ["06", "确认执行", "首页确认卡 + 日历 / 地图 / 提醒 / TTS 调度"],
    ["07", "本地沉淀", "时间线、提醒偏好、导出与资产回看"],
  ];

  steps.forEach((s, i) => {
    const row = i < 4 ? 0 : 1;
    const col = row === 0 ? i : i - 4;
    const x = row === 0 ? 0.92 + col * 3.08 : 2.48 + col * 3.08;
    const y = row === 0 ? 2.42 : 4.55;
    addCard(slide, {
      x, y, w: 2.55, h: 1.46,
      title: `${s[0]}  ${s[1]}`,
      body: s[2],
      fill: i % 2 === 0 ? COLORS.panelGold : COLORS.panelBlue,
      accent: i % 2 === 0 ? COLORS.primary : COLORS.skyDeep,
      titleSize: 12.8,
      bodySize: 10.1,
    });
    if (row === 0 && i < 3) {
      slide.addShape(pptx.ShapeType.chevron, {
        x: x + 2.62,
        y: 2.92,
        w: 0.28,
        h: 0.34,
        line: { color: COLORS.primaryDeep, transparency: 100 },
        fill: { color: COLORS.primaryDeep },
      });
    }
    if (row === 1 && i > 3 && i < 6) {
      slide.addShape(pptx.ShapeType.chevron, {
        x: x + 2.62,
        y: 5.05,
        w: 0.28,
        h: 0.34,
        line: { color: COLORS.skyDeep, transparency: 100 },
        fill: { color: COLORS.skyDeep },
      });
    }
  });

  slide.addShape(pptx.ShapeType.line, {
    x: 10.25,
    y: 3.9,
    w: -7.0,
    h: 0.55,
    line: { color: COLORS.line, pt: 1.1, beginArrowType: "none", endArrowType: "triangle" },
  });

  addFooter(slide, 7, 14);
}

function slide08() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "ARCHITECTURE", "系统架构把大模型能力约束进可维护、可验证的工程边界", "这也是《织时》能够从概念原型走向成熟参赛作品的关键原因。");

  const layers = [
    ["展示层", "首页 / 时间线 / 我的 / 启动页"],
    ["提醒与沉淀层", "ReminderScheduler / DataStore / 导出能力"],
    ["执行层", "IntentDispatcher / Calendar / Map / TTS"],
    ["风险决策层", "RiskPolicyEngine / ActionValidator / fusedConfidence"],
    ["智能理解层", "VLMNetworkClient / OCR / ResponseInterpreter"],
    ["预处理层", "图片读取 / Base64 / 文本归一化"],
    ["输入层", "相机 / 相册 / 分享 / 粘贴 / 语音"],
  ];

  layers.forEach((l, i) => {
    addCard(slide, {
      x: 0.96 + i * 0.12,
      y: 2.18 + i * 0.56,
      w: 5.85 - i * 0.24,
      h: 0.8,
      title: l[0],
      body: l[1],
      fill: i % 2 === 0 ? COLORS.panelGold : COLORS.panelBlue,
      accent: i % 2 === 0 ? COLORS.primary : COLORS.skyDeep,
      titleSize: 12.4,
      bodySize: 10.2,
    });
  });

  addCard(slide, {
    x: 7.15, y: 2.3, w: 5.05, h: 1.02,
    title: "关键代码模块",
    body: "MainActivity · HomeScreenModule · TimelineScreenModule · ProfileScreenModule",
    fill: COLORS.panel,
    accent: COLORS.primary,
    bodySize: 10.4,
    mono: true,
  });
  addCard(slide, {
    x: 7.15, y: 3.52, w: 5.05, h: 1.02,
    title: "模型与接口",
    body: "VLM_APP_ID / VLM_API_KEY 已接入 vivo 真接口\n文本直连 chat/completions；图片走 OCR + LLM 双阶段链路",
    fill: COLORS.panelBlue,
    accent: COLORS.skyDeep,
    bodySize: 10.3,
  });
  addCard(slide, {
    x: 7.15, y: 4.74, w: 5.05, h: 1.02,
    title: "工程边界",
    body: "不回退 mock、不破坏页面基线、不把风控移除、不把执行链重新做成黑盒。",
    fill: COLORS.panelGreen,
    accent: COLORS.green,
    bodySize: 10.3,
  });

  addFooter(slide, 8, 14);
}

function slide09() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "SAFETY", "风险决策与人在回路是项目从 Demo 走向产品的关键分水岭", "《织时》不是把模型结果直接映射成动作，而是让客户端保留最后一层解释、追问和拦截。");

  addCard(slide, {
    x: 0.94, y: 2.32, w: 5.1, h: 3.78,
    title: "Extract → Suggest → Confirm → Execute",
    body: "Extract：获取结构化 JSON 结果\n\nSuggest：校验字段完整性、置信度和动作等级\n\nConfirm：中高风险动作必须进入确认或澄清\n\nExecute：只把被允许的动作映射给系统 Intent",
    fill: COLORS.panel,
    accent: COLORS.primary,
    titleSize: 15,
    bodySize: 11.4,
  });

  addCard(slide, {
    x: 6.32, y: 2.32, w: 6.0, h: 1.22,
    title: "当前动作风险分级",
    body: "send_sms：高风险，绝不自动发送    create_event / navigate：中风险，必须确认    tts_feedback：低风险，可直接播报",
    fill: COLORS.panelGold,
    accent: COLORS.warning,
    titleSize: 14.2,
    bodySize: 10.6,
  });
  addCard(slide, {
    x: 6.32, y: 3.76, w: 6.0, h: 1.02,
    title: "结构化契约",
    body: "action + confidence + payload + fallback_query + target_found",
    fill: COLORS.panelBlue,
    accent: COLORS.skyDeep,
    bodySize: 11.1,
    mono: true,
  });
  addCard(slide, {
    x: 6.32, y: 5.0, w: 6.0, h: 1.1,
    title: "安全价值",
    body: "让评委和用户都能清楚看到：系统为什么建议、为什么拦截、为什么需要再确认。",
    fill: COLORS.panelGreen,
    accent: COLORS.green,
    bodySize: 11.1,
  });

  addFooter(slide, 9, 14);
}

function slide10() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "UI / IA", "三页主结构让高频操作、资产沉淀和控制中枢各归其位", "视觉上保持 Minimalist Tech + Bento UI，信息上坚持先焦点、再结构、再控制。");

  addCard(slide, {
    x: 0.92, y: 2.28, w: 3.83, h: 3.9,
    title: "首页 Home",
    body: "角色：动态 AI 工作台\n\n• Today-First 焦点卡\n• 多模态意图输入舱\n• 白盒化确认卡\n• 最近识别结果与继续动作\n\n首页解决的是“现在要处理什么”。",
    fill: COLORS.panelGold,
    accent: COLORS.primary,
    titleSize: 16,
    bodySize: 11,
  });
  addCard(slide, {
    x: 4.95, y: 2.28, w: 3.83, h: 3.9,
    title: "时间线 Timeline",
    body: "角色：秩序化资产沉淀区\n\n• 日 / 周 / 月聚合\n• 垂直时间轴列表\n• 提醒状态与导出\n• 日程详情与回看\n\n时间线解决的是“这些事如何被组织起来”。",
    fill: COLORS.panelBlue,
    accent: COLORS.skyDeep,
    titleSize: 16,
    bodySize: 11,
  });
  addCard(slide, {
    x: 8.98, y: 2.28, w: 3.42, h: 3.9,
    title: "我的 Profile",
    body: "角色：智能体控制中枢\n\n• 账号资料与偏好\n• 数字福祉与统计\n• 历史 / 账户 / 设置 / 更多功能\n• 风险开关与提醒策略\n\n这里解决的是“我如何掌控这个智能体”。",
    fill: COLORS.panel,
    accent: COLORS.green,
    titleSize: 16,
    bodySize: 10.9,
  });

  addFooter(slide, 10, 14);
}

function slide11() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "MILESTONES", "项目推进遵循“先打主链路，再补系统能力，再修关键问题”的节奏", "时间线上的每一次收口，都是为了让作品更接近真正可演示、可答辩、可交付的状态。");

  slide.addShape(pptx.ShapeType.line, {
    x: 1.1,
    y: 4.1,
    w: 10.9,
    h: 0,
    line: { color: COLORS.line, pt: 1.5 },
  });

  const nodes = [
    { x: 1.2, y: 4.0, date: "05.11", title: "API / UI 基线", body: "真实模型接入\n三页结构定型", up: true },
    { x: 3.1, y: 4.0, date: "05.12", title: "测试闭环", body: "自动化验证\n交互语义修正", up: false },
    { x: 5.0, y: 4.0, date: "05.29", title: "语音与交付", body: "构建、安装、APK 输出", up: true },
    { x: 6.9, y: 4.0, date: "06.01", title: "编译恢复", body: "修复编码问题\n恢复稳定构建", up: false },
    { x: 8.8, y: 4.0, date: "06.06", title: "识别兜底", body: "多事项切分\n提高通知解析覆盖", up: true },
    { x: 10.7, y: 4.0, date: "06.07", title: "产品收口", body: "提醒语义统一\n我的页二级结构补齐", up: false },
  ];
  nodes.forEach((n) => addTimelineNode(slide, n));

  addFooter(slide, 11, 14);
}

function slide12() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "ISSUES & FIXES", "近期修复重点已经从“能不能跑”转向“跑得是否可信、是否顺手”", "这部分最能体现项目从展示型原型往成熟型参赛作品靠近的速度。");

  addCard(slide, {
    x: 0.92, y: 2.34, w: 5.58, h: 3.78,
    title: "已经明确修掉或显著收口的问题",
    body: "• 分享文本和图片已真实跑通到 OCR / 模型 / 确认卡阶段\n• 多事项通知识别增加本地切分兜底，不再只拿到第一条\n• 提醒数统一按“待提醒事项数”统计，避免语义误导\n• 首页主按钮逻辑、重复登录、分享后不回首页等问题已收口\n• “我的页”从堆叠入口改为统计 / 账户 / 设置等二级结构",
    fill: COLORS.panelGreen,
    accent: COLORS.green,
    titleSize: 15,
    bodySize: 11.1,
  });
  addCard(slide, {
    x: 6.72, y: 2.34, w: 5.66, h: 3.78,
    title: "仍需继续打磨的边界",
    body: "• 语音输入全链路与实机表现仍需进一步验证\n• 地图联动的真实设备适配仍需持续观察\n• 图片低置信度分支与澄清体验还可继续优化\n• 导出 JPG / PNG 与更多边界场景还需要回归测试\n• 页面文案、轻量动效和性能表现仍可继续统一",
    fill: COLORS.panel,
    accent: COLORS.warning,
    titleSize: 15,
    bodySize: 11.1,
  });

  addFooter(slide, 12, 14);
}

function slide13() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "CURRENT STATUS", "当前版本已经具备可答辩、可演示、可继续扩展的完整闭环", "它已经不是“概念图 + 说明文档”，而是一个有真实模型、有真实系统能力、有真实风控的运行原型。");

  addCard(slide, {
    x: 0.92, y: 2.28, w: 6.0, h: 3.9,
    title: "当前已具备的核心能力",
    body: "√ 多入口导入：拍照 / 相册 / 分享 / 粘贴 / 语音\n√ vivo AI 接入：文本直连 LLM，图片走 OCR + LLM\n√ 结构化 JSON 输出与解释式确认卡\n√ 系统执行：日历、地图、提醒、TTS\n√ 时间线沉淀、本地持久化与偏好控制\n√ Profile 二级入口、统计面板、账号结构\n√ 构建、安装、模拟器验证与 APK 交付路径",
    fill: COLORS.panelGold,
    accent: COLORS.primary,
    titleSize: 15,
    bodySize: 11.2,
  });
  addCard(slide, {
    x: 7.16, y: 2.28, w: 5.22, h: 1.22,
    title: "环境与协作基线",
    body: "E 盘 Android Studio + 指定 JDK / SDK / AVD；进度说明与配置说明作为统一接手入口。",
    fill: COLORS.panelBlue,
    accent: COLORS.skyDeep,
    bodySize: 10.8,
  });
  addCard(slide, {
    x: 7.16, y: 3.74, w: 5.22, h: 1.22,
    title: "当前演示价值",
    body: "足以支撑“信息降噪 → 结构化理解 → 安全执行 → 时间线沉淀”的完整答辩叙事。",
    fill: COLORS.panelGreen,
    accent: COLORS.green,
    bodySize: 10.8,
  });
  addCard(slide, {
    x: 7.16, y: 5.2, w: 5.22, h: 0.98,
    title: "一句话结论",
    body: "《织时》已经具备成熟参赛作品的产品边界和工程可信度。",
    fill: COLORS.panel,
    accent: COLORS.primaryDeep,
    bodySize: 10.8,
  });

  addFooter(slide, 13, 14);
}

function slide14() {
  const slide = pptx.addSlide();
  addAmbient(slide);
  addHeader(slide, "NEXT", "下一阶段已经很清晰：围绕实机体验、语音链路与性能继续收口", "这页保留为后续展示与答辩过渡页，你也可以在这里补充演示视频、二维码或团队信息。");

  addCard(slide, {
    x: 0.94, y: 2.35, w: 3.74, h: 2.2,
    title: "P0 真实闭环",
    body: "继续把语音、拍照、导航和提醒在真实设备上的闭环验证做扎实，确保演示时不掉链子。",
    fill: COLORS.panelGold,
    accent: COLORS.primary,
    titleSize: 15,
    bodySize: 11.2,
  });
  addCard(slide, {
    x: 4.86, y: 2.35, w: 3.74, h: 2.2,
    title: "P1 体验收口",
    body: "继续优化低置信度澄清、页面文案一致性、交互反馈和各页流畅度，减少答辩时的感知阻力。",
    fill: COLORS.panelBlue,
    accent: COLORS.skyDeep,
    titleSize: 15,
    bodySize: 11.2,
  });
  addCard(slide, {
    x: 8.78, y: 2.35, w: 3.62, h: 2.2,
    title: "P2 交付表达",
    body: "结合实机演示视频、答辩口播和阶段汇报材料，把产品逻辑、设计语言和工程可信度讲得更完整。",
    fill: COLORS.panelGreen,
    accent: COLORS.green,
    titleSize: 15,
    bodySize: 11.2,
  });

  slide.addShape(pptx.ShapeType.roundRect, {
    x: 0.96,
    y: 5.02,
    w: 4.9,
    h: 1.08,
    rectRadius: 0.14,
    line: { color: COLORS.primary, pt: 1.2, dash: "dash" },
    fill: { color: COLORS.panel, transparency: 10 },
  });
  slide.addText("演示视频 / 二维码占位\n后续可直接替换为录屏、实机视频或展示链接", {
    x: 1.16,
    y: 5.29,
    w: 4.45,
    h: 0.5,
    fontFace: FONT_BODY,
    fontSize: 12.2,
    color: COLORS.body,
    align: "center",
    valign: "mid",
    margin: 0,
  });
  slide.addText("团队：________________", {
    x: 7.9,
    y: 6.36,
    w: 2.9,
    h: 0.2,
    fontFace: FONT_BODY,
    fontSize: 11.2,
    color: COLORS.muted,
    margin: 0,
  });
  slide.addText("结论：我们已经把《织时》从“想法”推进到了“可被验证的产品形态”。", {
    x: 6.42,
    y: 5.18,
    w: 5.8,
    h: 0.56,
    fontFace: FONT_TITLE,
    fontSize: 18.5,
    bold: true,
    color: COLORS.ink,
    margin: 0,
  });
  slide.addText("后续只需要继续围绕真实设备体验和边界稳定性打磨，就能让它更接近完整交付。", {
    x: 6.42,
    y: 5.82,
    w: 5.8,
    h: 0.34,
    fontFace: FONT_BODY,
    fontSize: 11.5,
    color: COLORS.body,
    margin: 0,
  });

  addFooter(slide, 14, 14, "资料依据：配置说明.md / 进度说明.md / 作品描述.md / README.md / demo_script.md");
}

async function build() {
  slide01();
  slide02();
  slide03();
  slide04();
  slide05();
  slide06();
  slide07();
  slide08();
  slide09();
  slide10();
  slide11();
  slide12();
  slide13();
  slide14();
  await pptx.writeFile({ fileName: OUT_FILE });
  console.log(`PPTX written to: ${OUT_FILE}`);
}

build().catch((error) => {
  console.error(error);
  process.exit(1);
});
