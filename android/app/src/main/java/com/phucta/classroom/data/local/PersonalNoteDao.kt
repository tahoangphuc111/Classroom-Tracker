package com.phucta.classroom.data.local

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

data class AttachedCourseworkNoteRef(
    val id: String,
    @ColumnInfo(name = "coursework_id") val courseworkId: String?
)

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

    @Query("DELETE FROM personal_notes WHERE id IN (:ids)")
    suspend fun deleteNotesByIds(ids: List<String>)

    @Query("DELETE FROM personal_notes WHERE coursework_id = :courseworkId")
    suspend fun deleteNoteByCourseworkId(courseworkId: String)

    @Query("SELECT id, coursework_id FROM personal_notes WHERE coursework_id IS NOT NULL AND TRIM(coursework_id) != ''")
    suspend fun getCourseworkAttachedNoteRefs(): List<AttachedCourseworkNoteRef>

    @Transaction
    suspend fun deleteNotesWithCourseworkNotIn(validCourseworkIds: List<String>) {
        if (validCourseworkIds.isEmpty()) {
            deleteAllCourseworkAttachedNotes()
            return
        }
        val validSet = validCourseworkIds.toHashSet()
        val attached = getCourseworkAttachedNoteRefs()
        if (attached.isEmpty()) return
        val toDelete = ArrayList<String>()
        for (note in attached) {
            val cwId = note.courseworkId
            if (!cwId.isNullOrBlank() && !validSet.contains(cwId)) {
                toDelete.add(note.id)
            }
        }
        if (toDelete.isNotEmpty()) {
            for (chunk in toDelete.chunked(500)) {
                deleteNotesByIds(chunk)
            }
        }
    }

    @Query("DELETE FROM personal_notes WHERE coursework_id IS NOT NULL AND TRIM(coursework_id) != ''")
    suspend fun deleteAllCourseworkAttachedNotes()

    @Query("SELECT * FROM personal_notes WHERE search_index LIKE '%' || :query || '%' ORDER BY updated_at DESC")
    fun searchNotes(query: String): Flow<List<PersonalNoteEntity>>

    @Query("SELECT * FROM personal_notes WHERE coursework_id IS NULL AND search_index LIKE '%' || :query || '%' ORDER BY updated_at DESC")
    fun searchStandaloneNotes(query: String): Flow<List<PersonalNoteEntity>>

    @Query("DELETE FROM personal_notes")
    suspend fun deleteAllNotes()
}
