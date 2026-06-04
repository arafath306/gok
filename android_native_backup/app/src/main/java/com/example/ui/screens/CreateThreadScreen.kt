package com.example.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Image
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.rememberAsyncImagePainter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateThreadScreen(
    onBack: () -> Unit,
    viewModel: CreateThreadViewModel = viewModel(),
    profileViewModel: ProfileViewModel = viewModel()
) {
    var content by remember { mutableStateOf("") }
    val profile by profileViewModel.profile.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("নতুন ডাক", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    Button(
                        onClick = {
                            viewModel.postThread(content) { onBack() }
                        },
                        modifier = Modifier.padding(end = 8.dp),
                        enabled = content.isNotBlank()
                    ) {
                        Text("পোস্ট করুন")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .background(Color.White)
                .padding(16.dp)
        ) {
            Row {
                Image(
                    painter = rememberAsyncImagePainter(profile?.avatarUrl ?: "https://i.pravatar.cc/150"),
                    contentDescription = "Avatar",
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
                Spacer(modifier = Modifier.width(16.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(profile?.fullName ?: " ডাক ব্যবহারকারী", fontWeight = FontWeight.Bold)
                    TextField(
                        value = content,
                        onValueChange = { content = it },
                        placeholder = { Text("কি ভাবছেন, বলুন...") },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 100.dp),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color.White,
                            unfocusedContainerColor = Color.White,
                            focusedIndicatorColor = Color.Transparent,
                            unfocusedIndicatorColor = Color.Transparent
                        )
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFFF9F9F9))
                            .clickable { /* Upload images mock */ },
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(Icons.Filled.Image, contentDescription = null, tint = Color.Gray)
                            Text("ছবি বা ভিডিও যোগ করুন", color = Color.Gray)
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            Text("কে উত্তর দিতে পারবে?", fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                RadioButton(selected = true, onClick = {})
                Text("সবাই (Everyone)")
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                RadioButton(selected = false, onClick = {})
                Text("আপনার অনুসারীরা")
            }
        }
    }
}
