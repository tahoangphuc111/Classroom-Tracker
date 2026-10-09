package com.phucta.classroom.domain

import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
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

    fun sortCoursework(items: List<Coursework>): List<Coursework> {
        return items.sortedWith { first, second ->
            if (first.isCompleted != second.isCompleted) {
                return@sortedWith if (!first.isCompleted) -1 else 1
            }
            when {
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
        }
    }

    fun filterByActiveCourses(items: List<Coursework>, courses: List<Course>): List<Coursework> {
        if (courses.isEmpty() || items.isEmpty()) return items
        val allCourseIds = HashSet<String>(courses.size)
        val activeCourseIds = HashSet<String>(courses.size)
        for (course in courses) {
            allCourseIds.add(course.id)
            if (course.isSelectedForWidget) {
                activeCourseIds.add(course.id)
            }
        }
        val itemsMatchCourses = items.any { allCourseIds.contains(it.courseId) }
        if (!itemsMatchCourses || activeCourseIds.isEmpty()) return items
        return items.filter { activeCourseIds.contains(it.courseId) }
    }

    /**
     * Core Algorithm for "Báo bài Ngày mai":
     * "Báo bài là Ngày mai - Ngày hôm nay mặc định đã hoàn thành."
     *
     * 1. Primary target: Assignments due TOMORROW (startOfTomorrow until startOfDayAfter).
     *    Today's completed tasks are EXCLUDED from tomorrow's agenda.
     * 2. Fallback sequence when tomorrow has no assignments:
     *    - Overdue incomplete tasks (stuff that was missed: dueEpochMillis < now && !isCompleted)
     *    - Incomplete tasks due today (now <= dueEpochMillis < startOfTomorrow && !isCompleted)
     *    - Next upcoming tasks (in 2+ days: dueEpochMillis >= startOfDayAfter)
     *    - Undated tasks
     *    - Empty state ("Ngày mai rảnh rồi!")
     */
    fun getTomorrowCoursework(
        items: List<Coursework>,
        courses: List<Course> = emptyList(),
        includeCompleted: Boolean = true
    ): List<Coursework> {
        val relevant = filterByActiveCourses(items, courses)
        if (relevant.isEmpty()) return emptyList()

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
        val overdue = ArrayList<Coursework>()
        val todayIncomplete = ArrayList<Coursework>()
        val upcomingFiltered = ArrayList<Coursework>()
        val undatedFiltered = ArrayList<Coursework>()

        for (item in relevant) {
            val isEligible = includeCompleted || !item.isCompleted
            val due = item.dueEpochMillis

            if (due != null) {
                if (due in startOfTomorrow until startOfDayAfter) {
                    if (isEligible) tomorrowFiltered.add(item)
                } else if (!item.isCompleted) {
                    if (due < now) {
                        overdue.add(item)
                    } else if (due < startOfTomorrow) {
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

        if (tomorrowFiltered.isNotEmpty()) return sortCoursework(tomorrowFiltered)
        if (overdue.isNotEmpty()) return sortCoursework(overdue)
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
