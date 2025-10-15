package com.tucancionero.data.repository

import com.tucancionero.data.database.SongDao
import com.tucancionero.domain.models.Song
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class SongRepository @Inject constructor(
    private val songDao: SongDao
) {
    fun getAllSongs(): Flow<List<Song>> = songDao.getAllSongs()

    fun getSongById(id: Long): Flow<Song?> = songDao.getSongById(id)

    suspend fun insertSong(song: Song): Long = songDao.insertSong(song)

    suspend fun updateSong(song: Song) = songDao.updateSong(song)

    suspend fun deleteSong(song: Song) = songDao.deleteSong(song)

    fun searchSongs(query: String): Flow<List<Song>> = songDao.searchSongs(query)

    fun getFavoriteSongs(): Flow<List<Song>> = songDao.getFavoriteSongs()
}