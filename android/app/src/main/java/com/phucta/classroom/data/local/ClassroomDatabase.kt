package com.phucta.classroom.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [CourseEntity::class, CourseworkEntity::class, PersonalNoteEntity::class],
    version = 6,
    exportSchema = false
)
abstract class ClassroomDatabase : RoomDatabase() {
    abstract fun courseDao(): CourseDao
    abstract fun courseworkDao(): CourseworkDao
    abstract fun personalNoteDao(): PersonalNoteDao

    companion object {
        @Volatile
        private var INSTANCE: ClassroomDatabase? = null

        fun getInstance(context: Context): ClassroomDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    ClassroomDatabase::class.java,
                    "classroom_tracker.db"
                ).fallbackToDestructiveMigration().build().also { INSTANCE = it }
            }
        }
    }
}
