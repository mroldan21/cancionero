package com.tucancionero.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tucancionero.data.repository.SongRepository
import com.tucancionero.domain.models.Song
import com.tucancionero.domain.usecases.TransposeUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SongViewModel @Inject constructor(
    private val repository: SongRepository,
    private val transposeUseCase: TransposeUseCase
) : ViewModel() {
    private val _songs = MutableStateFlow<List<Song>>(emptyList())
    val songs: StateFlow<List<Song>> = _songs.asStateFlow()

    private val _currentSong = MutableStateFlow<Song?>(null)
    val currentSong: StateFlow<Song?> = _currentSong.asStateFlow()

    private val _transposition = MutableStateFlow(0)
    val transposition: StateFlow<Int> = _transposition.asStateFlow()

    init {
        loadSongs()
    }

    fun loadSongs() {
        viewModelScope.launch {
            repository.getAllSongs().collect { songsList ->
                _songs.value = songsList
            }
        }
    }

    fun searchSongs(query: String) {
        viewModelScope.launch {
            if (query.isEmpty()) {
                repository.getAllSongs().collect { songsList ->
                    _songs.value = songsList
                }
            } else {
                repository.searchSongs(query).collect { songsList ->
                    _songs.value = songsList
                }
            }
        }
    }

    fun addSong(song: Song) {
        viewModelScope.launch {
            repository.insertSong(song)
        }
    }

    fun updateSong(song: Song) {
        viewModelScope.launch {
            repository.updateSong(song)
        }
    }

    fun setCurrentSong(song: Song) {
        _currentSong.value = song
    }

    fun getSongById(id: Long) {
        viewModelScope.launch {
            repository.getSongById(id).collect { song ->
                _currentSong.value = song
            }
        }
    }

    // Transposición
    fun transposeUp() {
        _transposition.value = (_transposition.value + 1).coerceIn(-11, 11)
    }

    fun transposeDown() {
        _transposition.value = (_transposition.value - 1).coerceIn(-11, 11)
    }

    fun resetTransposition() {
        _transposition.value = 0
    }

    fun getTransposedLyrics(originalLyrics: String): String {
        return transposeUseCase.transposeLyrics(originalLyrics, _transposition.value)
    }

    fun getCurrentKey(originalKey: String): String {
        return transposeUseCase.transposeChord(originalKey, _transposition.value)
    }
}