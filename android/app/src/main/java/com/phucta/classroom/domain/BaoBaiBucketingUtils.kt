package com.phucta.classroom.domain

import androidx.compose.runtime.Immutable
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.data.model.SubmissionStatus
import java.util.Calendar

object BaoBaiBucketingUtils {
    @Immutable
    data class CourseworkBuckets(
        val overdue: List<Coursework> = emptyList(),
        val today: List<Coursework> = emptyList(),
        val tomorrow: List<Coursework> = emptyList(),
        val laterUpcoming: List<Coursework> = emptyList(),
        val noDueDate: List<Coursework> = emptyList(),
        val completed: List<Coursework> = emptyList(),
        val widgetItems: List<Coursework> = emptyList()
    ) {
        val todayAndTomorrow: List<Coursework> by lazy(LazyThreadSafetyMode.NONE) {
            val sToday = today.size
            val sTomorrow = tomorrow.size
            if (sToday == 0) tomorrow
            else if (sTomorrow == 0) today
            else {
                val list = ArrayList<Coursework>(sToday + sTomorrow)
                list.addAll(today)
                list.addAll(tomorrow)
                list
            }
        }

        val allUpcoming: List<Coursework> by lazy(LazyThreadSafetyMode.NONE) {
            val total = today.size + tomorrow.size + laterUpcoming.size + noDueDate.size
            if (total == 0) emptyList()
            else {
                val list = ArrayList<Coursework>(total)
                list.addAll(today)
                list.addAll(tomorrow)
                list.addAll(laterUpcoming)
                list.addAll(noDueDate)
                list
            }
        }
    }

    val COURSEWORK_COMPARATOR = Comparator<Coursework> { first, second ->
        val c1 = first.isCompleted
        val c2 = second.isCompleted
        if (c1 != c2) {
            return@Comparator if (!c1) -1 else 1
        }
        val d1 = first.dueEpochMillis
        val d2 = second.dueEpochMillis
        if (d1 != null) {
            if (d2 != null) {
                val diff = d1.compareTo(d2)
                if (diff != 0) return@Comparator diff
            } else {
                return@Comparator -1
            }
        } else if (d2 != null) {
            return@Comparator 1
        }

        val titleDiff = first.title.compareTo(second.title, ignoreCase = true)
        if (titleDiff != 0) titleDiff else first.id.compareTo(second.id)
    }

    val SAME_STATUS_COURSEWORK_COMPARATOR = Comparator<Coursework> { first, second ->
        val d1 = first.dueEpochMillis
        val d2 = second.dueEpochMillis
        if (d1 != null) {
            if (d2 != null) {
                val diff = d1.compareTo(d2)
                if (diff != 0) return@Comparator diff
            } else {
                return@Comparator -1
            }
        } else if (d2 != null) {
            return@Comparator 1
        }

        val titleDiff = first.title.compareTo(second.title, ignoreCase = true)
        if (titleDiff != 0) titleDiff else first.id.compareTo(second.id)
    }

    private class ScoredCoursework(
        val item: Coursework,
        val score: Int
    )

    fun sortCoursework(
        items: List<Coursework>,
        searchTokens: List<String> = emptyList(),
        rawNormalizedQuery: String = ""
    ): List<Coursework> {
        val itemCount = items.size
        if (itemCount <= 1) return items
        if (searchTokens.isNotEmpty()) {
            val tokenCount = searchTokens.size
            val filteredItems = ArrayList<Coursework>(itemCount)
            for (i in 0 until itemCount) {
                val item = items[i]
                val idx = item.searchIndex
                var matchesAll = true
                for (t in 0 until tokenCount) {
                    if (!idx.contains(searchTokens[t])) {
                        matchesAll = false
                        break
                    }
                }
                if (matchesAll) {
                    filteredItems.add(item)
                }
            }
            return sortPreFiltered(filteredItems, searchTokens, rawNormalizedQuery, COURSEWORK_COMPARATOR)
        }
        val copy = ArrayList<Coursework>(itemCount)
        copy.addAll(items)
        copy.sortWith(COURSEWORK_COMPARATOR)
        return copy
    }

