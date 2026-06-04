package com.example.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.domain.model.ThreadPost

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedScreen(
    onNavigateToChaStation: () -> Unit,
    onNavigateToCreate: () -> Unit,
    viewModel: FeedViewModel = viewModel()
) {
    val feed by viewModel.feed.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("ডাক", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold) },
                actions = {
                    TextButton(onClick = onNavigateToChaStation) {
                        Text("আড্ডা জোন", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = onNavigateToCreate,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                icon = { Icon(Icons.Filled.Add, contentDescription = "Add") },
                text = { Text("ডাক দিন") }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
                .padding(padding),
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            items(feed) { post ->
                CustomThreadItem(
                    post = post,
                    onLikeToggle = {
                        viewModel.toggleLike(post.id, !post.isLikedByMe)
                    }
                )
                HorizontalDivider(color = Color(0xFFF0F0F0))
            }
        }
    }
}
