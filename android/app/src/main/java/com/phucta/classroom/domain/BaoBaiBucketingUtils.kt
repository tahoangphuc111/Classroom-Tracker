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

        val normTitleDiff = first.normalizedTitle.compareTo(second.normalizedTitle)
        if (normTitleDiff != 0) {
            normTitleDiff
        } else {
            val titleDiff = first.title.compareTo(second.title, ignoreCase = true)
            if (titleDiff != 0) titleDiff else first.id.compareTo(second.id)
        }
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

        val normTitleDiff = first.normalizedTitle.compareTo(second.normalizedTitle)
        if (normTitleDiff != 0) {
            normTitleDiff
        } else {
            val titleDiff = first.title.compareTo(second.title, ignoreCase = true)
            if (titleDiff != 0) titleDiff else first.id.compareTo(second.id)
        }
    }

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
        items: List<Coursework>,
        searchTokens: List<String>,
        rawNormalizedQuery: String,
        comparator: Comparator<Coursework>
    ): List<Coursework> {
        val count = items.size
        if (count <= 1) return items
        if (searchTokens.isNotEmpty()) {
            val scores = IntArray(count)
            for (i in 0 until count) {
                val item = items[i]
                scores[i] = com.phucta.classroom.data.model.calculateSearchRelevance(
                    queryTokens = searchTokens,
                    rawNormalizedQuery = rawNormalizedQuery,
                    title = item.title,
                    courseName = item.courseName,
                    content = null,
                    normalizedTitle = item.normalizedTitle,
                    normalizedCourseName = item.normalizedCourseName
                )
            }
            val indices = Array(count) { it }
            indices.sortWith { i1, i2 ->
                val diff = scores[i2].compareTo(scores[i1])
                if (diff != 0) diff else comparator.compare(items[i1], items[i2])
            }
            val result = ArrayList<Coursework>(count)
            for (i in 0 until count) {
                result.add(items[indices[i]])
            }
            return result
        }
        return if (items is ArrayList<Coursework>) {
            items.sortWith(comparator)
            items
        } else {
            items.sortedWith(comparator)
        }
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
        val todayIncompleteFiltered = ArrayList<Coursework>(estCap)
        val todayCompletedFiltered = ArrayList<Coursework>(estCap)
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
                    if (item.isCompleted) {
                        if (includeCompleted) todayCompletedFiltered.add(item)
                    } else {
                        todayIncompleteFiltered.add(item)
                    }
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
        if (todayIncompleteFiltered.isNotEmpty()) return sortInternal(todayIncompleteFiltered, emptyList(), "")
        if (upcomingFiltered.isNotEmpty()) return sortInternal(upcomingFiltered, emptyList(), "")
        if (undatedFiltered.isNotEmpty()) return sortInternal(undatedFiltered, emptyList(), "")
        if (todayCompletedFiltered.isNotEmpty()) return sortInternal(todayCompletedFiltered, emptyList(), "")
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
        val completedTomorrow = ArrayList<Coursework>()
        val completedToday = ArrayList<Coursework>()
        val completedLater = ArrayList<Coursework>()
        val completedNoDate = ArrayList<Coursework>()
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
                        completedTomorrow.add(item)
                    } else if (due in now until startOfTomorrow) {
                        completedToday.add(item)
                    } else if (due >= startOfDayAfter) {
                        completedLater.add(item)
                    }
                } else {
                    completedNoDate.add(item)
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
        val hasTomorrow = tomorrow.isNotEmpty() || completedTomorrow.isNotEmpty()
        val hasToday = today.isNotEmpty()
        val hasLater = later.isNotEmpty() || completedLater.isNotEmpty()
        val hasNoDate = noDate.isNotEmpty() || completedNoDate.isNotEmpty()
        val hasCompletedToday = completedToday.isNotEmpty()
        val tomorrowCandidates: List<Coursework> = when {
            hasTomorrow -> {
                if (completedTomorrow.isEmpty()) tomorrow
                else if (tomorrow.isEmpty()) completedTomorrow
                else {
                    val list = ArrayList<Coursework>(tomorrow.size + completedTomorrow.size)
                    list.addAll(tomorrow)
                    list.addAll(completedTomorrow)
                    list
                }
            }
            hasToday -> today
            hasLater -> {
                if (completedLater.isEmpty()) later
                else if (later.isEmpty()) completedLater
                else {
                    val list = ArrayList<Coursework>(later.size + completedLater.size)
                    list.addAll(later)
                    list.addAll(completedLater)
                    list
                }
            }
            hasNoDate -> {
                if (completedNoDate.isEmpty()) noDate
                else if (noDate.isEmpty()) completedNoDate
                else {
                    val list = ArrayList<Coursework>(noDate.size + completedNoDate.size)
                    list.addAll(noDate)
                    list.addAll(completedNoDate)
                    list
                }
            }
            hasCompletedToday -> completedToday
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
            sortPreFiltered(tomorrowCandidates, searchTokens, rawNormalizedQuery, COURSEWORK_COMPARATOR)
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