    private fun sortPreFiltered(
        items: ArrayList<Coursework>,
        searchTokens: List<String>,
        rawNormalizedQuery: String,
        comparator: Comparator<Coursework>
    ): List<Coursework> {
        val count = items.size
        if (count <= 1) return items
        if (searchTokens.isNotEmpty()) {
            val scoredItems = Array(count) { index ->
                val item = items[index]
                val score = com.phucta.classroom.data.model.calculateSearchRelevance(
                    queryTokens = searchTokens,
                    rawNormalizedQuery = rawNormalizedQuery,
                    title = item.title,
                    courseName = item.courseName,
                    content = null,
                    normalizedTitle = item.normalizedTitle,
                    normalizedCourseName = item.normalizedCourseName
                )
                ScoredCoursework(item, score)
            }
            scoredItems.sortWith { a, b ->
                val diff = b.score.compareTo(a.score)
                if (diff != 0) diff else comparator.compare(a.item, b.item)
            }
            val result = ArrayList<Coursework>(count)
            for (i in 0 until count) {
                result.add(scoredItems[i].item)
            }
            return result
        }
        items.sortWith(comparator)
        return items
    }

    private fun sortInternal(
        items: ArrayList<Coursework>,
        searchTokens: List<String>,
        rawNormalizedQuery: String
    ): List<Coursework> {
        return sortPreFiltered(items, searchTokens, rawNormalizedQuery, COURSEWORK_COMPARATOR)
    }

    private data class CourseFilterCache(
        val coursesRef: List<Course>,
        val hasUnselected: Boolean,
        val allCourseIds: Set<String>,
        val activeCourseIds: Set<String>
    )

    @Volatile
    private var cachedCourseFilter: CourseFilterCache? = null

    private fun getCourseFilter(courses: List<Course>): CourseFilterCache {
        val cached = cachedCourseFilter
        if (cached != null && (cached.coursesRef === courses || cached.coursesRef == courses)) {
            return cached
        }

        val courseCount = courses.size
        var hasUnselected = false
        val allCourseIds = HashSet<String>(courseCount * 2)
        val activeCourseIds = HashSet<String>(courseCount * 2)

        for (i in 0 until courseCount) {
            val course = courses[i]
            allCourseIds.add(course.id)
            if (course.isSelectedForWidget) {
                activeCourseIds.add(course.id)
            } else {
                hasUnselected = true
            }
        }

        val newCache = CourseFilterCache(
            coursesRef = courses,
            hasUnselected = hasUnselected,
            allCourseIds = allCourseIds,
            activeCourseIds = activeCourseIds
        )
        cachedCourseFilter = newCache
        return newCache
    }

    fun filterByActiveCourses(items: List<Coursework>, courses: List<Course>): List<Coursework> {
        if (courses.isEmpty() || items.isEmpty()) return items

        var hasUnselected = false
        val courseCount = courses.size
        for (i in 0 until courseCount) {
            if (!courses[i].isSelectedForWidget) {
                hasUnselected = true
                break
            }
        }
        if (!hasUnselected) return items

        val filter = getCourseFilter(courses)
        val allCourseIds = filter.allCourseIds
        val activeCourseIds = filter.activeCourseIds

        if (allCourseIds.size == activeCourseIds.size || activeCourseIds.isEmpty()) {
            return items
        }

        val result = ArrayList<Coursework>(items.size)
        var anyMatchesLoadedCourses = false
        val itemCount = items.size
        for (i in 0 until itemCount) {
            val item = items[i]
            if (allCourseIds.contains(item.courseId)) {
                anyMatchesLoadedCourses = true
                if (activeCourseIds.contains(item.courseId)) {
                    result.add(item)
                }
            } else {
                result.add(item)
            }
        }
        return if (anyMatchesLoadedCourses) result else items
    }

