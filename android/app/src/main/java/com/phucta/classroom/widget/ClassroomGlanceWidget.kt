package com.phucta.classroom.widget

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontFamily
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.phucta.classroom.R
import com.phucta.classroom.data.local.ClassroomDatabase
import com.phucta.classroom.data.local.MockDataProvider
import com.phucta.classroom.data.local.TokenStorage
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import com.phucta.classroom.ui.MainActivity
import com.phucta.classroom.ui.components.DueDateBadgeColors
import com.phucta.classroom.ui.components.DueDateBadgeDefaults
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.theme.ChunkyColor
import com.phucta.classroom.widget.ClassroomGlanceWidget.Companion.formatDeadlinePill
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private val WidgetRoundedFamily = FontFamily("sans-serif-rounded")

enum class WidgetSizeOverride {
    AUTO, SMALL, MEDIUM, LARGE
}

open class ClassroomGlanceWidget(private val sizeOverride: WidgetSizeOverride = WidgetSizeOverride.AUTO) : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val (isAuthenticated, courseworkList) = withContext(Dispatchers.IO) {
            try {
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
                    val recentThreshold = System.currentTimeMillis() - (48 * 3600 * 1000L)
                    database.courseworkDao().getWidgetCoursework(recentThreshold)
                        .map { it.toDomain() }
                        .filter { !MockDataProvider.isMockCourseworkId(it.id) }
                } else {
                    emptyList()
                }
                val personalNotes = if (authed) {
                    database.personalNoteDao().getAllNotes()
                        .map { it.toDomain() }
                        .filter { (it.courseId == null || !MockDataProvider.isMockCourse(it.courseId)) && (it.courseworkId == null || !MockDataProvider.isMockCourseworkId(it.courseworkId)) }
                } else {
                    emptyList()
                }

                val items = if (authed) {
                    BaoBaiBucketingUtils.getTomorrowCoursework(
                        items = allCoursework,
                        courses = courses,
                        includeCompleted = true,
                        personalNotes = personalNotes
                    )
                } else {
                    emptyList()
                }

                val activeCount = items.count { !it.isCompleted }
                val hasCompleted = items.any { it.isCompleted }
                val hasUrgent = items.any { it.isUrgent }
                listOf(56, 88, 96).forEach { sizeDp ->
                    val emotion = getCharacterEmotion(activeCount, hasCompleted, hasUrgent = hasUrgent, isSmall = sizeDp <= 56)
                    EmberWidgetBitmapHelper.getEmberBitmap(context, sizeDp, if (authed) emotion else EmberEmotion.NORMAL)
                }

