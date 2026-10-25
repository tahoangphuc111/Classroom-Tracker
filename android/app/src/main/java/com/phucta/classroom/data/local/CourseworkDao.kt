package com.phucta.classroom.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface CourseworkDao {
    @Query("SELECT * FROM courseworks")
    fun observeAllCoursework(): Flow<List<CourseworkEntity>>

    @Query("SELECT * FROM courseworks")
    suspend fun getAllCoursework(): List<CourseworkEntity>

    @Query("""
        SELECT * FROM courseworks 
        WHERE (status != 'TURNED_IN' AND status != 'RETURNED' AND is_manually_completed = 0)
           OR due_epoch_millis >= :recentThreshold
           OR due_epoch_millis IS NULL
    """)
    suspend fun getWidgetCoursework(recentThreshold: Long): List<CourseworkEntity>

    @Query("SELECT id FROM courseworks")
    suspend fun getAllCourseworkIds(): List<String>

    @Query("SELECT * FROM courseworks WHERE course_id = :courseId")
    suspend fun getCourseworkForCourse(courseId: String): List<CourseworkEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertCourseworks(items: List<CourseworkEntity>)

    @Query("UPDATE courseworks SET status = :status, is_manually_completed = :isManuallyCompleted WHERE id = :id")
    suspend fun updateCompletionStatus(id: String, status: String, isManuallyCompleted: Boolean)

    @Query("DELETE FROM courseworks WHERE id IN (:ids)")
    suspend fun deleteCourseworkByIds(ids: List<String>)

    @Transaction
    suspend fun deleteCourseworkNotIn(validIds: List<String>) {
        if (validIds.isEmpty()) {
            deleteAllCoursework()
            return
        }
        val validSet = validIds.toHashSet()
        val allIds = getAllCourseworkIds()
        if (allIds.isEmpty()) return
        val toDelete = ArrayList<String>()
        val count = allIds.size
        for (i in 0 until count) {
            val id = allIds[i]
            if (!validSet.contains(id)) {
                toDelete.add(id)
            }
        }
        if (toDelete.isNotEmpty()) {
            for (chunk in toDelete.chunked(500)) {
                deleteCourseworkByIds(chunk)
            }
        }
    }

    @Query("DELETE FROM courseworks")
    suspend fun deleteAllCoursework()

    @Query("DELETE FROM courseworks WHERE course_id = :courseId")
    suspend fun deleteCourseworkForCourse(courseId: String)
}
