package com.phucta.classroom.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface CourseDao {
    @Query("SELECT * FROM courses ORDER BY name ASC")
    fun observeAllCourses(): Flow<List<CourseEntity>>

    @Query("SELECT * FROM courses ORDER BY name ASC")
    suspend fun getAllCourses(): List<CourseEntity>

    @Query("SELECT * FROM courses WHERE is_selected_for_widget = 1 ORDER BY name ASC")
    fun observeSelectedCourses(): Flow<List<CourseEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertCourses(courses: List<CourseEntity>)

    @Query("UPDATE courses SET is_selected_for_widget = :isSelected WHERE id = :courseId")
    suspend fun updateWidgetSelection(courseId: String, isSelected: Boolean)

    @Query("DELETE FROM courses WHERE id NOT IN (:validCourseIds)")
    suspend fun deleteCoursesNotIn(validCourseIds: List<String>)

    @Query("DELETE FROM courses")
    suspend fun deleteAllCourses()
}
