package com.linux.clients

import jakarta.json.Json
import jakarta.json.JsonObject
import java.time.Instant
import java.time.format.DateTimeFormatter


fun Instant.json(): String = DateTimeFormatter.ISO_INSTANT.format(this)
fun String.instant(): Instant = Instant.from(DateTimeFormatter.ISO_INSTANT.parse(this))

data class User(val id: Int, val name: String, val active: Boolean, val email: String, val createdAt: Instant, val updatedAt: Instant) {

    fun toJson(): JsonObject = Json.createObjectBuilder()
        .add("id", id)
        .add("name", name)
        .add("active", active)
        .add("email", email)
        .add("created_at", createdAt.json())
        .add("updated_at", updatedAt.json())
        .build()

    companion object {
        fun fromJson(json: JsonObject): User = User(
            id = json.getInt("id"),
            name = json.getString("name"),
            active = json.getBoolean("active"),
            email = json.getString("email"),
            createdAt = json.getString("created_at").instant(),
            updatedAt = json.getString("updated_at").instant()
        )
    }
}

data class Group(val id: Int, val name: String, val active: Boolean, val createdBy: Int, val createdAt: Instant, val updatedAt: Instant) {
    fun toJson(): JsonObject = Json.createObjectBuilder()
        .add("id", id)
        .add("name", name)
        .add("active", active)
        .add("created_by", createdBy)
        .add("created_at", createdAt.json())
        .add("updated_at", updatedAt.json())
        .build()

    companion object {
        fun fromJson(json: JsonObject): Group = Group(
            id = json.getInt("id"),
            name = json.getString("name"),
            active = json.getBoolean("active"),
            createdBy = json.getInt("created_by"),
            createdAt = json.getString("created_at").instant(),
            updatedAt = json.getString("updated_at").instant()
        )
    }
}

data class Membership(val id: Int, val groupId: Int, val userId: Int, val admin: Boolean, val createdAt: Instant, val updatedAt: Instant) {
    fun toJson(): JsonObject = Json.createObjectBuilder()
        .add("id", id)
        .add("group_id", groupId)
        .add("user_id", userId)
        .add("admin", admin)
        .add("created_at", createdAt.json())
        .add("updated_at", updatedAt.json())
        .build()

    companion object {
        fun fromJson(json: JsonObject): Membership = Membership(
            id = json.getInt("id"),
            groupId = json.getInt("group_id"),
            userId = json.getInt("user_id"),
            admin = json.getBoolean("admin"),
            createdAt = json.getString("created_at").instant(),
            updatedAt = json.getString("updated_at").instant()
        )
    }
}