                Pair(authed, items)
            } catch (e: Exception) {
                Pair(false, emptyList())
            }
        }

        provideContent {
            GlanceTheme {
                val currentSize = androidx.glance.LocalSize.current
                // A resized widget must fit the space supplied by its launcher.
                val isSmall = sizeOverride == WidgetSizeOverride.SMALL || currentSize.width < 250.dp
                val isLarge = !isSmall && currentSize.height >= 280.dp &&
                    sizeOverride != WidgetSizeOverride.MEDIUM

                val skyBg = when {
                    isSmall -> R.drawable.bg_widget_sky
                    isLarge -> R.drawable.bg_widget_sky_large
                    else -> R.drawable.bg_widget_sky_medium
                }

                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .cornerRadius(22.dp)
                        .background(ImageProvider(skyBg))
                        .clickable(actionStartActivity<MainActivity>())
                        .padding(if (isLarge) 16.dp else 12.dp)
                ) {
                    when {
                        !isAuthenticated -> {
                            UnauthenticatedWidgetView(
                                context = context,
                                isSmall = isSmall,
                                isLarge = isLarge
                            )
                        }
                        isSmall -> {
                            SmallWidgetContent(
                                context = context,
                                courseworkList = courseworkList
                            )
                        }
                        isLarge -> {
                            LargeWidgetContent(
                                context = context,
                                courseworkList = courseworkList
                            )
                        }
                        else -> {
                            MediumWidgetContent(
                                context = context,
                                courseworkList = courseworkList
                            )
                        }
                    }
                }
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun UnauthenticatedWidgetView(
        context: Context,
        isSmall: Boolean,
        isLarge: Boolean
    ) {
        when {
            isSmall -> {
                Column(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    if (androidx.glance.LocalSize.current.height >= 120.dp) {
                        val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 44, EmberEmotion.NORMAL)
                        Image(
                            provider = ImageProvider(emberBitmap),
                            contentDescription = "Ember mascot",
                            modifier = GlanceModifier.size(44.dp)
                        )
                        Spacer(modifier = GlanceModifier.height(6.dp))
                    }
                    Box(
                        modifier = GlanceModifier
                            .defaultWeight()
                            .fillMaxWidth()
                            .background(ImageProvider(R.drawable.bg_widget_card))
                            .padding(horizontal = 8.dp, vertical = 8.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = "Chưa đăng nhập",
                                maxLines = 1,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextPrimary),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    fontFamily = WidgetRoundedFamily
                                )
                            )
                            Spacer(modifier = GlanceModifier.height(3.dp))
                            Text(
                                text = "Chạm để mở",
                                maxLines = 1,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.ActionBlue),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp
                                )
                            )
                        }
                    }
                }
            }

            isLarge -> {
                Column(
                    modifier = GlanceModifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 92, EmberEmotion.NORMAL)
                    Image(
                        provider = ImageProvider(emberBitmap),
                        contentDescription = "Ember mascot",
                        modifier = GlanceModifier.size(92.dp)
                    )
                    Spacer(modifier = GlanceModifier.height(10.dp))
                    Text(
                        text = "Chưa đăng nhập",
                        style = TextStyle(
                            color = ColorProvider(Color.White),
                            fontWeight = FontWeight.Bold,
                            fontSize = 24.sp,
                            fontFamily = WidgetRoundedFamily
                        )
                    )
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    Text(
                        text = "Chạm để kết nối Classroom",
                        style = TextStyle(
                            color = ColorProvider(ChunkyColor.ButterYellow),
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.5.sp
                        )
                    )
                }
            }

            else -> {
                Row(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(
                        modifier = GlanceModifier.width(80.dp).fillMaxHeight(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 68, EmberEmotion.NORMAL)
                        Image(
                            provider = ImageProvider(emberBitmap),
                            contentDescription = "Ember mascot",
                            modifier = GlanceModifier.size(68.dp)
                        )
                    }

                    Spacer(modifier = GlanceModifier.width(8.dp))

                    Box(
                        modifier = GlanceModifier
                            .defaultWeight()
                            .fillMaxHeight()
                            .background(ImageProvider(R.drawable.bg_widget_card))
                            .padding(horizontal = 14.dp, vertical = 10.dp)
                    ) {
                        Column(
                            modifier = GlanceModifier.fillMaxSize(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_person),
                                contentDescription = "Sign in",
                                modifier = GlanceModifier.size(38.dp)
                            )
                            Spacer(modifier = GlanceModifier.height(6.dp))
                            Text(
                                text = "Chưa đăng nhập",
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextPrimary),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    fontFamily = WidgetRoundedFamily
                                )
                            )
                            Spacer(modifier = GlanceModifier.height(3.dp))
                            Text(
                                text = "Chạm để kết nối Classroom",
                                maxLines = 1,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextMuted),
                                    fontWeight = FontWeight.Medium,
                                    fontSize = 12.sp
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun SmallWidgetContent(
        context: Context,
        courseworkList: List<Coursework>
    ) {
        val currentSize = androidx.glance.LocalSize.current
        val compact = currentSize.height < 140.dp || currentSize.width < 140.dp
        val showHeader = currentSize.height >= 120.dp
        val activeItems = courseworkList.filter { !it.isCompleted }
        val displayItems = if (activeItems.isEmpty()) courseworkList else activeItems
        val sectionTitle = getSectionHeaderTitle(courseworkList)
        val compactHeader = getCompactHeaderTitle(sectionTitle)
        val emotion = getCharacterEmotion(activeItems.size, courseworkList.any { it.isCompleted }, hasUrgent = activeItems.any { it.isUrgent }, isSmall = true)

        Column(
            modifier = GlanceModifier.fillMaxSize()
        ) {
            if (showHeader) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 2.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        modifier = GlanceModifier.defaultWeight(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "${activeItems.size}",
                            style = TextStyle(
                                color = ColorProvider(Color.White),
                                fontWeight = FontWeight.Bold,
                                fontSize = 31.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                        Spacer(modifier = GlanceModifier.width(5.dp))

                        if (activeItems.isEmpty() && courseworkList.isNotEmpty()) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_seal_check),
                                contentDescription = "Completed",
                                modifier = GlanceModifier.size(22.dp)
                            )
                        } else {
                            Text(
                                text = compactHeader,
                                maxLines = 1,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.ButterYellow),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.sp,
                                    fontFamily = WidgetRoundedFamily
                                )
                            )
                        }
                    }

                    val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 44, emotion)
                    Image(
                        provider = ImageProvider(emberBitmap),
                        contentDescription = "Ember mascot",
                        modifier = GlanceModifier.size(44.dp)
                    )
                }

                Spacer(modifier = GlanceModifier.height(4.dp))
            }

            Box(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxWidth()
                    .background(ImageProvider(R.drawable.bg_widget_card))
                    .padding(horizontal = 8.dp, vertical = 6.dp)
            ) {
                if (displayItems.isEmpty()) {
                    Column(
                        modifier = GlanceModifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (!compact) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_sparkles),
                                contentDescription = "Done",
                                modifier = GlanceModifier.size(26.dp)
                            )
                            Spacer(modifier = GlanceModifier.height(4.dp))
                        }
                        Text(
                            text = "Hết bài rồi!",
                            maxLines = 1,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.TextPrimary),
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                    }
                } else if (displayItems.size == 1 || compact) {
                    val item = displayItems.first()
                    val theme = SubjectArtHelper.theme(item.courseName, item.title)

                    Column(
                        modifier = GlanceModifier.fillMaxSize(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (!compact) {
                            Row(
                                modifier = GlanceModifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = GlanceModifier
                                        .size(24.dp)
                                        .cornerRadius(8.dp)
                                        .background(theme.color.copy(alpha = 0.16f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Image(
                                        provider = ImageProvider(theme.iconRes),
                                        contentDescription = null,
                                        modifier = GlanceModifier.size(12.dp)
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(6.dp))
                                Text(
                                    text = item.courseName,
                                    maxLines = 1,
                                    modifier = GlanceModifier.defaultWeight(),
                                    style = TextStyle(
                                        color = ColorProvider(theme.textColor),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 11.sp
                                    )
                                )
                                Spacer(modifier = GlanceModifier.width(4.dp))
                                if (item.isCompleted) {
                                    Image(
                                        provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                        contentDescription = "Done",
                                        modifier = GlanceModifier.size(17.dp)
                                    )
                                } else {
                                    val labelText = formatDeadlinePill(item)
                                    val badgeColors = getWidgetBadgeColors(item)
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(6.dp)
                                            .background(badgeColors.background)
                                            .padding(horizontal = 7.dp, vertical = 3.dp)
                                    ) {
                                        Text(
                                            text = labelText,
                                            maxLines = 1,
                                            style = TextStyle(
                                                color = ColorProvider(badgeColors.text),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 11.sp
                                            )
                                        )
                                    }
                                }
                            }

                            Spacer(modifier = GlanceModifier.height(4.dp))
                        }

                        Text(
                            text = item.title.ifEmpty { item.courseName },
                            maxLines = 2,
                            style = TextStyle(
                                color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                        if (compact) {
                            Spacer(modifier = GlanceModifier.height(3.dp))
                            Text(
                                text = dueLabel(item),
                                maxLines = 1,
                                style = TextStyle(
                                    color = ColorProvider(getWidgetBadgeColors(item).text),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.sp
                                )
                            )
                        }
                    }
                } else {
                    val itemsToShow = displayItems.take(2)
                    Column(
                        modifier = GlanceModifier.fillMaxSize()
                    ) {
                        itemsToShow.forEachIndexed { index, item ->
                            val theme = SubjectArtHelper.theme(item.courseName, item.title)
                            Row(
                                modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = GlanceModifier
                                        .size(24.dp)
                                        .cornerRadius(8.dp)
                                        .background(theme.color.copy(alpha = 0.16f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Image(
                                        provider = ImageProvider(theme.iconRes),
                                        contentDescription = null,
                                        modifier = GlanceModifier.size(12.dp)
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(7.dp))
                                Text(
                                    text = item.title.ifEmpty { item.courseName },
                                    maxLines = 1,
                                    modifier = GlanceModifier.defaultWeight(),
                                    style = TextStyle(
                                        color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 13.sp,
                                        fontFamily = WidgetRoundedFamily
                                    )
                                )
                                Spacer(modifier = GlanceModifier.width(4.dp))
                                if (item.isCompleted) {
                                    Image(
                                        provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                        contentDescription = "Done",
                                        modifier = GlanceModifier.size(12.dp)
                                    )
                                } else {
                                    val badgeColors = getWidgetBadgeColors(item)
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(6.dp)
                                            .background(badgeColors.background)
                                            .padding(horizontal = 6.5.dp, vertical = 2.5.dp)
                                    ) {
                                        Text(
                                            text = formatDeadlinePill(item),
                                            maxLines = 1,
                                            style = TextStyle(
                                                color = ColorProvider(badgeColors.text),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 11.5.sp
                                            )
                                        )
                                    }
                                }
                            }
                            if (index < itemsToShow.size - 1) {
                                Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(ChunkyColor.Hairline)) {}
                            }
                        }
                    }
                }
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun MediumWidgetContent(
        context: Context,
        courseworkList: List<Coursework>
    ) {
        val compact = androidx.glance.LocalSize.current.height < 140.dp
        val mascotSize = if (compact) 40 else 68
        val activeItems = courseworkList.filter { !it.isCompleted }
        val completedItems = courseworkList.filter { it.isCompleted }
        val displayItems = if (activeItems.isEmpty()) courseworkList else (activeItems + completedItems)
        val sectionTitle = getSectionHeaderTitle(courseworkList)
        val compactHeader = getCompactHeaderTitle(sectionTitle)

        val emotion = getCharacterEmotion(activeItems.size, completedItems.isNotEmpty(), hasUrgent = activeItems.any { it.isUrgent }, isSmall = false)

        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = GlanceModifier.width(80.dp).fillMaxHeight(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "${activeItems.size}",
                        style = TextStyle(
                            color = ColorProvider(Color.White),
                            fontWeight = FontWeight.Bold,
                            fontSize = if (compact) 28.sp else 35.sp,
                            fontFamily = WidgetRoundedFamily
                        )
                    )
                    Spacer(modifier = GlanceModifier.width(5.dp))
                    if (activeItems.isEmpty() && courseworkList.isNotEmpty()) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_widget_seal_check),
                            contentDescription = "Done",
                            modifier = GlanceModifier.size(24.dp)
                        )
                    } else {
                        Text(
                            text = compactHeader,
                            maxLines = 1,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.ButterYellow),
                                fontWeight = FontWeight.Bold,
                                fontSize = 11.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                    }
                }

                Spacer(modifier = GlanceModifier.defaultWeight())

                val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, mascotSize, emotion)
                Image(
                    provider = ImageProvider(emberBitmap),
                    contentDescription = "Ember mascot",
                    modifier = GlanceModifier.size(mascotSize.dp)
                )
            }

            Spacer(modifier = GlanceModifier.width(6.dp))

            Box(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxHeight()
                    .background(ImageProvider(R.drawable.bg_widget_card))
                    .padding(horizontal = 10.dp, vertical = 8.dp)
            ) {
                if (displayItems.isEmpty()) {
                    Column(
                        modifier = GlanceModifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_widget_sparkles),
                            contentDescription = "Free day",
                            modifier = GlanceModifier.size(28.dp)
                        )
                        Spacer(modifier = GlanceModifier.height(6.dp))
                        val emptyTitle = if (sectionTitle == "HÔM NAY") "Hôm nay hết bài rồi!" else "Ngày mai không có bài!"
                        Text(
                            text = emptyTitle,
                            maxLines = 1,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.TextPrimary),
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(3.dp))
                        Text(
                            text = "Không còn bài tập cần nộp",
                            maxLines = 1,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.TextMuted),
                                fontWeight = FontWeight.Medium,
                                fontSize = 12.sp
                            )
                        )
                    }
                } else if (displayItems.size == 1) {
                    val item = displayItems.first()
                    val theme = SubjectArtHelper.theme(item.courseName, item.title)

                    Column(
                        modifier = GlanceModifier.fillMaxSize(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            modifier = GlanceModifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = GlanceModifier
                                    .size(28.dp)
                                    .cornerRadius(12.dp)
                                    .background(theme.color.copy(alpha = 0.16f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Image(
                                    provider = ImageProvider(theme.iconRes),
                                    contentDescription = null,
                                    modifier = GlanceModifier.size(16.dp)
                                )
                            }
                            Spacer(modifier = GlanceModifier.width(6.dp))
                            Text(
                                text = item.courseName,
                                maxLines = 1,
                                modifier = GlanceModifier.defaultWeight(),
                                style = TextStyle(
                                    color = ColorProvider(theme.textColor),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    fontFamily = WidgetRoundedFamily
                                )
                            )
                            Spacer(modifier = GlanceModifier.width(6.dp))
                            if (item.isCompleted) {
                                Box(
                                    modifier = GlanceModifier
                                        .cornerRadius(8.dp)
                                        .background(ChunkyColor.CompletedBadgeBackground)
                                        .padding(horizontal = 6.dp, vertical = 3.dp)
                                ) {
                                    Text(
                                        text = "Đã xong",
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(ChunkyColor.CompletedBadgeText),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 11.sp,
                                            fontFamily = WidgetRoundedFamily
                                        )
                                    )
                                }
                            } else {
                                val badgeColors = getWidgetBadgeColors(item)
                                Box(
                                    modifier = GlanceModifier
                                        .cornerRadius(8.dp)
                                        .background(badgeColors.background)
                                        .padding(horizontal = 6.dp, vertical = 3.dp)
                                ) {
                                    Text(
                                        text = formatDeadlinePill(item),
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(badgeColors.text),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 11.sp,
                                            fontFamily = WidgetRoundedFamily
                                        )
                                    )
                                }
                            }
                        }

                        Spacer(modifier = GlanceModifier.height(8.dp))

                        Text(
                            text = item.title.ifEmpty { item.courseName },
                            maxLines = if (compact) 1 else 2,
                            style = TextStyle(
                                color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                    }
                } else {
                    val itemsToShow = displayItems.take(if (compact) 2 else 3)
                    val isTwoItems = itemsToShow.size <= 2
                    val badgeSize = if (isTwoItems) 30 else 26
                    val iconSize = if (isTwoItems) 16 else 14
                    val titleFontSize = if (isTwoItems) 15.0 else 13.5
                    val subFontSize = if (isTwoItems) 12.0 else 11.0
                    val tagFontSize = if (isTwoItems) 11.0 else 10.5

                    Column(
                        modifier = GlanceModifier.fillMaxSize()
                    ) {
                        itemsToShow.forEachIndexed { index, item ->
                            val theme = SubjectArtHelper.theme(item.courseName, item.title)
                            Row(
                                modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = GlanceModifier
                                        .size(badgeSize.dp)
                                        .cornerRadius(if (isTwoItems) 10.dp else 8.dp)
                                        .background(theme.color.copy(alpha = 0.16f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Image(
                                        provider = ImageProvider(theme.iconRes),
                                        contentDescription = null,
                                        modifier = GlanceModifier.size(iconSize.dp)
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(6.dp))
                                Column(
                                    modifier = GlanceModifier.defaultWeight()
                                ) {
                                    Text(
                                        text = item.title.ifEmpty { item.courseName },
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = titleFontSize.sp,
                                            fontFamily = WidgetRoundedFamily
                                        )
                                    )
                                    Text(
                                        text = item.courseName,
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(ChunkyColor.TextMuted),
                                            fontWeight = FontWeight.Medium,
                                            fontSize = subFontSize.sp
                                        )
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(6.dp))
                                if (item.isCompleted) {
                                    Image(
                                        provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                        contentDescription = "Done",
                                        modifier = GlanceModifier.size(19.dp)
                                    )
                                } else {
                                    val timeText = formatDeadlinePill(item)
                                    val badgeColors = getWidgetBadgeColors(item)
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(7.dp)
                                            .background(badgeColors.background)
                                            .padding(horizontal = 8.5.dp, vertical = 3.5.dp)
                                    ) {
                                        Text(
                                            text = timeText,
                                            style = TextStyle(
                                                color = ColorProvider(badgeColors.text),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = tagFontSize.sp
                                            )
                                        )
                                    }
                                }
                            }
                            if (index < itemsToShow.size - 1) {
                                Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(ChunkyColor.Hairline)) {}
                            }
                        }
                    }
                }
            }
        }
    }

    @androidx.compose.runtime.Composable
    private fun LargeWidgetContent(
        context: Context,
        courseworkList: List<Coursework>
    ) {
        val activeItems = courseworkList.filter { !it.isCompleted }
        val completedItems = courseworkList.filter { it.isCompleted }
        val displayItems = if (activeItems.isEmpty()) courseworkList else (activeItems + completedItems)
        val sectionTitle = getSectionHeaderTitle(courseworkList)
        val sectionCapsule = getSectionCapsuleLabel(sectionTitle)

        val emotion = getCharacterEmotion(activeItems.size, completedItems.isNotEmpty(), hasUrgent = activeItems.any { it.isUrgent }, isSmall = false)

        Column(
            modifier = GlanceModifier.fillMaxSize()
        ) {
            // Header sitting on sky gradient
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(horizontal = 2.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 78, emotion)
                Image(
                    provider = ImageProvider(emberBitmap),
                    contentDescription = "Ember mascot",
                    modifier = GlanceModifier.size(78.dp)
                )

                Spacer(modifier = GlanceModifier.width(14.dp))

                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "${activeItems.size}",
                            style = TextStyle(
                                color = ColorProvider(Color.White),
                                fontWeight = FontWeight.Bold,
                                fontSize = 42.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                        Spacer(modifier = GlanceModifier.width(8.dp))
                        Text(
                            text = if (activeItems.isEmpty()) "HOÀN TẤT" else getCompactHeaderTitle(sectionTitle),
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.ButterYellow),
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                    }

                    Spacer(modifier = GlanceModifier.height(4.dp))

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = GlanceModifier
                                .cornerRadius(8.dp)
                                .background(Color.White.copy(alpha = 0.24f))
                                .padding(horizontal = 10.dp, vertical = 4.dp)
                        ) {
                            val summaryText = if (completedItems.isNotEmpty()) {
                                "$sectionCapsule • Đã xong ${completedItems.size}"
                            } else {
                                "$sectionCapsule: ${activeItems.size} bài"
                            }
                            Text(
                                text = summaryText,
                                style = TextStyle(
                                    color = ColorProvider(Color.White),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.5.sp
                                )
                            )
                        }
                    }
                }
            }

            Spacer(modifier = GlanceModifier.height(6.dp))

            // White Card Content
            Box(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxWidth()
                    .background(ImageProvider(R.drawable.bg_widget_card_large))
                    .padding(horizontal = 12.dp, vertical = 10.dp)
            ) {
                if (displayItems.isEmpty()) {
                    Column(
                        modifier = GlanceModifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_widget_sparkles),
                            contentDescription = "Great",
                            modifier = GlanceModifier.size(48.dp)
                        )
                        Spacer(modifier = GlanceModifier.height(8.dp))
                        val emptyTitle = if (sectionTitle == "HÔM NAY") "Hôm nay hết bài rồi!" else "Ngày mai không có bài!"
                        Text(
                            text = emptyTitle,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.TextPrimary),
                                fontWeight = FontWeight.Bold,
                                fontSize = 24.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = "Tất cả bài tập đều đã làm xong",
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.TextMuted),
                                fontWeight = FontWeight.Medium,
                                fontSize = 16.sp
                            )
                        )
                    }
                } else if (displayItems.size == 1) {
                    val item = displayItems.first()
                    val theme = SubjectArtHelper.theme(item.courseName, item.title)

                    Column(
                        modifier = GlanceModifier.fillMaxSize(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            modifier = GlanceModifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = GlanceModifier
                                    .size(38.dp)
                                    .cornerRadius(14.dp)
                                    .background(theme.color.copy(alpha = 0.16f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Image(
                                    provider = ImageProvider(theme.iconRes),
                                    contentDescription = null,
                                    modifier = GlanceModifier.size(20.dp)
                                )
                            }
                            Spacer(modifier = GlanceModifier.width(12.dp))
                            Text(
                                text = item.courseName,
                                maxLines = 1,
                                modifier = GlanceModifier.defaultWeight(),
                                style = TextStyle(
                                    color = ColorProvider(theme.textColor),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    fontFamily = WidgetRoundedFamily
                                )
                            )
                            Spacer(modifier = GlanceModifier.width(8.dp))
                            if (item.isCompleted) {
                                Box(
                                    modifier = GlanceModifier
                                        .cornerRadius(8.dp)
                                        .background(ChunkyColor.CompletedBadgeBackground)
                                        .padding(horizontal = 12.dp, vertical = 5.dp)
                                ) {
                                    Text(
                                        text = "Đã xong",
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(ChunkyColor.CompletedBadgeText),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 14.5.sp,
                                            fontFamily = WidgetRoundedFamily
                                        )
                                    )
                                }
                            } else {
                                val badgeColors = getWidgetBadgeColors(item)
                                Box(
                                    modifier = GlanceModifier
                                        .cornerRadius(8.dp)
                                        .background(badgeColors.background)
                                        .padding(horizontal = 12.dp, vertical = 5.dp)
                                ) {
                                    Text(
                                        text = formatDeadlinePill(item),
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(badgeColors.text),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 14.5.sp,
                                            fontFamily = WidgetRoundedFamily
                                        )
                                    )
                                }
                            }
                        }

                        Spacer(modifier = GlanceModifier.height(8.dp))

                        Text(
                            text = item.title.ifEmpty { item.courseName },
                            maxLines = 3,
                            style = TextStyle(
                                color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                fontWeight = FontWeight.Bold,
                                fontSize = 20.sp,
                                fontFamily = WidgetRoundedFamily
                            )
                        )
                    }
                } else {
                    val itemsToShow = displayItems.take(4)
                    val count = itemsToShow.size
                    val badgeSize = when (count) {
                        2 -> 38
                        3 -> 34
                        else -> 30
                    }
                    val iconSize = when (count) {
                        2 -> 20
                        3 -> 18
                        else -> 16
                    }
                    val titleFontSize = when (count) {
                        2 -> 18.0
                        3 -> 16.0
                        else -> 14.5
                    }
                    val subFontSize = when (count) {
                        2 -> 13.0
                        3 -> 12.0
                        else -> 11.0
                    }
                    val tagFontSize = when (count) {
                        2 -> 12.0
                        3 -> 11.5
                        else -> 11.0
                    }

                    Column(
                        modifier = GlanceModifier.fillMaxSize()
                    ) {
                        itemsToShow.forEachIndexed { index, item ->
                            val theme = SubjectArtHelper.theme(item.courseName, item.title)
                            Row(
                                modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = GlanceModifier
                                        .size(badgeSize.dp)
                                        .cornerRadius(if (count <= 3) 12.dp else 10.dp)
                                        .background(theme.color.copy(alpha = 0.16f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Image(
                                        provider = ImageProvider(theme.iconRes),
                                        contentDescription = null,
                                        modifier = GlanceModifier.size(iconSize.dp)
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(12.dp))
                                Column(modifier = GlanceModifier.defaultWeight()) {
                                    Text(
                                        text = item.title.ifEmpty { item.courseName },
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = titleFontSize.sp,
                                            fontFamily = WidgetRoundedFamily
                                        )
                                    )
                                    Text(
                                        text = item.courseName,
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(ChunkyColor.TextMuted),
                                            fontWeight = FontWeight.Medium,
                                            fontSize = subFontSize.sp
                                        )
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(8.dp))
                                if (item.isCompleted) {
                                    Image(
                                        provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                        contentDescription = "Done",
                                        modifier = GlanceModifier.size(22.dp)
                                    )
                                } else {
                                    val timeText = formatDeadlinePill(item)
                                    val badgeColors = getWidgetBadgeColors(item)
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(8.dp)
                                            .background(badgeColors.background)
                                            .padding(horizontal = 9.5.dp, vertical = 4.5.dp)
                                    ) {
                                        Text(
                                            text = timeText,
                                            style = TextStyle(
                                                color = ColorProvider(badgeColors.text),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = tagFontSize.sp
                                            )
                                        )
                                    }
                                }
                            }
                            if (index < itemsToShow.size - 1) {
                                Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(ChunkyColor.Hairline)) {}
                            }
                        }
                    }
                }
            }
        }
    }

    companion object {
        fun getWidgetBadgeColors(item: Coursework): DueDateBadgeColors {
            return DueDateBadgeDefaults.colors(
                isCompleted = item.isCompleted,
                isOverdue = item.isOverdue || item.isPast,
                isDueToday = item.isDueToday,
                isDueTomorrow = item.isDueTomorrow,
                isUrgent = item.isUrgent
            )
        }

        fun getCharacterEmotion(activeCount: Int, hasCompleted: Boolean, hasUrgent: Boolean = false, isSmall: Boolean = false): EmberEmotion {
            val stressedThreshold = if (isSmall) 3 else 4
            return when {
                activeCount == 0 -> if (hasCompleted) EmberEmotion.CELEBRATING else EmberEmotion.SLEEPING
                hasUrgent || activeCount >= stressedThreshold -> EmberEmotion.STRESSED
                else -> EmberEmotion.NORMAL
            }
        }

        fun getSectionHeaderTitle(items: List<Coursework>): String {
            val pending = items.filter { !it.isCompleted }
            val hasToday = pending.any { it.isDueToday }
            val hasTomorrow = pending.any { it.isDueTomorrow }
            val hasOverdue = pending.any { it.dueEpochMillis != null && it.dueEpochMillis < System.currentTimeMillis() }

            return when {
                hasToday && hasTomorrow -> "HÔM NAY & MAI"
                hasToday -> "HÔM NAY"
                hasTomorrow -> "NGÀY MAI"
                hasOverdue -> "QUÁ HẠN"
                pending.isNotEmpty() -> "SẮP TỚI"
                items.any { it.isDueToday } -> "HÔM NAY"
                items.any { it.isDueTomorrow } -> "NGÀY MAI"
                else -> "NGÀY MAI"
            }
        }

        fun getSectionCapsuleLabel(sectionTitle: String): String {
            return when (sectionTitle) {
                "HÔM NAY & MAI" -> "Hôm nay & mai"
                "HÔM NAY" -> "Hôm nay"
                "QUÁ HẠN" -> "Quá hạn"
                "SẮP TỚI" -> "Sắp tới"
                else -> "Ngày mai"
            }
        }

        fun getCompactHeaderTitle(sectionTitle: String): String {
            return when (sectionTitle) {
                "HÔM NAY & MAI" -> "CẦN NỘP"
                "HÔM NAY" -> "HÔM NAY"
                "QUÁ HẠN" -> "QUÁ HẠN"
                "SẮP TỚI" -> "SẮP TỚI"
                else -> "NGÀY MAI"
            }
        }

        fun formatDeadlinePill(item: Coursework): String {
            return if (item.isDueTomorrow) {
                if (item.timeOnlyString == "Cuối ngày") "Mai" else item.timeOnlyString
            } else if (item.isDueToday) {
                item.timeOnlyString
            } else {
                item.compactDueString
            }
        }

        fun dueLabel(item: Coursework): String {
            return when {
                item.isCompleted -> "Đã nộp"
                item.isDueToday -> item.timeOnlyString
                item.isDueTomorrow -> if (item.timeOnlyString == "Cuối ngày") "Mai" else "Mai ${item.timeOnlyString}"
                item.dueEpochMillis == null -> "Không hạn"
                else -> item.compactDueString
            }
        }
    }
}

class ClassroomSmallGlanceWidget : ClassroomGlanceWidget(WidgetSizeOverride.SMALL)
class ClassroomMediumGlanceWidget : ClassroomGlanceWidget(WidgetSizeOverride.MEDIUM)
class ClassroomLargeGlanceWidget : ClassroomGlanceWidget(WidgetSizeOverride.LARGE)
