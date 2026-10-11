package com.phucta.classroom.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface PersonalNoteDao {
    @Query("SELECT * FROM personal_notes ORDER BY updated_at DESC")
    fun observeAllNotes(): Flow<List<PersonalNoteEntity>>

    @Query("SELECT * FROM personal_notes ORDER BY updated_at DESC")
    suspend fun getAllNotes(): List<PersonalNoteEntity>

    @Query("SELECT * FROM personal_notes WHERE coursework_id = :courseworkId LIMIT 1")
    fun observeNoteForCoursework(courseworkId: String): Flow<PersonalNoteEntity?>

    @Query("SELECT * FROM personal_notes WHERE coursework_id = :courseworkId LIMIT 1")
    suspend fun getNoteForCoursework(courseworkId: String): PersonalNoteEntity?

    @Query("SELECT * FROM personal_notes WHERE id = :id LIMIT 1")
    suspend fun getNoteById(id: String): PersonalNoteEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertNote(note: PersonalNoteEntity)

    @Query("UPDATE personal_notes SET is_completed = :isCompleted, updated_at = :updatedAt WHERE id = :id")
    suspend fun updateCompletionStatus(id: String, isCompleted: Boolean, updatedAt: Long = System.currentTimeMillis())

    @Query("DELETE FROM personal_notes WHERE id = :id")
    suspend fun deleteNoteById(id: String)

    @Query("DELETE FROM personal_notes WHERE coursework_id = :courseworkId")
    suspend fun deleteNoteByCourseworkId(courseworkId: String)

    @Query("DELETE FROM personal_notes")
    suspend fun deleteAllNotes()
}
