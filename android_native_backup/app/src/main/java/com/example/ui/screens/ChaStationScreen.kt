package com.example.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.viewmodel.compose.viewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChaStationScreen(onBack: () -> Unit, viewModel: ChaStationViewModel = viewModel()) {
    val feed by viewModel.feed.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("চা-স্টেশন", color = MaterialTheme.colorScheme.primary) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    Icon(Icons.Filled.LocalCafe, contentDescription = "Tea", tint = MaterialTheme.colorScheme.primary)
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { /* TODO */ },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                icon = { Icon(Icons.Filled.CameraAlt, contentDescription = "Camera") },
                text = { Text("ডাক পোস্ট করুন") }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
                .padding(padding)
        ) {
            items(feed) { post ->
                CustomThreadItem(
                    post = post,
                    onLikeToggle = {
                        // In Cha Station, clicking like also toggles like
                    }
                )
                HorizontalDivider(color = Color(0xFFF0F0F0))
            }
        }
    }
}
