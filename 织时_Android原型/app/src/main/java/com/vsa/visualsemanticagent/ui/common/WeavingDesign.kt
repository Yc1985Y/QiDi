package com.vsa.visualsemanticagent.ui.common

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Indication
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.sp
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppShapes
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import kotlinx.coroutines.launch

enum class WeavingInteractionStyle {
    CardLift,
    PrimaryPress,
    IconGlow,
    TimelineSlide
}

@Composable
fun rememberWeavingInteractionSource(): MutableInteractionSource = remember { MutableInteractionSource() }

@Composable
fun Modifier.weavingPressFeedback(
    interactionSource: MutableInteractionSource,
    style: WeavingInteractionStyle = WeavingInteractionStyle.CardLift
): Modifier {
    val pressed by interactionSource.collectIsPressedAsState()
    val targetScale = when (style) {
        WeavingInteractionStyle.PrimaryPress -> if (pressed) 0.965f else 1f
        WeavingInteractionStyle.IconGlow -> if (pressed) 0.92f else 1f
        WeavingInteractionStyle.TimelineSlide -> if (pressed) 0.985f else 1f
        WeavingInteractionStyle.CardLift -> if (pressed) 0.985f else 1f
    }
    val targetAlpha = when (style) {
        WeavingInteractionStyle.IconGlow -> if (pressed) 0.88f else 1f
        else -> 1f
    }
    val targetTranslation = when (style) {
        WeavingInteractionStyle.TimelineSlide -> if (pressed) 6f else 0f
        WeavingInteractionStyle.CardLift -> if (pressed) 2f else 0f
        else -> 0f
    }
    val scale by animateFloatAsState(
        targetValue = targetScale,
        animationSpec = spring(stiffness = 650f, dampingRatio = 0.82f),
        label = "weaving-scale"
    )
    val alpha by animateFloatAsState(
        targetValue = targetAlpha,
        animationSpec = tween(durationMillis = 120),
        label = "weaving-alpha"
    )
    val translationY by animateFloatAsState(
        targetValue = targetTranslation,
        animationSpec = spring(stiffness = 700f, dampingRatio = 0.9f),
        label = "weaving-translation"
    )
    return graphicsLayer {
        scaleX = scale
        scaleY = scale
        this.alpha = alpha
        this.translationY = translationY
    }
}

fun Modifier.weavingClickable(
    interactionSource: MutableInteractionSource,
    enabled: Boolean = true,
    indication: Indication? = null,
    onClick: () -> Unit
): Modifier = clickable(
    interactionSource = interactionSource,
    indication = indication,
    enabled = enabled,
    onClick = onClick
)

@Composable
fun WeavingBackground(
    modifier: Modifier = Modifier,
    interactiveStars: Boolean = false,
    showStarField: Boolean = false
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        AppColors.Background,
                        AppColors.SurfaceBright,
                        AppColors.Background
                    )
                )
            )
    ) {
        DiffuseGlow(
            modifier = Modifier
                .size(280.dp)
                .align(Alignment.TopStart),
            colors = listOf(AppColors.MintAccent.copy(alpha = 0.55f), Color.Transparent)
        )
        DiffuseGlow(
            modifier = Modifier
                .size(320.dp)
                .align(Alignment.TopEnd)
                .padding(top = 80.dp),
            colors = listOf(AppColors.GoldSoft.copy(alpha = 0.5f), Color.Transparent)
        )
        DiffuseGlow(
            modifier = Modifier
                .size(260.dp)
                .align(Alignment.BottomEnd),
            colors = listOf(AppColors.CoralSoft.copy(alpha = 0.45f), Color.Transparent)
        )
        if (showStarField || interactiveStars) {
            InteractiveFluorescentDustField(interactive = interactiveStars)
        }
    }
}

@Composable
private fun DiffuseGlow(
    modifier: Modifier,
    colors: List<Color>
) {
    Box(
        modifier = modifier
            .background(
                brush = Brush.radialGradient(colors),
                shape = CircleShape
            )
    )
}

