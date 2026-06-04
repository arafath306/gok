package com.example.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.repository.DakRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class AuthViewModel(private val repository: DakRepository = DakRepository()) : ViewModel() {
    
    private val _authState = MutableStateFlow<AuthResultState>(AuthResultState.Idle)
    val authState: StateFlow<AuthResultState> = _authState

    fun isUserSignedIn(): Boolean = repository.isUserSignedIn()

    fun handleLogin(email: String, password: String, onComplete: () -> Unit) {
        viewModelScope.launch {
            _authState.value = AuthResultState.Loading
            val result = repository.signIn(email, password)
            if (result.isSuccess) {
                _authState.value = AuthResultState.Success
                onComplete()
            } else {
                _authState.value = AuthResultState.Error(result.exceptionOrNull()?.message ?: "Login failed")
            }
        }
    }

    fun handleSignup(email: String, password: String, onComplete: () -> Unit) {
        viewModelScope.launch {
            _authState.value = AuthResultState.Loading
            val result = repository.signUp(email, password)
            if (result.isSuccess) {
                _authState.value = AuthResultState.Success
                onComplete()
            } else {
                _authState.value = AuthResultState.Error(result.exceptionOrNull()?.message ?: "Sign up failed")
            }
        }
    }

    fun handleSignout(onComplete: () -> Unit) {
        repository.signOut()
        onComplete()
    }
}

sealed interface AuthResultState {
    object Idle : AuthResultState
    object Loading : AuthResultState
    object Success : AuthResultState
    data class Error(val message: String) : AuthResultState
}

class FeedViewModel(private val repository: DakRepository = DakRepository()) : ViewModel() {
    val feed = repository.getFeed().stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    fun toggleLike(threadId: String, isLiked: Boolean) {
        viewModelScope.launch {
            repository.toggleLike(threadId, isLiked)
        }
    }
}

class ChaStationViewModel(private val repository: DakRepository = DakRepository()) : ViewModel() {
    val feed = repository.getChaStationFeed().stateIn(viewModelScope, SharingStarted.Lazily, emptyList())
}

class ProfileViewModel(private val repository: DakRepository = DakRepository()) : ViewModel() {
    val profile = repository.getCurrentProfile().stateIn(viewModelScope, SharingStarted.Lazily, null)
    val myThreads = repository.getMyThreads().stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    fun updateProfile(fullName: String, username: String, bio: String, onComplete: () -> Unit) {
        viewModelScope.launch {
            repository.updateProfile(fullName, username, bio)
            onComplete()
        }
    }
    
    fun toggleLike(threadId: String, isLiked: Boolean) {
        viewModelScope.launch {
            repository.toggleLike(threadId, isLiked)
        }
    }
}

class NotificationsViewModel(private val repository: DakRepository = DakRepository()) : ViewModel() {
    val notifications = repository.getNotifications().stateIn(viewModelScope, SharingStarted.Lazily, emptyList())
}

class CreateThreadViewModel(private val repository: DakRepository = DakRepository()) : ViewModel() {
    fun postThread(content: String, imageUrls: List<String>? = null, onComplete: () -> Unit) {
        viewModelScope.launch {
            repository.createThread(content, imageUrls)
            onComplete()
        }
    }
}
