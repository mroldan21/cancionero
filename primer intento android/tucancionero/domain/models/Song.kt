package com.tucancionero.domain.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

@Entity(tableName = "songs")
data class Song(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val title: String = "",
    val artist: String = "",
    val lyricsWithChords: String = "",
    val originalKey: String = "C",
    val tempoBpm: Int? = null,
    val capoPosition: Int = 0,
    val isFavorite: Boolean = false,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
)