@Composable
fun InteractiveFluorescentDustField(
    modifier: Modifier = Modifier,
    drawStars: Boolean = true,
    interactive: Boolean = true,
    touchTargetSize: Dp = 28.dp,
    palette: List<Color> = listOf(
        AppColors.PrimaryFixed,
        AppColors.GoldSoft,
        AppColors.MintAccent,
        AppColors.CoralSoft
    )
) {
    val stars = remember {
        listOf(
            // 北斗式星群：四颗斗身 + 三颗斗柄，边缘留白处更容易被用户轻触到。
            GlowStar(0.09f, 0.16f, 3, true),
            GlowStar(0.22f, 0.11f, 2, true),
            GlowStar(0.34f, 0.20f, 3, true),
            GlowStar(0.18f, 0.27f, 2, true),
            GlowStar(0.47f, 0.18f, 2, true),
            GlowStar(0.61f, 0.13f, 2, true),
            GlowStar(0.76f, 0.18f, 3, true),
            // 伴星只提供氛围，不参与连线。
            GlowStar(0.92f, 0.35f, 1, false),
            GlowStar(0.06f, 0.58f, 1, false),
            GlowStar(0.91f, 0.70f, 2, false),
            GlowStar(0.18f, 0.88f, 1, false),
            GlowStar(0.66f, 0.92f, 1, false)
        )
    }
    val scope = rememberCoroutineScope()
    val pulseProgress = remember { Animatable(1f) }
    val pulseStarState = remember { mutableStateOf<GlowStar?>(null) }
    val pulseColorState = remember { mutableStateOf(palette.firstOrNull() ?: AppColors.PrimaryFixed) }
    val pulseStar = pulseStarState.value
    val pulseColor = pulseColorState.value
    val safePalette = palette.ifEmpty { listOf(AppColors.PrimaryFixed) }

    BoxWithConstraints(modifier = modifier.fillMaxSize()) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            if (drawStars) {
                val constellationStars = stars.filter { it.inConstellation }
                constellationStars.zipWithNext().forEachIndexed { index, pair ->
                    val start = Offset(size.width * pair.first.x, size.height * pair.first.y)
                    val end = Offset(size.width * pair.second.x, size.height * pair.second.y)
                    val color = safePalette[(index + 1) % safePalette.size]
                    drawLine(
                        color = color.copy(alpha = 0.16f),
                        start = start,
                        end = end,
                        strokeWidth = 1.dp.toPx(),
                        cap = StrokeCap.Round
                    )
                }

                stars.forEachIndexed { index, star ->
                    val color = safePalette[index % safePalette.size]
                    val center = Offset(size.width * star.x, size.height * star.y)
                    val radius = star.size.dp.toPx()

                    drawCircle(
                        color = color.copy(alpha = 0.13f),
                        radius = radius * 4.2f,
                        center = center
                    )
                    drawCircle(
                        color = color.copy(alpha = 0.54f),
                        radius = radius,
                        center = center
                    )

                    if (star.size >= 3) {
                        drawLine(
                            color = color.copy(alpha = 0.22f),
                            start = Offset(center.x - radius * 3f, center.y),
                            end = Offset(center.x + radius * 3f, center.y),
                            strokeWidth = 0.8.dp.toPx()
                        )
                        drawLine(
                            color = color.copy(alpha = 0.18f),
                            start = Offset(center.x, center.y - radius * 3f),
                            end = Offset(center.x, center.y + radius * 3f),
                            strokeWidth = 0.8.dp.toPx()
                        )
                    }
                }
            }

            pulseStar?.let { star ->
                val progress = pulseProgress.value
                if (progress < 1f) {
                    val alpha = (1f - progress).coerceIn(0f, 1f)
                    val center = Offset(size.width * star.x, size.height * star.y)
                    drawCircle(
                        color = pulseColor.copy(alpha = 0.055f * alpha),
                        radius = 10.dp.toPx() + 42.dp.toPx() * progress,
                        center = center
                    )
                    drawCircle(
                        color = Color.White.copy(alpha = 0.18f * alpha),
                        radius = 2.dp.toPx() + 5.dp.toPx() * progress,
                        center = center
                    )
                    drawCircle(
                        color = pulseColor.copy(alpha = 0.18f * alpha),
                        radius = 6.dp.toPx() + 26.dp.toPx() * progress,
                        center = center
                    )
                }
            }
        }

        if (interactive) {
            stars.forEachIndexed { index, star ->
                Box(
                    modifier = Modifier
                        .offset(
                            x = maxWidth * star.x - touchTargetSize / 2,
                            y = maxHeight * star.y - touchTargetSize / 2
                        )
                        .size(touchTargetSize)
                        .clip(CircleShape)
                        .pointerInput(index, safePalette) {
                            detectTapGestures {
                                pulseStarState.value = star
                                pulseColorState.value = safePalette[index % safePalette.size]
                                scope.launch {
                                    pulseProgress.snapTo(0f)
                                    pulseProgress.animateTo(
                                        targetValue = 1f,
                                        animationSpec = tween(durationMillis = 620, easing = FastOutSlowInEasing)
                                    )
                                }
                            }
                        }
                )
            }
        }
    }
}

private data class GlowStar(
    val x: Float,
    val y: Float,
    val size: Int,
    val inConstellation: Boolean
)

