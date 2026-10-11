package com.phucta.classroom.domain

import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.data.model.SubmissionStatus
import java.util.Calendar

object BaoBaiBucketingUtils {

    data class CourseworkBuckets(
        val overdue: List<Coursework> = emptyList(),
        val today: List<Coursework> = emptyList(),
        val tomorrow: List<Coursework> = emptyList(),
        val laterUpcoming: List<Coursework> = emptyList(),
        val noDueDate: List<Coursework> = emptyList(),
        val completed: List<Coursework> = emptyList()
    ) {
        val todayAndTomorrow: List<Coursework> = today + tomorrow
        val allUpcoming: List<Coursework> = today + tomorrow + laterUpcoming + noDueDate
        val widgetItems: List<Coursework> get() = tomorrow
    }

    val COURSEWORK_COMPARATOR = Comparator<Coursework> { first, second ->
        if (first.isCompleted != second.isCompleted) {
            if (!first.isCompleted) -1 else 1
        } else {
            val primaryDiff = when {
                first.dueEpochMillis != null && second.dueEpochMillis != null -> {
                    if (first.dueEpochMillis != second.dueEpochMillis) {
                        first.dueEpochMillis.compareTo(second.dueEpochMillis)
                    } else {
                        first.title.compareTo(second.title, ignoreCase = true)
                    }
                }
                first.dueEpochMillis != null && second.dueEpochMillis == null -> -1
                first.dueEpochMillis == null && second.dueEpochMillis != null -> 1
                else -> first.title.compareTo(second.title, ignoreCase = true)
            }
            if (primaryDiff != 0) primaryDiff else first.id.compareTo(second.id)
        }
    }

    fun sortCoursework(items: List<Coursework>): List<Coursework> {
        if (items.size <= 1) return items
        return items.sortedWith(COURSEWORK_COMPARATOR)
    }

    fun filterByActiveCourses(items: List<Coursework>, courses: List<Course>): List<Coursework> {
        if (courses.isEmpty() || items.isEmpty()) return items
        var hasUnselected = false
        val allCourseIds = HashSet<String>(courses.size)
        val activeCourseIds = HashSet<String>(courses.size)
        for (course in courses) {
            allCourseIds.add(course.id)
            if (course.isSelectedForWidget) {
                activeCourseIds.add(course.id)
            } else {
                hasUnselected = true
            }
        }
        if (!hasUnselected || activeCourseIds.isEmpty()) return items

        val result = ArrayList<Coursework>(items.size)
        var anyMatchesLoadedCourses = false
        for (item in items) {
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

    /**
     * "Báo bài Ngày mai": prioritizes assignments due tomorrow.
     * If tomorrow is clear, falls back in order: overdue -> due today -> later upcoming -> undated.
     */
    fun getTomorrowCoursework(
        items: List<Coursework>,
        courses: List<Course> = emptyList(),
        includeCompleted: Boolean = true,
        personalNotes: List<PersonalNote> = emptyList(),
        includeNotes: Boolean = true
    ): List<Coursework> {
        val relevant = filterByActiveCourses(items, courses)
        if (relevant.isEmpty() && (!includeNotes || personalNotes.isEmpty())) return emptyList()

        val now = System.currentTimeMillis()

        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val startOfTomorrow = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val startOfDayAfter = cal.timeInMillis

        val tomorrowFiltered = ArrayList<Coursework>()
        val todayIncomplete = ArrayList<Coursework>()
        val upcomingFiltered = ArrayList<Coursework>()
        val undatedFiltered = ArrayList<Coursework>()

        for (item in relevant) {
            val isEligible = includeCompleted || !item.isCompleted
            val due = item.dueEpochMillis

            if (due != null) {
                // Triết lý: Cứ hết hạn thì tính là đã hoàn thành.
                // Bài tập quá hạn (due < now) không được tính là bài cần làm và không đưa vào widget báo bài.
                if (due in startOfTomorrow until startOfDayAfter) {
                    if (isEligible) tomorrowFiltered.add(item)
                } else if (!item.isCompleted) {
                    if (due in now until startOfTomorrow) {
                        todayIncomplete.add(item)
                    } else if (isEligible && due >= startOfDayAfter) {
                        upcomingFiltered.add(item)
                    }
                } else if (isEligible && due >= startOfDayAfter) {
                    upcomingFiltered.add(item)
                }
            } else {
                if (isEligible) undatedFiltered.add(item)
            }
        }

        if (includeNotes && personalNotes.isNotEmpty()) {
            for (note in personalNotes) {
                if (note.courseworkId == null) {
                    val isEligible = includeCompleted || !note.isCompleted
                    if (isEligible && note.isDueTomorrow) {
                        val matchesCourse = if (note.courseId != null && courses.isNotEmpty()) {
                            val activeIds = courses.filter { it.isSelectedForWidget }.map { it.id }.toSet()
                            activeIds.isEmpty() || activeIds.contains(note.courseId)
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

        if (tomorrowFiltered.isNotEmpty()) return sortCoursework(tomorrowFiltered)
        if (todayIncomplete.isNotEmpty()) return sortCoursework(todayIncomplete)
        if (upcomingFiltered.isNotEmpty()) return sortCoursework(upcomingFiltered)
        if (undatedFiltered.isNotEmpty()) return sortCoursework(undatedFiltered)

        return emptyList()
    }

    fun computeBuckets(items: List<Coursework>, courses: List<Course>): CourseworkBuckets {
        val relevant = filterByActiveCourses(items, courses)
        val now = System.currentTimeMillis()

        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val startOfTomorrow = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val startOfDayAfter = cal.timeInMillis

        val overdue = mutableListOf<Coursework>()
        val today = mutableListOf<Coursework>()
        val tomorrow = mutableListOf<Coursework>()
        val later = mutableListOf<Coursework>()
        val noDate = mutableListOf<Coursework>()
        val completed = mutableListOf<Coursework>()

        for (item in relevant) {
            if (item.isCompleted) {
                completed.add(item)
                continue
            }
            val due = item.dueEpochMillis
            when {
                due == null -> noDate.add(item)
                due < now -> overdue.add(item)
                due < startOfTomorrow -> today.add(item)
                due < startOfDayAfter -> tomorrow.add(item)
                else -> later.add(item)
            }
        }

        return CourseworkBuckets(
            overdue = sortCoursework(overdue),
            today = sortCoursework(today),
            tomorrow = sortCoursework(tomorrow),
            laterUpcoming = sortCoursework(later),
            noDueDate = sortCoursework(noDate),
            completed = sortCoursework(completed)
        )
    }
}
