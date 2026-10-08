package com.phucta.classroom.data.model

import kotlinx.serialization.Serializable

@Serializable
data class Course(
    val id: String,
    val name: String,
    val section: String? = null,
    val descriptionHeading: String? = null,
    val room: String? = null,
    val alternateLink: String? = null,
    val isSelectedForWidget: Boolean = true
)
