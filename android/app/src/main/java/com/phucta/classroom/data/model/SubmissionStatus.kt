package com.phucta.classroom.data.model

import kotlinx.serialization.Serializable

@Serializable
enum class SubmissionStatus(val rawValue: String) {
    PENDING("pending"),
    TURNED_IN("turnedIn"),
    RETURNED("returned"),
    LATE("late");

    companion object {
        fun fromRaw(raw: String?): SubmissionStatus {
            return entries.firstOrNull { it.rawValue.equals(raw, ignoreCase = true) } ?: PENDING
        }
    }
}
