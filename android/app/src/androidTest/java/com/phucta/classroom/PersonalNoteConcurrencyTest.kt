package com.phucta.classroom

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.phucta.classroom.data.local.ClassroomDatabase
import com.phucta.classroom.data.model.ChecklistItem
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.data.repository.ClassroomRepository
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PersonalNoteConcurrencyTest {
    @Test
    fun concurrentChecklistEditsAreAllSaved() = runBlocking {
        val app = InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as ClassroomApplication
        val database = Room.inMemoryDatabaseBuilder(app, ClassroomDatabase::class.java).build()
        try {
            val repository = ClassroomRepository(app, database, app.preferences, app.oauthManager)
            val checklist = (1..24).map { ChecklistItem(id = "item-$it", title = "Việc $it") }
            val note = PersonalNote(title = "Bài tập", checklist = checklist)
            repository.savePersonalNote(note)

            coroutineScope {
                for (item in checklist) {
                    launch { repository.toggleChecklistItem(note.id, item.id) }
                }
            }

            val saved = checkNotNull(database.personalNoteDao().getNoteById(note.id)).toDomain()
            assertEquals(checklist.size, saved.completedChecklistCount)
            assertTrue(saved.isCompleted)

            repository.toggleChecklistItem(note.id, checklist.first().id)
            val unchecked = checkNotNull(database.personalNoteDao().getNoteById(note.id)).toDomain()
            assertEquals(checklist.size - 1, unchecked.completedChecklistCount)
            assertFalse(unchecked.isCompleted)
        } finally {
            database.close()
        }
    }
}
