package com.phucta.classroom.widget

import android.content.Context
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.phucta.classroom.data.local.ClassroomDatabase
import com.phucta.classroom.data.local.MockDataProvider
import com.phucta.classroom.data.local.TokenStorage
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import com.phucta.classroom.ui.MainActivity
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.theme.ChunkyColor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ClassroomGlanceWidget : GlanceAppWidget() {

    companion object {
        private val SMALL_SIZE = DpSize(120.dp, 100.dp)
        private val MEDIUM_SIZE = DpSize(260.dp, 100.dp)
        private val LARGE_SIZE = DpSize(260.dp, 200.dp)
    }

    override val sizeMode: SizeMode = SizeMode.Responsive(
        setOf(SMALL_SIZE, MEDIUM_SIZE, LARGE_SIZE)
    )

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val (isAuthenticated, tomorrowItems) = withContext(Dispatchers.IO) {
            val tokenStorage = TokenStorage(context)
            val database = ClassroomDatabase.getInstance(context)

            val authed = tokenStorage.hasValidTokens()
            val courses = if (authed) {
                database.courseDao().getAllCourses()
                    .map { it.toDomain() }
                    .filter { !MockDataProvider.isMockCourse(it.id) }
            } else {
                emptyList()
            }
            val allCoursework = if (authed) {
                database.courseworkDao().getAllCoursework()
                    .map { it.toDomain() }
                    .filter { !MockDataProvider.isMockCourseworkId(it.id) }
            } else {
                emptyList()
            }

            val items = if (authed) {
                BaoBaiBucketingUtils.getTomorrowCoursework(allCoursework, courses)
            } else {
                emptyList()
            }
            Pair(authed, items)
        }

        provideContent {
            GlanceTheme {
                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .cornerRadius(16.dp)
                        .background(ChunkyColor.SkyBottom)
                        .clickable(actionStartActivity(android.content.Intent(context, MainActivity::class.java)))
                        .padding(10.dp)
                ) {
                    if (!isAuthenticated) {
                        UnauthenticatedWidgetView()
                    } else {
                        MediumChunkyWidgetContent(tomorrowItems)
                    }
                }
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun UnauthenticatedWidgetView() {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Báo bài Ngày mai",
                style = TextStyle(
                    color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
            )
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = "Vui lòng mở ứng dụng để đăng nhập Google.",
                style = TextStyle(
                    color = ColorProvider(androidx.compose.ui.graphics.Color.White.copy(alpha = 0.85f)),
                    fontSize = 11.sp
                )
            )
        }
    }

    @androidx.compose.runtime.Composable
    private fun MediumChunkyWidgetContent(items: List<Coursework>) {
        val incomplete = items.filter { !it.isCompleted }
        val displayItems = incomplete.take(3)
        val isAllDone = items.isEmpty() || incomplete.isEmpty()

        val headerTitle = when {
            isAllDone -> "✦ RẢNH RỒI"
            incomplete.any { it.isDueTomorrow } -> "NGÀY MAI"
            incomplete.all { it.isOverdue } -> "QUÁ HẠN"
            incomplete.all { it.isDueToday } -> "HÔM NAY"
            else -> "SẮP TỚI"
        }

        val subTitle = when {
            isAllDone -> "Tất cả bài tập\nđã xong!"
            else -> "Còn ${incomplete.size}\nbài cần nộp"
        }

        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left Column: Mascot status
            Column(
                modifier = GlanceModifier.width(90.dp).padding(end = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = headerTitle,
                    style = TextStyle(
                        color = ColorProvider(ChunkyColor.ButterYellow),
                        fontWeight = FontWeight.Bold,
                        fontSize = 11.sp
                    )
                )
                Spacer(modifier = GlanceModifier.height(4.dp))
                Text(
                    text = subTitle,
                    style = TextStyle(
                        color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                        fontWeight = FontWeight.Medium,
                        fontSize = 11.5.sp
                    )
                )
            }

            // Right Column: Task Cards
            Column(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxSize()
                    .cornerRadius(12.dp)
                    .background(ChunkyColor.SurfaceWhite)
                    .padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (displayItems.isEmpty()) {
                    Text(
                        text = if (items.isNotEmpty()) "Tất cả bài tập đã xong xuôi ✦" else "Không có bài tập nào cho ngày mai ✦",
                        style = TextStyle(
                            color = ColorProvider(ChunkyColor.TextMuted),
                            fontWeight = FontWeight.Medium,
                            fontSize = 11.5.sp
                        )
                    )
                } else {
                    displayItems.forEachIndexed { index, item ->
                        WidgetTaskRow(item)
                        if (index < displayItems.size - 1) {
                            Spacer(modifier = GlanceModifier.height(4.dp))
                        }
                    }
                }
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun WidgetTaskRow(item: Coursework) {
        val theme = SubjectArtHelper.theme(item.courseName, item.title)

        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Subject code
            Box(
                modifier = GlanceModifier
                    .cornerRadius(3.dp)
                    .background(theme.color)
                    .padding(horizontal = 4.dp, vertical = 1.dp)
            ) {
                Text(
                    text = theme.badgeCode,
                    style = TextStyle(
                        color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                        fontWeight = FontWeight.Bold,
                        fontSize = 8.sp
                    )
                )
            }

            Spacer(modifier = GlanceModifier.width(6.dp))

            // Title
            Text(
                text = item.title,
                maxLines = 1,
                modifier = GlanceModifier.defaultWeight(),
                style = TextStyle(
                    color = ColorProvider(ChunkyColor.TextPrimary),
                    fontWeight = FontWeight.Medium,
                    fontSize = 10.5.sp
                )
            )

            Spacer(modifier = GlanceModifier.width(4.dp))

            // Time
            Text(
                text = item.timeOnlyString,
                style = TextStyle(
                    color = ColorProvider(ChunkyColor.TextMuted),
                    fontWeight = FontWeight.Medium,
                    fontSize = 9.sp
                )
            )
        }
    }
}