    fun getTomorrowCoursework(
        items: List<Coursework>,
        courses: List<Course> = emptyList(),
        includeCompleted: Boolean = true,
        personalNotes: List<PersonalNote> = emptyList(),
        includeNotes: Boolean = true
    ): List<Coursework> {
        val relevant = filterByActiveCourses(items, courses)
        val hasNotes = includeNotes && personalNotes.isNotEmpty()
        if (relevant.isEmpty() && !hasNotes) return emptyList()
        val now = System.currentTimeMillis()
        val startOfTomorrow = ClassroomDateUtils.startOfTomorrow
        val startOfDayAfter = ClassroomDateUtils.startOfDayAfter
        val estCap = maxOf(4, relevant.size shr 2)
        val tomorrowFiltered = ArrayList<Coursework>(estCap)
        val todayFiltered = ArrayList<Coursework>(estCap)
        val upcomingFiltered = ArrayList<Coursework>(estCap)
        val undatedFiltered = ArrayList<Coursework>(estCap)
        val count = relevant.size
        for (i in 0 until count) {
            val item = relevant[i]
            val isEligible = includeCompleted || !item.isCompleted
            if (!isEligible) continue
            val due = item.dueEpochMillis
            if (due != null) {
                if (due in startOfTomorrow until startOfDayAfter) {
                    tomorrowFiltered.add(item)
                } else if (due in now until startOfTomorrow) {
                    todayFiltered.add(item)
                } else if (due >= startOfDayAfter) {
                    upcomingFiltered.add(item)
                }
            } else {
                undatedFiltered.add(item)
            }
        }
        if (hasNotes) {
            val filter = if (courses.isNotEmpty()) getCourseFilter(courses) else null
            val filterActive = filter != null && filter.hasUnselected && filter.activeCourseIds.isNotEmpty() && filter.allCourseIds.size != filter.activeCourseIds.size
            val noteCount = personalNotes.size
            for (i in 0 until noteCount) {
                val note = personalNotes[i]
                if (note.courseworkId == null) {
                    val isEligible = includeCompleted || !note.isCompleted
                    if (isEligible && note.isDueTomorrow) {
                        val matchesCourse = if (filterActive && note.courseId != null && filter!!.allCourseIds.contains(note.courseId)) {
                            filter.activeCourseIds.contains(note.courseId)
                        } else {
                            true
                        }
                        if (matchesCourse) {
                            val noteCoursework = Coursework(
                                id = "note_${note.id}",
                                courseId = note.courseId ?: "personal_note",
                                courseName = note.courseName ?: "Ghi chú",
                                title = note.title,
                                description = note.content,
                                dueEpochMillis = note.dueEpochMillis,
                                status = if (note.isCompleted) SubmissionStatus.TURNED_IN else SubmissionStatus.PENDING,
                                isManuallyCompleted = note.isCompleted
                            )
                            tomorrowFiltered.add(noteCoursework)
                        }
                    }
                }
            }
        }
        if (tomorrowFiltered.isNotEmpty()) return sortInternal(tomorrowFiltered, emptyList(), "")
        if (todayFiltered.isNotEmpty()) return sortInternal(todayFiltered, emptyList(), "")
        if (upcomingFiltered.isNotEmpty()) return sortInternal(upcomingFiltered, emptyList(), "")
        if (undatedFiltered.isNotEmpty()) return sortInternal(undatedFiltered, emptyList(), "")
        return emptyList()
    }

