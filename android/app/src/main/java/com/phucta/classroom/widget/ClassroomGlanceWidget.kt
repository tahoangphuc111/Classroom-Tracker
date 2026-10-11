package com.phucta.classroom.widget

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
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
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.theme.ChunkyColor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ClassroomGlanceWidget : GlanceAppWidget() {

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
                    database.courseworkDao().getAllCoursework()
                        .map { it.toDomain() }
                        .filter { !MockDataProvider.isMockCourseworkId(it.id) }
                } else {
                    emptyList()
                }
                val personalNotes = if (authed) {
                    database.personalNoteDao().getAllNotes()
                        .map { it.toDomain() }
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
                Pair(authed, items)
            } catch (e: Exception) {
                Pair(false, emptyList())
            }
        }

        provideContent {
            GlanceTheme {
                val currentSize = androidx.glance.LocalSize.current
                val isSmall = currentSize.width < 200.dp
                val isLarge = currentSize.height >= 180.dp && !isSmall

                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .cornerRadius(18.dp)
                        .background(R.drawable.bg_widget_sky)
                        .clickable(actionStartActivity<MainActivity>())
                        .padding(if (isSmall) 7.dp else 9.dp)
                ) {
                    when {
                        !isAuthenticated -> {
                            UnauthenticatedWidgetView(
                                context = context,
                                currentSize = currentSize
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
        currentSize: DpSize
    ) {
        val isSmall = currentSize.width < 200.dp
        val isLarge = currentSize.height >= 180.dp && !isSmall

        when {
            isSmall -> {
                Column(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 44, EmberEmotion.NORMAL)
                    Image(
                        provider = ImageProvider(emberBitmap),
                        contentDescription = "Ember mascot",
                        modifier = GlanceModifier.size(44.dp)
                    )
                    Spacer(modifier = GlanceModifier.height(5.dp))
                    Box(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .background(R.drawable.bg_widget_card)
                            .padding(horizontal = 6.dp, vertical = 6.dp)
                    ) {
                        Column(
                            modifier = GlanceModifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Chưa đăng nhập",
                                maxLines = 1,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextPrimary),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 10.5.sp
                                )
                            )
                            Spacer(modifier = GlanceModifier.height(2.dp))
                            Text(
                                text = "Chạm để đăng nhập",
                                maxLines = 1,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.PillBlue),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 8.5.sp
                                )
                            )
                        }
                    }
                }
            }

            isLarge -> {
                Column(
                    modifier = GlanceModifier.fillMaxSize()
                ) {
                    Row(
                        modifier = GlanceModifier.fillMaxWidth().height(68.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 68, EmberEmotion.NORMAL)
                        Image(
                            provider = ImageProvider(emberBitmap),
                            contentDescription = "Ember mascot",
                            modifier = GlanceModifier.size(68.dp)
                        )
                        Spacer(modifier = GlanceModifier.width(12.dp))
                        Column {
                            Text(
                                text = "BÁO BÀI NGÀY MAI",
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.ButterYellow),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.5.sp
                                )
                            )
                            Spacer(modifier = GlanceModifier.height(2.dp))
                            Text(
                                text = "Chưa đăng nhập",
                                style = TextStyle(
                                    color = ColorProvider(Color.White),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 20.sp
                                )
                            )
                        }
                    }

                    Spacer(modifier = GlanceModifier.height(6.dp))

                    Box(
                        modifier = GlanceModifier
                            .defaultWeight()
                            .fillMaxWidth()
                            .background(R.drawable.bg_widget_card_large)
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
                                modifier = GlanceModifier.size(34.dp)
                            )
                            Spacer(modifier = GlanceModifier.height(8.dp))
                            Text(
                                text = "Chạm để đăng nhập",
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextPrimary),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.5.sp
                                )
                            )
                            Spacer(modifier = GlanceModifier.height(4.dp))
                            Text(
                                text = "Đăng nhập tài khoản Google Classroom để theo dõi bài tập cần hoàn thành cho ngày mai.",
                                maxLines = 3,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextMuted),
                                    fontWeight = FontWeight.Medium,
                                    fontSize = 11.sp
                                )
                            )
                        }
                    }
                }
            }

            else -> {
                Row(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(
                        modifier = GlanceModifier.width(88.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 62, EmberEmotion.NORMAL)
                        Image(
                            provider = ImageProvider(emberBitmap),
                            contentDescription = "Ember mascot",
                            modifier = GlanceModifier.size(62.dp)
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = "Báo bài",
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.ButterYellow),
                                fontWeight = FontWeight.Bold,
                                fontSize = 10.5.sp
                            )
                        )
                    }

                    Spacer(modifier = GlanceModifier.width(8.dp))

                    Box(
                        modifier = GlanceModifier
                            .defaultWeight()
                            .fillMaxHeight()
                            .background(R.drawable.bg_widget_card)
                            .padding(horizontal = 10.dp, vertical = 8.dp)
                    ) {
                        Column(
                            modifier = GlanceModifier.fillMaxSize(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_person),
                                contentDescription = "Sign in",
                                modifier = GlanceModifier.size(24.dp)
                            )
                            Spacer(modifier = GlanceModifier.height(4.dp))
                            Text(
                                text = "Chưa đăng nhập",
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextPrimary),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.5.sp
                                )
                            )
                            Spacer(modifier = GlanceModifier.height(2.dp))
                            Text(
                                text = "Chạm để đăng nhập Google Classroom",
                                maxLines = 2,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextMuted),
                                    fontWeight = FontWeight.Medium,
                                    fontSize = 10.sp
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
        val activeItems = courseworkList.filter { !it.isCompleted }
        val displayItems = if (activeItems.isEmpty()) courseworkList else activeItems
        val sectionTitle = getSectionHeaderTitle(courseworkList)
        val shownCount = if (displayItems.size == 1) 1 else 2
        val extraCount = maxOf(0, activeItems.size - shownCount)

        val emotion = when {
            activeItems.isEmpty() -> if (courseworkList.any { it.isCompleted }) EmberEmotion.CELEBRATING else EmberEmotion.SLEEPING
            activeItems.size >= 3 -> EmberEmotion.STRESSED
            else -> EmberEmotion.NORMAL
        }

        Column(
            modifier = GlanceModifier.fillMaxSize()
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
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
                            fontSize = 26.sp
                        )
                    )
                    Spacer(modifier = GlanceModifier.width(4.dp))

                    if (activeItems.isEmpty() && courseworkList.isNotEmpty()) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_widget_seal_check),
                            contentDescription = "Completed",
                            modifier = GlanceModifier.size(13.dp)
                        )
                    } else {
                        Text(
                            text = sectionTitle,
                            maxLines = 1,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.ButterYellow),
                                fontWeight = FontWeight.Bold,
                                fontSize = 9.sp
                            )
                        )
                    }

                    if (extraCount > 0) {
                        Spacer(modifier = GlanceModifier.width(3.dp))
                        Box(
                            modifier = GlanceModifier
                                .cornerRadius(8.dp)
                                .background(ChunkyColor.UrgentAccent)
                                .padding(horizontal = 4.dp, vertical = 1.dp)
                        ) {
                            Text(
                                text = "+$extraCount",
                                style = TextStyle(
                                    color = ColorProvider(Color.White),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 8.sp
                                )
                            )
                        }
                    }
                }

                Spacer(modifier = GlanceModifier.defaultWeight())

                val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 38, emotion)
                Image(
                    provider = ImageProvider(emberBitmap),
                    contentDescription = "Ember mascot",
                    modifier = GlanceModifier.size(38.dp)
                )
            }

            Spacer(modifier = GlanceModifier.height(4.dp))

            Box(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxWidth()
                    .background(R.drawable.bg_widget_card)
                    .padding(horizontal = 7.dp, vertical = 6.dp)
            ) {
                if (displayItems.isEmpty()) {
                    Column(
                        modifier = GlanceModifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_sparkles),
                                contentDescription = "Done",
                                modifier = GlanceModifier.size(12.dp)
                            )
                            Spacer(modifier = GlanceModifier.width(4.dp))
                            Text(
                                text = "Rảnh rồi!",
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextPrimary),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.5.sp
                                )
                            )
                        }
                        Spacer(modifier = GlanceModifier.height(2.dp))
                        Text(
                            text = "Nghỉ ngơi nhé",
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.TextMuted),
                                fontWeight = FontWeight.Medium,
                                fontSize = 10.sp
                            )
                        )
                    }
                } else if (displayItems.size == 1) {
                    val item = displayItems.first()
                    val theme = SubjectArtHelper.theme(item.courseName, item.title)

                    Column(
                        modifier = GlanceModifier.fillMaxSize()
                    ) {
                        Row(
                            modifier = GlanceModifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = GlanceModifier
                                    .cornerRadius(4.dp)
                                    .background(theme.color)
                                    .padding(horizontal = 4.dp, vertical = 1.5.dp)
                            ) {
                                Text(
                                    text = theme.badgeCode,
                                    style = TextStyle(
                                        color = ColorProvider(Color.White),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 8.5.sp
                                    )
                                )
                            }
                            Spacer(modifier = GlanceModifier.width(4.dp))
                            Text(
                                text = item.courseName,
                                maxLines = 1,
                                modifier = GlanceModifier.defaultWeight(),
                                style = TextStyle(
                                    color = ColorProvider(theme.color),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.sp
                                )
                            )
                            Spacer(modifier = GlanceModifier.width(3.dp))
                            if (item.isCompleted) {
                                Image(
                                    provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                    contentDescription = "Turned in",
                                    modifier = GlanceModifier.size(12.dp)
                                )
                            } else {
                                val labelText = if (item.isDueToday || item.isDueTomorrow) item.timeOnlyString else item.compactDueString
                                Box(
                                    modifier = GlanceModifier
                                        .cornerRadius(6.dp)
                                        .background(if (item.isUrgent) ChunkyColor.UrgentAccent.copy(alpha = 0.12f) else Color(0x0F000000))
                                        .padding(horizontal = 4.dp, vertical = 1.dp)
                                ) {
                                    Text(
                                        text = labelText,
                                        style = TextStyle(
                                            color = ColorProvider(if (item.isUrgent) ChunkyColor.UrgentAccent else ChunkyColor.TextMuted),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 8.5.sp
                                        )
                                    )
                                }
                            }
                        }

                        Spacer(modifier = GlanceModifier.height(3.dp))
                        Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(ChunkyColor.Hairline)) {}
                        Spacer(modifier = GlanceModifier.height(3.dp))

                        Text(
                            text = item.title.ifEmpty { item.courseName },
                            maxLines = 2,
                            style = TextStyle(
                                color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.5.sp
                            )
                        )

                        Spacer(modifier = GlanceModifier.defaultWeight())

                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_clock),
                                contentDescription = "Due time",
                                modifier = GlanceModifier.size(9.dp)
                            )
                            Spacer(modifier = GlanceModifier.width(3.dp))
                            Text(
                                text = dueLabel(item),
                                style = TextStyle(
                                    color = ColorProvider(if (item.isUrgent) ChunkyColor.UrgentAccent else if (item.isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted),
                                    fontWeight = FontWeight.Medium,
                                    fontSize = 9.sp
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
                                        .cornerRadius(4.dp)
                                        .background(theme.color)
                                        .padding(horizontal = 4.dp, vertical = 1.5.dp)
                                ) {
                                    Text(
                                        text = theme.badgeCode,
                                        style = TextStyle(
                                            color = ColorProvider(Color.White),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 8.sp
                                        )
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(5.dp))
                                Column(
                                    modifier = GlanceModifier.defaultWeight()
                                ) {
                                    Text(
                                        text = item.title.ifEmpty { item.courseName },
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 11.5.sp
                                        )
                                    )
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            text = item.courseName,
                                            maxLines = 1,
                                            style = TextStyle(
                                                color = ColorProvider(ChunkyColor.TextMuted),
                                                fontSize = 9.sp
                                            )
                                        )
                                        Text(
                                            text = " • ",
                                            style = TextStyle(
                                                color = ColorProvider(ChunkyColor.TextMuted),
                                                fontSize = 7.5.sp
                                            )
                                        )
                                        Text(
                                            text = dueLabel(item),
                                            maxLines = 1,
                                            style = TextStyle(
                                                color = ColorProvider(if (item.isUrgent) ChunkyColor.UrgentAccent else if (item.isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted),
                                                fontWeight = FontWeight.Medium,
                                                fontSize = 9.sp
                                            )
                                        )
                                    }
                                }
                                if (item.isCompleted) {
                                    Spacer(modifier = GlanceModifier.width(3.dp))
                                    Image(
                                        provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                        contentDescription = "Done",
                                        modifier = GlanceModifier.size(12.dp)
                                    )
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
        val activeItems = courseworkList.filter { !it.isCompleted }
        val completedItems = courseworkList.filter { it.isCompleted }
        val displayItems = if (activeItems.isEmpty()) courseworkList else (activeItems + completedItems)
        val sectionTitle = getSectionHeaderTitle(courseworkList)

        val emotion = when {
            activeItems.isEmpty() -> if (completedItems.isNotEmpty()) EmberEmotion.CELEBRATING else EmberEmotion.SLEEPING
            activeItems.size >= 4 -> EmberEmotion.STRESSED
            else -> EmberEmotion.NORMAL
        }

        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = GlanceModifier.width(92.dp).fillMaxHeight(),
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
                            fontSize = 30.sp
                        )
                    )
                    Spacer(modifier = GlanceModifier.width(4.dp))
                    if (activeItems.isEmpty() && courseworkList.isNotEmpty()) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_widget_seal_check),
                            contentDescription = "Completed",
                            modifier = GlanceModifier.size(15.dp)
                        )
                    } else {
                        Text(
                            text = sectionTitle,
                            maxLines = 1,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.ButterYellow),
                                fontWeight = FontWeight.Bold,
                                fontSize = 9.sp
                            )
                        )
                    }
                }

                Spacer(modifier = GlanceModifier.height(2.dp))

                val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 68, emotion)
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
                    .background(R.drawable.bg_widget_card)
                    .padding(horizontal = 10.dp, vertical = 6.dp)
            ) {
                Column(
                    modifier = GlanceModifier.fillMaxSize()
                ) {
                    Row(
                        modifier = GlanceModifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = sectionTitle,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.TextMuted),
                                fontWeight = FontWeight.Bold,
                                fontSize = 9.5.sp
                            )
                        )

                        Spacer(modifier = GlanceModifier.defaultWeight())

                        if (activeItems.size > 3) {
                            Box(
                                modifier = GlanceModifier
                                    .cornerRadius(8.dp)
                                    .background(ChunkyColor.UrgentAccent.copy(alpha = 0.12f))
                                    .padding(horizontal = 6.dp, vertical = 1.5.dp)
                            ) {
                                Text(
                                    text = "+${activeItems.size - 3}",
                                    style = TextStyle(
                                        color = ColorProvider(ChunkyColor.UrgentAccent),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 8.5.sp
                                    )
                                )
                            }
                        } else if (activeItems.isNotEmpty()) {
                            Text(
                                text = "${activeItems.size}",
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextMuted),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 9.sp
                                )
                            )
                        } else if (courseworkList.isNotEmpty()) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                contentDescription = "All done",
                                modifier = GlanceModifier.size(11.dp)
                            )
                        }
                    }

                    Spacer(modifier = GlanceModifier.height(3.dp))
                    Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(ChunkyColor.Hairline)) {}
                    Spacer(modifier = GlanceModifier.height(3.dp))

                    if (displayItems.isEmpty()) {
                        Row(
                            modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = GlanceModifier
                                    .cornerRadius(15.dp)
                                    .background(ChunkyColor.ButterYellow.copy(alpha = 0.35f))
                                    .padding(6.dp)
                            ) {
                                Image(
                                    provider = ImageProvider(R.drawable.ic_widget_sparkles),
                                    contentDescription = "Free day",
                                    modifier = GlanceModifier.size(18.dp)
                                )
                            }
                            Spacer(modifier = GlanceModifier.width(8.dp))
                            Column {
                                val emptyTitle = if (sectionTitle == "HÔM NAY") "Hôm nay rảnh rồi!" else if (sectionTitle == "SẮP TỚI") "Tạm thời rảnh rồi!" else "Ngày mai rảnh rồi!"
                                Text(
                                    text = emptyTitle,
                                    style = TextStyle(
                                        color = ColorProvider(ChunkyColor.TextPrimary),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 13.5.sp
                                    )
                                )
                                Spacer(modifier = GlanceModifier.height(2.dp))
                                Text(
                                    text = "Tất cả môn học đã hoàn thành.\nNghỉ ngơi và thư giãn nhé.",
                                    maxLines = 2,
                                    style = TextStyle(
                                        color = ColorProvider(ChunkyColor.TextMuted),
                                        fontWeight = FontWeight.Medium,
                                        fontSize = 10.sp
                                    )
                                )
                            }
                        }
                    } else if (displayItems.size == 1) {
                        val item = displayItems.first()
                        val theme = SubjectArtHelper.theme(item.courseName, item.title)

                        Column(
                            modifier = GlanceModifier.defaultWeight().fillMaxWidth()
                        ) {
                            Row(
                                modifier = GlanceModifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = GlanceModifier
                                        .cornerRadius(5.dp)
                                        .background(theme.color)
                                        .padding(horizontal = 5.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = theme.badgeCode,
                                        style = TextStyle(
                                            color = ColorProvider(Color.White),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 9.sp
                                        )
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(6.dp))
                                Text(
                                    text = item.courseName,
                                    maxLines = 1,
                                    modifier = GlanceModifier.defaultWeight(),
                                    style = TextStyle(
                                        color = ColorProvider(theme.color),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 12.sp
                                    )
                                )
                                Spacer(modifier = GlanceModifier.width(4.dp))
                                if (item.isCompleted) {
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(8.dp)
                                            .background(ChunkyColor.SuccessGreen.copy(alpha = 0.12f))
                                            .padding(horizontal = 6.dp, vertical = 2.dp)
                                    ) {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Image(
                                                provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                                contentDescription = "Done",
                                                modifier = GlanceModifier.size(10.dp)
                                            )
                                            Spacer(modifier = GlanceModifier.width(3.dp))
                                            Text(
                                                text = "Đã xong",
                                                style = TextStyle(
                                                    color = ColorProvider(ChunkyColor.SuccessGreen),
                                                    fontWeight = FontWeight.Bold,
                                                    fontSize = 9.sp
                                                )
                                            )
                                        }
                                    }
                                } else {
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(8.dp)
                                            .background(if (item.isUrgent) ChunkyColor.UrgentAccent.copy(alpha = 0.12f) else Color(0x0F000000))
                                            .padding(horizontal = 6.dp, vertical = 2.dp)
                                    ) {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Image(
                                                provider = ImageProvider(R.drawable.ic_widget_clock),
                                                contentDescription = "Clock",
                                                modifier = GlanceModifier.size(9.dp)
                                            )
                                            Spacer(modifier = GlanceModifier.width(3.dp))
                                            Text(
                                                text = if (item.isDueTomorrow) item.timeOnlyString else item.compactDueString,
                                                style = TextStyle(
                                                    color = ColorProvider(if (item.isUrgent) ChunkyColor.UrgentAccent else ChunkyColor.TextPrimary),
                                                    fontWeight = FontWeight.Bold,
                                                    fontSize = 9.5.sp
                                                )
                                            )
                                        }
                                    }
                                }
                            }

                            Spacer(modifier = GlanceModifier.height(3.dp))

                            Text(
                                text = item.title.ifEmpty { item.courseName },
                                maxLines = 2,
                                style = TextStyle(
                                    color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.5.sp
                                )
                            )

                            Spacer(modifier = GlanceModifier.height(2.dp))

                            val descSnippet = item.description?.lines()?.firstOrNull { it.isNotBlank() }?.trim().orEmpty()
                            val subtitleText = descSnippet.ifEmpty {
                                if (item.isCompleted) "Bài tập đã được đánh dấu hoàn thành"
                                else if (item.isUrgent) "Hạn nộp sắp tới, hãy hoàn thành sớm"
                                else "Chạm để xem chi tiết bài tập"
                            }
                            Text(
                                text = subtitleText,
                                maxLines = 1,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextMuted),
                                    fontWeight = FontWeight.Medium,
                                    fontSize = 10.sp
                                )
                            )
                        }
                    } else {
                        val itemsToShow = displayItems.take(3)
                        Column(
                            modifier = GlanceModifier.defaultWeight().fillMaxWidth()
                        ) {
                            itemsToShow.forEachIndexed { index, item ->
                                val theme = SubjectArtHelper.theme(item.courseName, item.title)
                                Row(
                                    modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(5.dp)
                                            .background(theme.color)
                                            .padding(horizontal = 5.dp, vertical = 2.dp)
                                    ) {
                                        Text(
                                            text = theme.badgeCode,
                                            style = TextStyle(
                                                color = ColorProvider(Color.White),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 8.5.sp
                                            )
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
                                                fontSize = 12.sp
                                            )
                                        )
                                        Text(
                                            text = item.courseName,
                                            maxLines = 1,
                                            style = TextStyle(
                                                color = ColorProvider(ChunkyColor.TextMuted),
                                                fontSize = 9.5.sp
                                            )
                                        )
                                    }
                                    Spacer(modifier = GlanceModifier.width(4.dp))
                                    if (item.isCompleted) {
                                        Image(
                                            provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                            contentDescription = "Done",
                                            modifier = GlanceModifier.size(12.dp)
                                        )
                                    } else {
                                        val timeText = if (item.isDueTomorrow) {
                                            if (item.timeOnlyString == "Cuối ngày") "Mai" else item.timeOnlyString
                                        } else {
                                            item.compactDueString
                                        }
                                        Box(
                                            modifier = GlanceModifier
                                                .cornerRadius(7.dp)
                                                .background(if (item.isUrgent) ChunkyColor.UrgentAccent.copy(alpha = 0.12f) else Color(0x0F000000))
                                                .padding(horizontal = 5.dp, vertical = 1.5.dp)
                                        ) {
                                            Text(
                                                text = timeText,
                                                style = TextStyle(
                                                    color = ColorProvider(if (item.isUrgent) ChunkyColor.UrgentAccent else ChunkyColor.TextMuted),
                                                    fontWeight = FontWeight.Bold,
                                                    fontSize = 9.sp
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

        val emotion = when {
            activeItems.isEmpty() -> if (completedItems.isNotEmpty()) EmberEmotion.CELEBRATING else EmberEmotion.SLEEPING
            activeItems.size >= 4 -> EmberEmotion.STRESSED
            else -> EmberEmotion.NORMAL
        }

        Column(
            modifier = GlanceModifier.fillMaxSize()
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth().height(72.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                val emberBitmap = EmberWidgetBitmapHelper.getEmberBitmap(context, 70, emotion)
                Image(
                    provider = ImageProvider(emberBitmap),
                    contentDescription = "Ember mascot",
                    modifier = GlanceModifier.size(70.dp)
                )

                Spacer(modifier = GlanceModifier.width(12.dp))

                Column {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "${activeItems.size}",
                            style = TextStyle(
                                color = ColorProvider(Color.White),
                                fontWeight = FontWeight.Bold,
                                fontSize = 34.sp
                            )
                        )
                        Spacer(modifier = GlanceModifier.width(6.dp))
                        Text(
                            text = if (activeItems.isEmpty()) "HOÀN TẤT" else "CẦN NỘP",
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.ButterYellow),
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp
                            )
                        )
                    }

                    Spacer(modifier = GlanceModifier.height(3.dp))

                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        val isUrgentGroup = activeItems.any { it.isUrgent }
                        Box(
                            modifier = GlanceModifier
                                .cornerRadius(8.dp)
                                .background(if (isUrgentGroup) ChunkyColor.UrgentAccent else Color(0x38FFFFFF))
                                .padding(horizontal = 7.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "$sectionCapsule: ${activeItems.size}",
                                style = TextStyle(
                                    color = ColorProvider(Color.White),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 9.sp
                                )
                            )
                        }

                        if (completedItems.isNotEmpty()) {
                            Spacer(modifier = GlanceModifier.width(5.dp))
                            Box(
                                modifier = GlanceModifier
                                    .cornerRadius(8.dp)
                                    .background(Color(0xD92E7D32))
                                    .padding(horizontal = 7.dp, vertical = 2.dp)
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Image(
                                        provider = ImageProvider(R.drawable.ic_widget_seal_check),
                                        contentDescription = "Done count",
                                        modifier = GlanceModifier.size(9.dp)
                                    )
                                    Spacer(modifier = GlanceModifier.width(3.dp))
                                    Text(
                                        text = "Đã xong: ${completedItems.size}",
                                        style = TextStyle(
                                            color = ColorProvider(Color.White),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 9.sp
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = GlanceModifier.height(6.dp))

            Box(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxWidth()
                    .background(R.drawable.bg_widget_card_large)
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            ) {
                Column(
                    modifier = GlanceModifier.fillMaxSize()
                ) {
                    Row(
                        modifier = GlanceModifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = sectionTitle,
                            style = TextStyle(
                                color = ColorProvider(ChunkyColor.TextMuted),
                                fontWeight = FontWeight.Bold,
                                fontSize = 10.sp
                            )
                        )

                        Spacer(modifier = GlanceModifier.defaultWeight())

                        if (activeItems.isNotEmpty()) {
                            Box(
                                modifier = GlanceModifier
                                    .cornerRadius(8.dp)
                                    .background(ChunkyColor.UrgentAccent.copy(alpha = 0.12f))
                                    .padding(horizontal = 7.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = "${activeItems.size}",
                                    style = TextStyle(
                                        color = ColorProvider(ChunkyColor.UrgentAccent),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 9.sp
                                    )
                                )
                            }
                        } else if (courseworkList.isNotEmpty()) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                contentDescription = "Done",
                                modifier = GlanceModifier.size(12.dp)
                            )
                        }
                    }

                    Spacer(modifier = GlanceModifier.height(3.dp))
                    Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(ChunkyColor.Hairline)) {}
                    Spacer(modifier = GlanceModifier.height(3.dp))

                    if (displayItems.isEmpty()) {
                        Column(
                            modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Image(
                                    provider = ImageProvider(R.drawable.ic_widget_sparkles),
                                    contentDescription = "Great",
                                    modifier = GlanceModifier.size(16.dp)
                                )
                                Spacer(modifier = GlanceModifier.width(6.dp))
                                Text(
                                    text = "Tuyệt vời!",
                                    style = TextStyle(
                                        color = ColorProvider(ChunkyColor.TextPrimary),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 17.sp
                                    )
                                )
                                Spacer(modifier = GlanceModifier.width(6.dp))
                                Image(
                                    provider = ImageProvider(R.drawable.ic_widget_sparkles),
                                    contentDescription = "Great",
                                    modifier = GlanceModifier.size(16.dp)
                                )
                            }
                            Spacer(modifier = GlanceModifier.height(4.dp))
                            Text(
                                text = "Không có môn nào cần nộp",
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
                            modifier = GlanceModifier.defaultWeight().fillMaxWidth()
                        ) {
                            Row(
                                modifier = GlanceModifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = GlanceModifier
                                        .cornerRadius(7.dp)
                                        .background(theme.color)
                                        .padding(horizontal = 7.dp, vertical = 3.dp)
                                ) {
                                    Text(
                                        text = theme.badgeCode,
                                        style = TextStyle(
                                            color = ColorProvider(Color.White),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 11.sp
                                        )
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(8.dp))
                                Column(
                                    modifier = GlanceModifier.defaultWeight()
                                ) {
                                    Text(
                                        text = item.courseName,
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(theme.color),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 13.5.sp
                                        )
                                    )
                                    Text(
                                        text = item.formattedFullDueDate,
                                        maxLines = 1,
                                        style = TextStyle(
                                            color = ColorProvider(ChunkyColor.TextMuted),
                                            fontSize = 10.sp
                                        )
                                    )
                                }
                                Spacer(modifier = GlanceModifier.width(4.dp))
                                if (item.isCompleted) {
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(8.dp)
                                            .background(ChunkyColor.SuccessGreen.copy(alpha = 0.12f))
                                            .padding(horizontal = 7.dp, vertical = 3.dp)
                                    ) {
                                        Text(
                                            text = "Đã xong",
                                            style = TextStyle(
                                                color = ColorProvider(ChunkyColor.SuccessGreen),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 10.sp
                                            )
                                        )
                                    }
                                } else {
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(8.dp)
                                            .background(if (item.isUrgent) ChunkyColor.UrgentAccent.copy(alpha = 0.12f) else Color(0x0F000000))
                                            .padding(horizontal = 7.dp, vertical = 3.dp)
                                    ) {
                                        Text(
                                            text = if (item.isDueTomorrow) item.timeOnlyString else item.compactDueString,
                                            style = TextStyle(
                                                color = ColorProvider(if (item.isUrgent) ChunkyColor.UrgentAccent else ChunkyColor.TextMuted),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 10.5.sp
                                            )
                                        )
                                    }
                                }
                            }

                            Spacer(modifier = GlanceModifier.height(5.dp))
                            Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(ChunkyColor.Hairline)) {}
                            Spacer(modifier = GlanceModifier.height(5.dp))

                            Text(
                                text = item.title.ifEmpty { item.courseName },
                                maxLines = 3,
                                style = TextStyle(
                                    color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.5.sp
                                )
                            )

                            Spacer(modifier = GlanceModifier.height(4.dp))

                            val descSnippet = item.description?.lines()?.firstOrNull { it.isNotBlank() }?.trim().orEmpty()
                            val subtitleText = descSnippet.ifEmpty {
                                if (item.isCompleted) "Bài tập đã được đánh dấu hoàn thành"
                                else "Chạm để xem chi tiết bài tập và nộp bài"
                            }
                            Text(
                                text = subtitleText,
                                maxLines = 2,
                                style = TextStyle(
                                    color = ColorProvider(ChunkyColor.TextMuted),
                                    fontWeight = FontWeight.Medium,
                                    fontSize = 11.5.sp
                                )
                            )
                        }
                    } else {
                        val itemsToShow = displayItems.take(5)
                        Column(
                            modifier = GlanceModifier.defaultWeight().fillMaxWidth()
                        ) {
                            itemsToShow.forEachIndexed { index, item ->
                                val theme = SubjectArtHelper.theme(item.courseName, item.title)
                                Row(
                                    modifier = GlanceModifier.defaultWeight().fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = GlanceModifier
                                            .cornerRadius(5.dp)
                                            .background(theme.color)
                                            .padding(horizontal = 5.dp, vertical = 2.dp)
                                    ) {
                                        Text(
                                            text = theme.badgeCode,
                                            style = TextStyle(
                                                color = ColorProvider(Color.White),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 8.5.sp
                                            )
                                        )
                                    }
                                    Spacer(modifier = GlanceModifier.width(7.dp))
                                    Column(
                                        modifier = GlanceModifier.defaultWeight()
                                    ) {
                                        Text(
                                            text = item.title.ifEmpty { item.courseName },
                                            maxLines = 1,
                                            style = TextStyle(
                                                color = ColorProvider(if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 12.5.sp
                                            )
                                        )
                                        Text(
                                            text = item.courseName,
                                            maxLines = 1,
                                            style = TextStyle(
                                                color = ColorProvider(ChunkyColor.TextMuted),
                                                fontSize = 9.5.sp
                                            )
                                        )
                                    }
                                    Spacer(modifier = GlanceModifier.width(4.dp))
                                    if (item.isCompleted) {
                                        Image(
                                            provider = ImageProvider(R.drawable.ic_widget_check_circle),
                                            contentDescription = "Done",
                                            modifier = GlanceModifier.size(13.dp)
                                        )
                                    } else {
                                        val timeText = if (item.isDueTomorrow) item.timeOnlyString else item.compactDueString
                                        Box(
                                            modifier = GlanceModifier
                                                .cornerRadius(7.dp)
                                                .background(if (item.isUrgent) ChunkyColor.UrgentAccent.copy(alpha = 0.12f) else Color(0x0F000000))
                                                .padding(horizontal = 6.dp, vertical = 2.dp)
                                        ) {
                                            Text(
                                                text = timeText,
                                                style = TextStyle(
                                                    color = ColorProvider(if (item.isUrgent) ChunkyColor.UrgentAccent else ChunkyColor.TextMuted),
                                                    fontWeight = FontWeight.Bold,
                                                    fontSize = 9.5.sp
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
    }

    private fun getSectionHeaderTitle(items: List<Coursework>): String {
        val pending = items.filter { !it.isCompleted }
        val hasToday = pending.any { it.isDueToday }
        val hasTomorrow = pending.any { it.isDueTomorrow }

        return when {
            hasToday && hasTomorrow -> "HÔM NAY & MAI"
            hasToday -> "HÔM NAY"
            hasTomorrow -> "NGÀY MAI"
            pending.isNotEmpty() -> "SẮP TỚI"
            items.any { it.isDueToday } -> "HÔM NAY"
            else -> "NGÀY MAI"
        }
    }

    private fun getSectionCapsuleLabel(sectionTitle: String): String {
        return when (sectionTitle) {
            "HÔM NAY & MAI" -> "Hôm nay & mai"
            "HÔM NAY" -> "Hôm nay"
            "SẮP TỚI" -> "Sắp tới"
            else -> "Ngày mai"
        }
    }

    private fun dueLabel(item: Coursework): String {
        return when {
            item.isCompleted -> "Đã nộp"
            item.isDueToday -> item.timeOnlyString
            item.isDueTomorrow -> if (item.timeOnlyString == "Cuối ngày") "Mai" else "Mai ${item.timeOnlyString}"
            item.dueEpochMillis == null -> "Không hạn"
            else -> item.compactDueString
        }
    }
}
