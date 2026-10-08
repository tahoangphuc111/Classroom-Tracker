package com.phucta.classroom.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface CourseworkDao {
    @Query("SELECT * FROM courseworks")
    fun observeAllCoursework(): Flow<List<CourseworkEntity>>

    @Query("SELECT * FROM courseworks")
    suspend fun getAllCoursework(): List<CourseworkEntity>

    @Query("SELECT * FROM courseworks WHERE course_id = :courseId")
    suspend fun getCourseworkForCourse(courseId: String): List<CourseworkEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertCourseworks(items: List<CourseworkEntity>)

    @Query("UPDATE courseworks SET status = :status, is_manually_completed = :isManuallyCompleted WHERE id = :id")
    suspend fun updateCompletionStatus(id: String, status: String, isManuallyCompleted: Boolean)

    @Query("DELETE FROM courseworks WHERE id NOT IN (:validIds)")
    suspend fun deleteCourseworkNotIn(validIds: List<String>)

    @Query("DELETE FROM courseworks")
    suspend fun deleteAllCoursework()

    @Query("DELETE FROM courseworks WHERE course_id = :courseId")
    suspend fun deleteCourseworkForCourse(courseId: String)
}
