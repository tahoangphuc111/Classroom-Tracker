package com.phucta.classroom.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.phucta.classroom.ui.theme.ChunkyColor

import androidx.compose.foundation.layout.imePadding

@Composable
fun SettingsDialog(
    isAuthenticated: Boolean,
    userEmail: String?,
    userName: String?,
    isSyncing: Boolean,
    initialClientId: String? = null,
    initialClientSecret: String? = null,
    onDismiss: () -> Unit,
    onSignIn: () -> Unit,
    onSignOut: () -> Unit,
    onSyncNow: () -> Unit,
    onSaveCustomCredentials: (String?, String?) -> Unit
) {
    var customClientId by remember(initialClientId) { mutableStateOf(initialClientId ?: "") }
    var customClientSecret by remember(initialClientSecret) { mutableStateOf(initialClientSecret ?: "") }
    var showLogoutConfirmation by remember { mutableStateOf(false) }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            usePlatformDefaultWidth = false
        )
    ) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = ChunkyColor.SurfaceWhite,
            modifier = Modifier
                .fillMaxWidth(0.92f)
                .padding(vertical = 24.dp)
                .imePadding()
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Cài đặt & Tài khoản",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = ChunkyColor.TextPrimary,
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close", tint = ChunkyColor.TextMuted)
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(ChunkyColor.WindowBackground)
                        .padding(14.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(CircleShape)
                                .background(ChunkyColor.SkyBottom.copy(alpha = 0.15f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.AccountCircle,
                                contentDescription = null,
                                tint = ChunkyColor.SkyBottom,
                                modifier = Modifier.size(28.dp)
                            )
                        }

                        Spacer(modifier = Modifier.width(12.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            if (isAuthenticated && !userEmail.isNullOrBlank()) {
                                Text(
                                    text = userName ?: "Google Classroom User",
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 14.sp,
                                    color = ChunkyColor.TextPrimary
                                )
                                Text(
                                    text = userEmail,
                                    fontSize = 12.sp,
                                    color = ChunkyColor.TextMuted
                                )
                            } else {
                                Text(
                                    text = "Chưa kết nối tài khoản",
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 14.sp,
                                    color = ChunkyColor.TextPrimary
                                )
                                Text(
                                    text = "Đang xem dữ liệu mẫu",
                                    fontSize = 12.sp,
                                    color = ChunkyColor.TextMuted
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                if (isAuthenticated) {
                    Row(modifier = Modifier.fillMaxWidth()) {
                        Button(
                            onClick = onSyncNow,
                            enabled = !isSyncing,
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(containerColor = ChunkyColor.SkyBottom),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            if (isSyncing) {
                                CircularProgressIndicator(
                                    color = Color.White,
                                    strokeWidth = 2.dp,
                                    modifier = Modifier.size(16.dp)
                                )
                            } else {
                                Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Đồng bộ ngay", fontWeight = FontWeight.SemiBold)
                            }
                        }

                        Spacer(modifier = Modifier.width(10.dp))

                        OutlinedButton(
                            onClick = { showLogoutConfirmation = true },
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Text("Đăng xuất", color = ChunkyColor.UrgentAccent)
                        }
                    }
                } else {
                    Button(
                        onClick = onSignIn,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = ChunkyColor.SkyBottom),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Text("Đăng nhập bằng Google", fontWeight = FontWeight.Bold)
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))
                HorizontalDivider(color = ChunkyColor.Hairline)
                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "CẤU HÌNH CLIENT ID RIÊNG (TÙY CHỌN)",
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.sp,
                    color = ChunkyColor.TextMuted,
                    letterSpacing = 0.5.sp
                )
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = customClientId,
                    onValueChange = { customClientId = it },
                    label = { Text("Google Client ID") },
                    placeholder = { Text("Để trống để dùng Client ID mặc định", fontSize = 12.sp) },
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = ChunkyColor.SkyBottom,
                        unfocusedBorderColor = ChunkyColor.CardBorder,
                        focusedLabelColor = ChunkyColor.SkyBottom
                    ),
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = customClientSecret,
                    onValueChange = { customClientSecret = it },
                    label = { Text("Client Secret") },
                    placeholder = { Text("Để trống nếu dùng mặc định", fontSize = 12.sp) },
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = ChunkyColor.SkyBottom,
                        unfocusedBorderColor = ChunkyColor.CardBorder,
                        focusedLabelColor = ChunkyColor.SkyBottom
                    ),
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(14.dp))

                Button(
                    onClick = {
                        onSaveCustomCredentials(
                            customClientId.ifBlank { null },
                            customClientSecret.ifBlank { null }
                        )
                        onDismiss()
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = ChunkyColor.SkyBottom
                    ),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Text("Lưu cấu hình", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                }

                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Classroom Tracker v1.0.0 • Native Android",
                    fontSize = 11.sp,
                    color = ChunkyColor.TextTertiary,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
            }
        }
    }

    if (showLogoutConfirmation) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { showLogoutConfirmation = false },
            title = {
                Text(
                    text = "Đăng xuất tài khoản?",
                    fontWeight = FontWeight.Bold,
                    color = ChunkyColor.TextPrimary
                )
            },
            text = {
                Text(
                    text = "Toàn bộ dữ liệu bài tập đã lưu trên thiết bị sẽ được xoá. Bạn có thể đăng nhập lại bất kỳ lúc nào.",
                    color = ChunkyColor.TextMuted,
                    fontSize = 13.5.sp
                )
            },
            confirmButton = {
                androidx.compose.material3.TextButton(
                    onClick = {
                        showLogoutConfirmation = false
                        onSignOut()
                    }
                ) {
                    Text("Đăng xuất", color = ChunkyColor.UrgentAccent, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                androidx.compose.material3.TextButton(
                    onClick = { showLogoutConfirmation = false }
                ) {
                    Text("Huỷ", color = ChunkyColor.TextPrimary)
                }
            },
            containerColor = ChunkyColor.SurfaceWhite,
            shape = RoundedCornerShape(16.dp)
        )
    }
}