    fun computeBuckets(
        items: List<Coursework>,
        courses: List<Course> = emptyList(),
        searchTokens: List<String> = emptyList(),
        rawNormalizedQuery: String = ""
    ): CourseworkBuckets {
        val totalCount = items.size
        if (totalCount == 0) return CourseworkBuckets()
        val filter = if (courses.isNotEmpty()) getCourseFilter(courses) else null
        val filterActive = filter != null && filter.hasUnselected && filter.activeCourseIds.isNotEmpty() && filter.allCourseIds.size != filter.activeCourseIds.size

        val allCourseIds = if (filterActive) filter!!.allCourseIds else null
        val activeCourseIds = if (filterActive) filter!!.activeCourseIds else null

        val hasSearchTokens = searchTokens.isNotEmpty()
        val tokenCount = searchTokens.size

        val now = System.currentTimeMillis()
        val startOfTomorrow = ClassroomDateUtils.startOfTomorrow
        val startOfDayAfter = ClassroomDateUtils.startOfDayAfter
        val estCapacity = maxOf(16, totalCount shr 2)
        val overdue = ArrayList<Coursework>(estCapacity)
        val today = ArrayList<Coursework>(estCapacity)
        val tomorrow = ArrayList<Coursework>(estCapacity)
        val later = ArrayList<Coursework>(estCapacity)
        val noDate = ArrayList<Coursework>(estCapacity)
        val completed = ArrayList<Coursework>(estCapacity)
        var completedTomorrowCount = 0
        var completedTodayCount = 0
        var completedLaterCount = 0
        var completedNoDateCount = 0
        var anyMatchesLoadedCourses = false
        for (i in 0 until totalCount) {
            val item = items[i]

            if (filterActive) {
                if (allCourseIds!!.contains(item.courseId)) {
                    anyMatchesLoadedCourses = true
                    if (!activeCourseIds!!.contains(item.courseId)) {
                        continue
                    }
                }
            }
            if (hasSearchTokens) {
                var matchesAll = true
                val idx = item.searchIndex
                for (t in 0 until tokenCount) {
                    if (!idx.contains(searchTokens[t])) {
                        matchesAll = false
                        break
                    }
                }
                if (!matchesAll) continue
            }
            val isCompleted = item.isCompleted
            val due = item.dueEpochMillis
            if (isCompleted) {
                completed.add(item)
                if (due != null) {
                    if (due in startOfTomorrow until startOfDayAfter) {
                        completedTomorrowCount++
                    } else if (due in now until startOfTomorrow) {
                        completedTodayCount++
                    } else if (due >= startOfDayAfter) {
                        completedLaterCount++
                    }
                } else {
                    completedNoDateCount++
                }
            } else {
                when {
                    due == null -> noDate.add(item)
                    due < now -> overdue.add(item)
                    due < startOfTomorrow -> today.add(item)
                    due < startOfDayAfter -> tomorrow.add(item)
                    else -> later.add(item)
                }
            }
        }
        if (filterActive && !anyMatchesLoadedCourses) {
            return computeBuckets(items, emptyList(), searchTokens, rawNormalizedQuery)
        }
        val hasTomorrow = tomorrow.isNotEmpty() || completedTomorrowCount > 0
        val hasToday = today.isNotEmpty() || completedTodayCount > 0
        val hasLater = later.isNotEmpty() || completedLaterCount > 0
        val hasNoDate = noDate.isNotEmpty() || completedNoDateCount > 0
        val tomorrowCandidates: List<Coursework> = when {
            hasTomorrow -> {
                if (completedTomorrowCount == 0) tomorrow
                else if (tomorrow.isEmpty()) {
                    val list = ArrayList<Coursework>(completedTomorrowCount)
                    for (c in completed) {
                        val d = c.dueEpochMillis
                        if (d != null && d in startOfTomorrow until startOfDayAfter) {
                            list.add(c)
                        }
                    }
                    list
                } else {
                    val list = ArrayList<Coursework>(tomorrow.size + completedTomorrowCount)
                    list.addAll(tomorrow)
                    for (c in completed) {
                        val d = c.dueEpochMillis
                        if (d != null && d in startOfTomorrow until startOfDayAfter) {
                            list.add(c)
                        }
                    }
                    list
                }
            }
            hasToday -> {
                if (completedTodayCount == 0) today
                else if (today.isEmpty()) {
                    val list = ArrayList<Coursework>(completedTodayCount)
                    for (c in completed) {
                        val d = c.dueEpochMillis
                        if (d != null && d in now until startOfTomorrow) {
                            list.add(c)
                        }
                    }
                    list
                } else {
                    val list = ArrayList<Coursework>(today.size + completedTodayCount)
                    list.addAll(today)
                    for (c in completed) {
                        val d = c.dueEpochMillis
                        if (d != null && d in now until startOfTomorrow) {
                            list.add(c)
                        }
                    }
                    list
                }
            }
            hasLater -> {
                if (completedLaterCount == 0) later
                else if (later.isEmpty()) {
                    val list = ArrayList<Coursework>(completedLaterCount)
                    for (c in completed) {
                        val d = c.dueEpochMillis
                        if (d != null && d >= startOfDayAfter) {
                            list.add(c)
                        }
                    }
                    list
                } else {
                    val list = ArrayList<Coursework>(later.size + completedLaterCount)
                    list.addAll(later)
                    for (c in completed) {
                        val d = c.dueEpochMillis
                        if (d != null && d >= startOfDayAfter) {
                            list.add(c)
                        }
                    }
                    list
                }
            }
            hasNoDate -> {
                if (completedNoDateCount == 0) noDate
                else if (noDate.isEmpty()) {
                    val list = ArrayList<Coursework>(completedNoDateCount)
                    for (c in completed) {
                        if (c.dueEpochMillis == null) {
                            list.add(c)
                        }
                    }
                    list
                } else {
                    val list = ArrayList<Coursework>(noDate.size + completedNoDateCount)
                    list.addAll(noDate)
                    for (c in completed) {
                        if (c.dueEpochMillis == null) {
                            list.add(c)
                        }
                    }
                    list
                }
            }
            else -> emptyList()
        }
        val sortedOverdue = sortPreFiltered(overdue, searchTokens, rawNormalizedQuery, SAME_STATUS_COURSEWORK_COMPARATOR)
        val sortedToday = sortPreFiltered(today, searchTokens, rawNormalizedQuery, SAME_STATUS_COURSEWORK_COMPARATOR)
        val sortedTomorrow = sortPreFiltered(tomorrow, searchTokens, rawNormalizedQuery, SAME_STATUS_COURSEWORK_COMPARATOR)
        val sortedLater = sortPreFiltered(later, searchTokens, rawNormalizedQuery, SAME_STATUS_COURSEWORK_COMPARATOR)
        val sortedNoDate = sortPreFiltered(noDate, searchTokens, rawNormalizedQuery, SAME_STATUS_COURSEWORK_COMPARATOR)
        val sortedCompleted = sortPreFiltered(completed, searchTokens, rawNormalizedQuery, SAME_STATUS_COURSEWORK_COMPARATOR)

        val sortedWidgetItems = if (tomorrowCandidates.isEmpty()) {
            emptyList()
        } else if (tomorrowCandidates === tomorrow) {
            sortedTomorrow
        } else if (tomorrowCandidates === today) {
            sortedToday
        } else if (tomorrowCandidates === later) {
            sortedLater
        } else if (tomorrowCandidates === noDate) {
            sortedNoDate
        } else {
            sortPreFiltered(tomorrowCandidates as ArrayList<Coursework>, searchTokens, rawNormalizedQuery, COURSEWORK_COMPARATOR)
        }
        return CourseworkBuckets(
            overdue = sortedOverdue,
            today = sortedToday,
            tomorrow = sortedTomorrow,
            laterUpcoming = sortedLater,
            noDueDate = sortedNoDate,
            completed = sortedCompleted,
            widgetItems = sortedWidgetItems
        )
    }
}