@Composable
fun WeavingGlassCard(
    modifier: Modifier = Modifier,
    containerColor: Color = AppColors.GlassSurface,
    onClick: (() -> Unit)? = null,
    interactionStyle: WeavingInteractionStyle = WeavingInteractionStyle.CardLift,
    content: @Composable ColumnScope.() -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    Card(
        modifier = if (onClick != null) {
            modifier
                .weavingPressFeedback(interactionSource, interactionStyle)
                .weavingClickable(interactionSource) { onClick() }
        } else {
            modifier
        },
        shape = RoundedCornerShape(AppShapes.Large),
        colors = CardDefaults.cardColors(containerColor = containerColor),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = androidx.compose.foundation.BorderStroke(0.6.dp, AppColors.GlassBorder.copy(alpha = 0.68f))
    ) {
        Column(
            modifier = Modifier.padding(horizontal = AppSpacing.lg, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            content = content
        )
    }
}

@Composable
fun WeavingSectionTitle(
    title: String,
    subtitle: String? = null,
    action: String? = null,
    onActionClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Bottom
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = title,
                style = AppTypography.HeadlineLargeMobile,
                color = AppColors.Primary
            )
            if (!subtitle.isNullOrBlank()) {
                Text(
                    text = subtitle,
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant
                )
            }
        }
        if (!action.isNullOrBlank()) {
            Text(
                text = action,
                style = AppTypography.LabelMedium,
                color = AppColors.Primary,
                modifier = if (onActionClick != null) {
                    Modifier.clickable { onActionClick() }
                } else {
                    Modifier
                }
            )
        }
    }
}

@Composable
fun WeavingChip(
    text: String,
    icon: ImageVector? = null,
    background: Color = AppColors.SurfaceContainer,
    contentColor: Color = AppColors.Primary,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(AppShapes.Full))
            .background(background)
            .padding(horizontal = 12.dp, vertical = 7.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = contentColor,
                modifier = Modifier.size(14.dp)
            )
        }
        Text(
            text = text,
            style = AppTypography.LabelSmall,
            color = contentColor,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
fun WeavingPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true
) {
    val interactionSource = rememberWeavingInteractionSource()
    Button(
        onClick = onClick,
        modifier = modifier
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.PrimaryPress)
            .heightIn(min = 50.dp),
        interactionSource = interactionSource,
        enabled = enabled,
        shape = RoundedCornerShape(AppShapes.Full),
        colors = ButtonDefaults.buttonColors(
            containerColor = AppColors.Primary,
            contentColor = AppColors.OnPrimary,
            disabledContainerColor = AppColors.Primary.copy(alpha = 0.45f),
            disabledContentColor = AppColors.OnPrimary.copy(alpha = 0.75f)
        ),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 10.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(17.dp)
                )
            }
            Text(
                text = text,
                style = AppTypography.BodyLarge.copy(fontSize = 15.sp),
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun WeavingSecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val interactionSource = rememberWeavingInteractionSource()
    Button(
        onClick = onClick,
        modifier = modifier
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.PrimaryPress)
            .heightIn(min = 48.dp),
        interactionSource = interactionSource,
        shape = RoundedCornerShape(AppShapes.Full),
        colors = ButtonDefaults.buttonColors(
            containerColor = AppColors.SurfaceContainer,
            contentColor = AppColors.Primary
        ),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 10.dp)
    ) {
        Text(
            text = text,
            style = AppTypography.BodyLarge,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun WeavingIconBubble(
    icon: ImageVector,
    background: Color,
    tint: Color,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    val interactionSource = rememberWeavingInteractionSource()
    val bubbleModifier = modifier
        .size(44.dp)
        .clip(CircleShape)
        .background(background)
        .border(0.8.dp, Color.White.copy(alpha = 0.64f), CircleShape)
        .let { base ->
            if (onClick != null) {
                base
                    .weavingPressFeedback(interactionSource, WeavingInteractionStyle.IconGlow)
                    .weavingClickable(interactionSource) { onClick() }
            } else {
                base
            }
        }

    Box(
        modifier = bubbleModifier,
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier.matchParentSize(),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = tint,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
fun WeavingInitialAvatar(
    text: String,
    modifier: Modifier = Modifier,
    background: Color = AppColors.CoralSoft,
    tint: Color = AppColors.Primary,
    onClick: (() -> Unit)? = null
) {
    val initial = text.trim().take(1).ifBlank { "织" }
    val interactionSource = rememberWeavingInteractionSource()
    val avatarModifier = modifier
        .size(48.dp)
        .clip(CircleShape)
        .background(background)
        .border(0.8.dp, Color.White.copy(alpha = 0.64f), CircleShape)
        .let { base ->
            if (onClick != null) {
                base
                    .weavingPressFeedback(interactionSource, WeavingInteractionStyle.IconGlow)
                    .weavingClickable(interactionSource) { onClick() }
            } else {
                base
            }
        }

    Box(
        modifier = avatarModifier,
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = initial,
            style = AppTypography.HeadlineMedium,
            color = tint,
            fontWeight = FontWeight.ExtraBold
        )
    }
}

@Composable
fun EmptyStateCard(
    title: String,
    summary: String,
    actionText: String? = null,
    onActionClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    WeavingGlassCard(
        modifier = modifier.fillMaxWidth(),
        containerColor = AppColors.SurfaceContainer
    ) {
        Text(
            text = title,
            style = AppTypography.HeadlineMedium,
            color = AppColors.Primary,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        Text(
            text = summary,
            style = AppTypography.BodyMedium,
            color = AppColors.OnSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        if (!actionText.isNullOrBlank() && onActionClick != null) {
            WeavingPrimaryButton(
                text = actionText,
                onClick = onActionClick,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
