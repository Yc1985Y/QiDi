package com.vsa.visualsemanticagent.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Badge
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vsa.visualsemanticagent.ui.common.InteractiveFluorescentDustField

private val LoginPrimary = Color(0xFFF0C24A)
private val LoginOnBackground = Color(0xFF4A3810)
private val LoginMuted = Color(0xFF8B7337)
private val LoginOutline = Color(0xFFEEDDA1)
private val LoginCard = Color(0xFFFFFDF8)
private val LoginGlowTop = Color(0xFFFFE8A6)
private val LoginGlowBottom = Color(0xFFFFD98A)
private val LoginError = Color(0xFFB3261E)

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun LoginScreen(
    isSubmitting: Boolean,
    message: String,
    onLogin: (account: String, password: String) -> Unit,
    onRegister: (account: String, password: String, nickname: String) -> Unit
) {
    val isRegisterModeState = remember { mutableStateOf(false) }
    val accountState = remember { mutableStateOf("") }
    val passwordState = remember { mutableStateOf("") }
    val nicknameState = remember { mutableStateOf("") }
    val isRegisterMode = isRegisterModeState.value
    val account = accountState.value
    val password = passwordState.value
    val nickname = nicknameState.value

    fun submit() {
        if (isSubmitting) return
        if (account.isBlank() || password.isBlank()) return
        if (isRegisterMode) {
            onRegister(account, password, nickname)
        } else {
            onLogin(account, password)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .semantics { testTagsAsResourceId = true }
            .testTag("login-root")
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFFFFFBEF),
                        Color(0xFFFFFCF8),
                        Color(0xFFFFF2CC)
                    )
                )
            )
    ) {
        LoginGlowLayers()
        InteractiveFluorescentDustField(
            touchTargetSize = 36.dp,
            palette = listOf(
                LoginPrimary,
                LoginGlowTop,
                LoginGlowBottom,
                Color.White
            )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            LoginBrandHeader()

            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(28.dp),
                color = LoginCard,
                tonalElevation = 0.dp,
                shadowElevation = 4.dp
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    LoginModeHeader(
                        isRegisterMode = isRegisterMode,
                        onToggleMode = {
                            isRegisterModeState.value = !isRegisterMode
                        }
                    )

                    if (isRegisterMode) {
                        LoginTextField(
                            value = nickname,
                            onValueChange = { nicknameState.value = it },
                            label = "昵称",
                            icon = Icons.Rounded.Badge,
                            imeAction = ImeAction.Next,
                            fieldTag = "login-nickname"
                        )
                    }

                    LoginTextField(
                        value = account,
                        onValueChange = { accountState.value = it },
                        label = "学号或邮箱",
                        icon = Icons.Rounded.Person,
                        keyboardType = KeyboardType.Email,
                        imeAction = ImeAction.Next,
                        fieldTag = "login-account"
                    )

                    LoginTextField(
                        value = password,
                        onValueChange = { passwordState.value = it },
                        label = "密码",
                        icon = Icons.Rounded.Lock,
                        keyboardType = KeyboardType.Password,
                        imeAction = ImeAction.Done,
                        isPassword = true,
                        fieldTag = "login-password",
                        onDone = ::submit
                    )

                    if (message.isNotBlank()) {
                        Text(
                            text = message,
                            color = if (
                                message.contains("成功") ||
                                message.contains("欢迎") ||
                                message.contains("退出")
                            ) {
                                LoginMuted
                            } else {
                                LoginError
                            },
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }

                    Button(
                        onClick = { submit() },
                        enabled = !isSubmitting,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(54.dp)
                            .testTag("login-submit"),
                        shape = RoundedCornerShape(999.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = LoginPrimary,
                            contentColor = Color.White,
                            disabledContainerColor = LoginPrimary.copy(alpha = 0.55f),
                            disabledContentColor = Color.White.copy(alpha = 0.85f)
                        )
                    ) {
                        Text(
                            text = when {
                                isSubmitting -> "正在校验账号"
                                isRegisterMode -> "注册并进入织时"
                                else -> "进入织时"
                            },
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun LoginGlowLayers() {
    Box(
        modifier = Modifier
            .padding(start = 8.dp, top = 32.dp)
            .fillMaxWidth(0.72f)
            .height(260.dp)
            .background(
                brush = Brush.radialGradient(
                    colors = listOf(LoginGlowTop.copy(alpha = 0.55f), Color.Transparent)
                ),
                shape = CircleShape
            )
    )
    Box(
        modifier = Modifier
            .fillMaxSize(),
        contentAlignment = Alignment.BottomEnd
    ) {
        Box(
            modifier = Modifier
                .padding(end = 12.dp, bottom = 120.dp)
                .fillMaxWidth(0.62f)
                .height(220.dp)
                .background(
                    brush = Brush.radialGradient(
                        colors = listOf(LoginGlowBottom.copy(alpha = 0.45f), Color.Transparent)
                    ),
                    shape = CircleShape
                )
        )
    }
}

@Composable
private fun LoginBrandHeader() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.padding(bottom = 36.dp)
    ) {
        Surface(
            modifier = Modifier.height(72.dp),
            shape = RoundedCornerShape(24.dp),
            color = LoginPrimary
        ) {
            Box(
                modifier = Modifier.padding(horizontal = 28.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "织时",
                    color = Color.White,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.ExtraBold
                )
            }
        }
        Text(
            text = "织时",
            color = LoginOnBackground,
            fontSize = 34.sp,
            fontWeight = FontWeight.ExtraBold
        )
        Text(
            text = "将校园信息碎片整理成清晰时间线",
            color = LoginMuted,
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun LoginModeHeader(
    isRegisterMode: Boolean,
    onToggleMode: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = if (isRegisterMode) "创建账号" else "欢迎回来",
                color = LoginOnBackground,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = if (isRegisterMode) "本地账号会保存在当前设备中" else "使用本地账号进入个人时间线",
                color = LoginMuted,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }
        Text(
            text = if (isRegisterMode) "去登录" else "去注册",
            color = LoginPrimary,
            fontSize = 13.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier
                .testTag("login-toggle-mode")
                .clickable { onToggleMode() }
        )
    }
}

@Composable
private fun LoginTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    keyboardType: KeyboardType = KeyboardType.Text,
    imeAction: ImeAction,
    isPassword: Boolean = false,
    fieldTag: String,
    onDone: (() -> Unit)? = null
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = Modifier
            .fillMaxWidth()
            .testTag(fieldTag),
        label = { Text(label) },
        leadingIcon = {
            Icon(icon, contentDescription = null, tint = LoginPrimary)
        },
        visualTransformation = if (isPassword) PasswordVisualTransformation() else VisualTransformation.None,
        keyboardOptions = KeyboardOptions(
            keyboardType = keyboardType,
            imeAction = imeAction
        ),
        keyboardActions = if (onDone != null) {
            KeyboardActions(onDone = { onDone() })
        } else {
            KeyboardActions.Default
        },
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = LoginPrimary,
            unfocusedBorderColor = LoginOutline,
            focusedLabelColor = LoginPrimary,
            unfocusedLabelColor = LoginMuted,
            cursorColor = LoginPrimary,
            focusedContainerColor = Color.White,
            unfocusedContainerColor = Color.White
        ),
        shape = RoundedCornerShape(18.dp),
        singleLine = true
    )
}
