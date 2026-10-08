package com.phucta.classroom.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.phucta.classroom.data.model.Course

@Entity(tableName = "courses")
data class CourseEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "name")
    val name: String,

    @ColumnInfo(name = "section")
    val section: String? = null,

    @ColumnInfo(name = "description_heading")
    val descriptionHeading: String? = null,

    @ColumnInfo(name = "room")
    val room: String? = null,

    @ColumnInfo(name = "alternate_link")
    val alternateLink: String? = null,

    @ColumnInfo(name = "is_selected_for_widget")
    val isSelectedForWidget: Boolean = true
) {
    fun toDomain(): Course = Course(
        id = id,
        name = name,
        section = section,
        descriptionHeading = descriptionHeading,
        room = room,
        alternateLink = alternateLink,
        isSelectedForWidget = isSelectedForWidget
    )

    companion object {
        fun fromDomain(domain: Course): CourseEntity = CourseEntity(
            id = domain.id,
            name = domain.name,
            section = domain.section,
            descriptionHeading = domain.descriptionHeading,
            room = domain.room,
            alternateLink = domain.alternateLink,
            isSelectedForWidget = domain.isSelectedForWidget
        )
    }
}
