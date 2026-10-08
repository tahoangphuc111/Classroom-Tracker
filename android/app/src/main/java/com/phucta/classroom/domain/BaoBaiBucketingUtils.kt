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
        val todayAndTomorrow: List<Coursework> get() = today + tomorrow
        val allUpcoming: List<Coursework> get() = today + tomorrow + laterUpcoming + noDueDate
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
        if (courses.isEmpty()) return items
        val allCourseIds = courses.map { it.id }.toSet()
        val itemsMatchCourses = items.any { allCourseIds.contains(it.courseId) }
        if (!itemsMatchCourses) return items

        val activeCourseIds = courses.filter { it.isSelectedForWidget }.map { it.id }.toSet()
        if (activeCourseIds.isEmpty()) return items
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

        // 1. Due tomorrow (The primary target for Báo bài)
        val tomorrowFiltered = relevant
            .filter { if (includeCompleted) true else !it.isCompleted }
            .filter {
                val due = it.dueEpochMillis
                due != null && due in startOfTomorrow until startOfDayAfter
            }

        // If tomorrow has assignments, present tomorrow's agenda directly!
        if (tomorrowFiltered.isNotEmpty()) {
            return sortCoursework(tomorrowFiltered)
        }

        // Fallback 1: Overdue incomplete tasks (stuff that was missed)
        val overdue = relevant
            .filter { !it.isCompleted }
            .filter { (it.dueEpochMillis ?: Long.MAX_VALUE) < now }

        if (overdue.isNotEmpty()) {
            return sortCoursework(overdue)
        }

        // Fallback 2: Any incomplete tasks from today that are still unsubmitted
        val todayIncomplete = relevant
            .filter { !it.isCompleted }
            .filter {
                val due = it.dueEpochMillis
                due != null && due in now until startOfTomorrow
            }

        if (todayIncomplete.isNotEmpty()) {
            return sortCoursework(todayIncomplete)
        }

        // Fallback 3: Next upcoming tasks (2+ days ahead)
        val upcomingFiltered = relevant
            .filter { if (includeCompleted) true else !it.isCompleted }
            .filter { (it.dueEpochMillis ?: 0L) >= startOfDayAfter }

        if (upcomingFiltered.isNotEmpty()) {
            return sortCoursework(upcomingFiltered)
        }

        // Fallback 4: Undated tasks
        val undatedFiltered = relevant
            .filter { if (includeCompleted) true else !it.isCompleted }
            .filter { it.dueEpochMillis == null }

        if (undatedFiltered.isNotEmpty()) {
            return sortCoursework(undatedFiltered)
        }

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
