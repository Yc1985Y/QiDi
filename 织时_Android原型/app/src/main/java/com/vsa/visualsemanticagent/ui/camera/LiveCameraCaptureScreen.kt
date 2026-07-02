package com.vsa.visualsemanticagent.ui.camera

import androidx.camera.core.CameraSelector
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Cameraswitch
import androidx.compose.material.icons.rounded.FlashOff
import androidx.compose.material.icons.rounded.FlashOn
import androidx.compose.material.icons.rounded.Photo
import androidx.compose.material.icons.rounded.PhotoCamera
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.vsa.visualsemanticagent.camera.CameraManager
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppShapes
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import com.vsa.visualsemanticagent.ui.common.WeavingGlassCard
import com.vsa.visualsemanticagent.ui.common.rememberWeavingInteractionSource
import com.vsa.visualsemanticagent.ui.common.weavingClickable
import com.vsa.visualsemanticagent.ui.common.weavingPressFeedback

@Composable
fun LiveCameraCaptureScreen(
    modifier: Modifier = Modifier,
    isCapturing: Boolean,
    statusText: String,
    onBack: () -> Unit,
    onCapture: () -> Unit,
    onPickImage: () -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val lensFacingState = remember { mutableIntStateOf(CameraSelector.LENS_FACING_BACK) }
    val torchEnabledState = remember { mutableStateOf(false) }
    val cameraAvailableState = remember { mutableStateOf(true) }
    val previewViewState = remember { mutableStateOf<PreviewView?>(null) }
    val lensFacing = lensFacingState.intValue
    val torchEnabled = torchEnabledState.value
    val cameraAvailable = cameraAvailableState.value
    val previewView = previewViewState.value

    fun bindCurrentPreview() {
        val view = previewView ?: return
        CameraManager.bindCamera(
            context = context,
            lifecycleOwner = lifecycleOwner,
            previewView = view,
            lensFacing = lensFacing,
            enableTorch = torchEnabled
        ) { available ->
            cameraAvailableState.value = available
        }
    }

    LaunchedEffect(previewView, lensFacing, torchEnabled) {
        bindCurrentPreview()
    }

    DisposableEffect(Unit) {
        onDispose { CameraManager.unbindPreview(previewView) }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        AndroidView(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black),
            factory = { ctx ->
                PreviewView(ctx).apply {
                    scaleType = PreviewView.ScaleType.FILL_CENTER
                    implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                    previewViewState.value = this
                }
            },
            update = { view ->
                if (previewView !== view) previewViewState.value = view
            }
        )

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Color.Black.copy(alpha = 0.38f),
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.52f)
                        )
                    )
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = AppSpacing.lg, vertical = AppSpacing.xl),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            CameraTopBar(
                torchEnabled = torchEnabled,
                onBack = onBack,
                onToggleTorch = {
                    torchEnabledState.value = !torchEnabled
                    CameraManager.setTorch(torchEnabledState.value)
                },
                onSwitchCamera = {
                    torchEnabledState.value = false
                    lensFacingState.intValue = if (lensFacing == CameraSelector.LENS_FACING_BACK) {
                        CameraSelector.LENS_FACING_FRONT
                    } else {
                        CameraSelector.LENS_FACING_BACK
                    }
                }
            )

            CameraGuideOverlay(cameraAvailable = cameraAvailable)

            CameraBottomBar(
                isCapturing = isCapturing,
                statusText = statusText,
                onCapture = onCapture,
                onPickImage = onPickImage
            )
        }
    }
}

@Composable
private fun CameraTopBar(
    torchEnabled: Boolean,
    onBack: () -> Unit,
    onToggleTorch: () -> Unit,
    onSwitchCamera: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        GlassIconButton(Icons.Rounded.ArrowBack, "返回", onBack)
        Row(horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
            GlassIconButton(
                imageVector = if (torchEnabled) Icons.Rounded.FlashOn else Icons.Rounded.FlashOff,
                contentDescription = "闪光灯",
                onClick = onToggleTorch
            )
            GlassIconButton(Icons.Rounded.Cameraswitch, "切换摄像头", onSwitchCamera)
        }
    }
}

@Composable
private fun CameraGuideOverlay(cameraAvailable: Boolean) {
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = Alignment.Center
    ) {
        WeavingGlassCard(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = AppSpacing.md),
            containerColor = Color.White.copy(alpha = 0.18f)
        ) {
            Text(
                text = if (cameraAvailable) "把海报、课表或群通知放进取景框" else "当前设备暂时没有可用摄像头",
                style = AppTypography.BodyMedium,
                color = Color.White,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = if (cameraAvailable) {
                    "确认画面清晰后点击下方快门，织时会截取这一帧进行解析。"
                } else {
                    "可以返回首页改用相册、分享或粘贴文本。"
                },
                style = AppTypography.LabelSmall,
                color = Color.White.copy(alpha = 0.78f)
            )
        }
    }
}

@Composable
private fun CameraBottomBar(
    isCapturing: Boolean,
    statusText: String,
    onCapture: () -> Unit,
    onPickImage: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Bottom
    ) {
        CameraSideAction(
            icon = Icons.Rounded.Photo,
            label = "相册",
            enabled = !isCapturing,
            onClick = onPickImage
        )

        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = if (isCapturing) "正在截取当前画面…" else statusText.ifBlank { "实时取景已就绪" },
                style = AppTypography.LabelMedium,
                color = Color.White.copy(alpha = 0.86f)
            )
            Spacer(modifier = Modifier.height(AppSpacing.md))
            val interactionSource = rememberWeavingInteractionSource()
            Box(
                modifier = Modifier
                    .size(86.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.42f))
                    .weavingPressFeedback(interactionSource)
                    .weavingClickable(
                        interactionSource,
                        enabled = !isCapturing,
                        indication = null,
                        onClick = onCapture
                    ),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(66.dp)
                        .clip(CircleShape)
                        .background(AppColors.Primary),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Rounded.PhotoCamera,
                        contentDescription = "拍照",
                        tint = Color.White,
                        modifier = Modifier.size(30.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.size(64.dp))
    }
}

@Composable
private fun CameraSideAction(
    icon: ImageVector,
    label: String,
    enabled: Boolean,
    onClick: () -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier
            .clip(RoundedCornerShape(AppShapes.Large))
            .background(Color.White.copy(alpha = 0.16f))
            .weavingPressFeedback(interactionSource)
            .weavingClickable(
                interactionSource,
                enabled = enabled,
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 14.dp, vertical = 12.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = Color.White,
            modifier = Modifier.size(22.dp)
        )
        Text(
            text = label,
            style = AppTypography.LabelSmall,
            color = Color.White
        )
    }
}

@Composable
private fun GlassIconButton(
    imageVector: ImageVector,
    contentDescription: String,
    onClick: () -> Unit
) {
    IconButton(
        onClick = onClick,
        modifier = Modifier
            .size(48.dp)
            .clip(RoundedCornerShape(AppShapes.Full))
            .background(Color.White.copy(alpha = 0.24f))
    ) {
        Icon(
            imageVector = imageVector,
            contentDescription = contentDescription,
            tint = Color.White
        )
    }
}
