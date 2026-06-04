package com.example.ui.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController

@Composable
fun MainScreen(onNavigateToCreate: () -> Unit, onNavigateToChaStation: () -> Unit, onNavigateToEditProfile: () -> Unit) {
    val bottomNavController = rememberNavController()
    val navBackStackEntry by bottomNavController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                NavigationBarItem(
                    selected = currentRoute == "home",
                    onClick = { bottomNavController.navigate("home") { launchSingleTop = true } },
                    icon = { Icon(if (currentRoute == "home") Icons.Filled.Home else Icons.Outlined.Home, contentDescription = "Home") },
                    label = { Text("বাসা") },
                    colors = NavigationBarItemDefaults.colors(indicatorColor = MaterialTheme.colorScheme.secondaryContainer)
                )
                NavigationBarItem(
                    selected = currentRoute == "search",
                    onClick = { bottomNavController.navigate("search") { launchSingleTop = true } },
                    icon = { Icon(if (currentRoute == "search") Icons.Filled.Search else Icons.Outlined.Search, contentDescription = "Search") },
                    label = { Text("খোঁজ") },
                    colors = NavigationBarItemDefaults.colors(indicatorColor = MaterialTheme.colorScheme.secondaryContainer)
                )
                NavigationBarItem(
                    selected = currentRoute == "cha_station",
                    onClick = { bottomNavController.navigate("cha_station") { launchSingleTop = true } },
                    icon = { Icon(if (currentRoute == "cha_station") Icons.Filled.LocalCafe else Icons.Outlined.LocalCafe, contentDescription = "Cha Station") },
                    label = { Text("চা-স্টেশন") },
                    colors = NavigationBarItemDefaults.colors(indicatorColor = MaterialTheme.colorScheme.secondaryContainer)
                )
                NavigationBarItem(
                    selected = currentRoute == "activity",
                    onClick = { bottomNavController.navigate("activity") { launchSingleTop = true } },
                    icon = { Icon(if (currentRoute == "activity") Icons.Filled.Notifications else Icons.Outlined.Notifications, contentDescription = "Activity") },
                    label = { Text("খবর") },
                    colors = NavigationBarItemDefaults.colors(indicatorColor = MaterialTheme.colorScheme.secondaryContainer)
                )
                NavigationBarItem(
                    selected = currentRoute == "profile",
                    onClick = { bottomNavController.navigate("profile") { launchSingleTop = true } },
                    icon = { Icon(if (currentRoute == "profile") Icons.Filled.Person else Icons.Outlined.Person, contentDescription = "Profile") },
                    label = { Text("আমি") },
                    colors = NavigationBarItemDefaults.colors(indicatorColor = MaterialTheme.colorScheme.secondaryContainer)
                )
            }
        }
    ) { padding ->
        NavHost(
            navController = bottomNavController,
            startDestination = "home",
            modifier = Modifier.padding(padding)
        ) {
        composable("home") { FeedScreen(onNavigateToChaStation = { bottomNavController.navigate("cha_station") }, onNavigateToCreate = onNavigateToCreate) }
        composable("search") { SearchScreen() }
        composable("cha_station") { ChaStationScreen(onBack = { bottomNavController.popBackStack() }) }
        composable("activity") { NotificationsScreen() }
        composable("profile") { ProfileScreenContainer(onNavigateToEditProfile = onNavigateToEditProfile) }
        }
    }
}
